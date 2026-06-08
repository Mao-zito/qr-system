"""
Tabla necesaria en Neon — ejecuta esto en el SQL Editor:

CREATE TABLE IF NOT EXISTS password_reset_codes (
    id          SERIAL PRIMARY KEY,
    correo      VARCHAR(255) NOT NULL,
    codigo      VARCHAR(6)   NOT NULL,
    expira_en   TIMESTAMP    NOT NULL,
    usado       BOOLEAN      DEFAULT FALSE,
    creado_en   TIMESTAMP    DEFAULT NOW()
);
"""

import os
import random
import smtplib
import string
from datetime import datetime, timedelta
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

from app.database import Database


def _generar_codigo() -> str:
    return ''.join(random.choices(string.digits, k=6))


def _enviar_email(destinatario: str, codigo: str) -> bool:
    gmail_user     = os.getenv("GMAIL_USER")
    gmail_password = os.getenv("GMAIL_PASSWORD")

    if not gmail_user or not gmail_password:
        raise Exception("GMAIL_USER o GMAIL_PASSWORD no configurados")

    msg = MIMEMultipart("alternative")
    msg["Subject"] = "Código para restablecer tu contraseña — QR System"
    msg["From"]    = gmail_user
    msg["To"]      = destinatario

    html = f"""
    <div style="font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto; padding: 32px;">
      <div style="text-align: center; margin-bottom: 24px;">
        <div style="background: #FF6B00; display: inline-block; padding: 16px; border-radius: 50%;">
          <span style="font-size: 32px;">📱</span>
        </div>
      </div>
      <h2 style="color: #1F1F1F; text-align: center; margin-bottom: 8px;">Restablecer contraseña</h2>
      <p style="color: #666; text-align: center; margin-bottom: 32px;">
        Usa el siguiente código para restablecer tu contraseña en QR System.
        Expira en <strong>15 minutos</strong>.
      </p>
      <div style="background: #FFF3EC; border: 2px solid #FF6B00; border-radius: 16px;
                  padding: 24px; text-align: center; margin-bottom: 24px;">
        <span style="font-size: 40px; font-weight: 900; color: #FF6B00; letter-spacing: 8px;">
          {codigo}
        </span>
      </div>
      <p style="color: #999; font-size: 13px; text-align: center;">
        Si no solicitaste este código, ignora este mensaje.
      </p>
    </div>
    """

    msg.attach(MIMEText(html, "html"))

    with smtplib.SMTP_SSL("smtp.gmail.com", 465) as server:
        server.login(gmail_user, gmail_password)
        server.sendmail(gmail_user, destinatario, msg.as_string())

    return True


class PasswordResetModel:

    @staticmethod
    def solicitar_reset(correo: str) -> bool:
        conn = Database.get_connection()
        try:
            with conn.cursor() as cursor:
                # Verificar que el correo existe
                cursor.execute("SELECT id FROM cuentas WHERE correo = %s", (correo,))
                if not cursor.fetchone():
                    return False  # no revelamos si existe o no por seguridad

                # Invalidar códigos anteriores
                cursor.execute("""
                    UPDATE password_reset_codes
                    SET usado = TRUE
                    WHERE correo = %s AND usado = FALSE
                """, (correo,))

                # Generar nuevo código
                codigo    = _generar_codigo()
                expira_en = datetime.now() + timedelta(minutes=15)

                cursor.execute("""
                    INSERT INTO password_reset_codes(correo, codigo, expira_en)
                    VALUES (%s, %s, %s)
                """, (correo, codigo, expira_en))

                conn.commit()

            # Enviar email (fuera del cursor)
            _enviar_email(correo, codigo)
            return True

        except Exception as e:
            conn.rollback()
            raise e
        finally:
            Database.release(conn)

    @staticmethod
    def verificar_codigo(correo: str, codigo: str) -> bool:
        conn = Database.get_connection()
        try:
            with conn.cursor() as cursor:
                cursor.execute("""
                    SELECT id FROM password_reset_codes
                    WHERE correo   = %s
                      AND codigo   = %s
                      AND usado    = FALSE
                      AND expira_en > NOW()
                    ORDER BY creado_en DESC
                    LIMIT 1
                """, (correo, codigo))
                return cursor.fetchone() is not None
        finally:
            Database.release(conn)

    @staticmethod
    def restablecer_contrasena(correo: str, codigo: str, nueva_contrasena: str) -> bool:
        from app.utils.auth import PasswordHash

        conn = Database.get_connection()
        try:
            with conn.cursor() as cursor:
                # Verificar código válido
                cursor.execute("""
                    SELECT id FROM password_reset_codes
                    WHERE correo   = %s
                      AND codigo   = %s
                      AND usado    = FALSE
                      AND expira_en > NOW()
                    ORDER BY creado_en DESC
                    LIMIT 1
                """, (correo, codigo))
                reset = cursor.fetchone()

                if not reset:
                    raise Exception("Código inválido o expirado")

                # Actualizar contraseña
                nuevo_hash = PasswordHash.hash_password(nueva_contrasena)
                cursor.execute("""
                    UPDATE cuentas SET contrasena = %s WHERE correo = %s
                """, (nuevo_hash, correo))

                # Marcar código como usado
                cursor.execute("""
                    UPDATE password_reset_codes SET usado = TRUE WHERE id = %s
                """, (reset["id"],))

                conn.commit()
                return True

        except Exception as e:
            conn.rollback()
            raise e
        finally:
            Database.release(conn)