from app.database import Database
from app.utils.auth import PasswordHash
from app.utils.qr_manager import QRGenerator


class UsuarioModel:

    @staticmethod
    def crear_usuario(
        nombre: str,
        apellido: str,
        correo: str,
        contrasena: str,
        telefono: str,
        codigo_estudiante: str,
        rol: str = "usuario"
    ):
        # FIX 1: una sola conexión, cursor de la misma conexión
        conn = Database.get_connection()
        cursor = conn.cursor()

        hash_pwd = PasswordHash.hash_password(contrasena)

        try:
            cursor.execute("""
                INSERT INTO cuentas(
                    nombre,
                    apellido,
                    correo,
                    contrasena,
                    telefono,
                    codigo_estudiante,
                    rol
                )
                VALUES (%s, %s, %s, %s, %s, %s, %s)
                RETURNING id, nombre, apellido, correo, rol
            """, (
                nombre,
                apellido,
                correo,
                hash_pwd,
                telefono,
                codigo_estudiante,
                rol
            ))

            row = cursor.fetchone()
            conn.commit()

            return {
                "id": row["id"],
                "nombre": row["nombre"],
                "apellido": row["apellido"],
                "correo": row["correo"],
                "rol": row["rol"]
            }

        except Exception as e:
            conn.rollback()
            import traceback
            print("Error real completo:")
            print(traceback.format_exc())
            raise e

        finally:
            cursor.close()

    @staticmethod
    def obtener_por_correo(correo: str):
        conn = Database.get_connection()
        cursor = conn.cursor()

        cursor.execute("""
            SELECT id, nombre, correo, contrasena, rol
            FROM cuentas
            WHERE correo = %s
        """, (correo,))

        resultado = cursor.fetchone()
        cursor.close()
        return resultado

    @staticmethod
    def obtener_por_id(usuario_id: int):
        conn = Database.get_connection()
        cursor = conn.cursor()

        cursor.execute("""
            SELECT id, nombre, correo, rol
            FROM cuentas
            WHERE id = %s
        """, (usuario_id,))

        resultado = cursor.fetchone()
        cursor.close()
        return resultado

    @staticmethod
    def obtener_perfil(usuario_id: int):
        conn = Database.get_connection()
        cursor = conn.cursor()

        cursor.execute("""
            SELECT
                id,
                nombre,
                apellido,
                correo,
                telefono,
                codigo_estudiante,
                rol,
                foto_perfil
            FROM cuentas
            WHERE id = %s
        """, (usuario_id,))

        resultado = cursor.fetchone()
        cursor.close()
        return resultado

    @staticmethod
    def actualizar_perfil(
        usuario_id: int,
        nombre: str = None,
        apellido: str = None,
        telefono: str = None,
        foto_perfil: str = None
    ):
        conn = Database.get_connection()
        cursor = conn.cursor()

        try:
            campos = []
            valores = []

            if nombre is not None:
                campos.append("nombre = %s")
                valores.append(nombre)

            if apellido is not None:
                campos.append("apellido = %s")
                valores.append(apellido)

            if telefono is not None:
                campos.append("telefono = %s")
                valores.append(telefono)

            if foto_perfil is not None:
                campos.append("foto_perfil = %s")
                valores.append(foto_perfil)

            if not campos:
                return None

            valores.append(usuario_id)

            cursor.execute(f"""
                UPDATE cuentas
                SET {', '.join(campos)}
                WHERE id = %s
                RETURNING
                    id,
                    nombre,
                    apellido,
                    correo,
                    telefono,
                    codigo_estudiante,
                    rol,
                    foto_perfil
            """, valores)

            resultado = cursor.fetchone()
            conn.commit()
            return resultado

        except Exception as e:
            conn.rollback()
            raise e

        finally:
            cursor.close()

    @staticmethod
    def cambiar_contrasena(
        usuario_id: int,
        contrasena_actual: str,
        contrasena_nueva: str
    ):
        conn = Database.get_connection()
        cursor = conn.cursor()

        try:
            cursor.execute("""
                SELECT contrasena
                FROM cuentas
                WHERE id = %s
            """, (usuario_id,))

            resultado = cursor.fetchone()

            if not resultado:
                raise Exception("Usuario no encontrado")

            hash_guardado = resultado["contrasena"]

            # FIX 3: validar que el hash sea bcrypt antes de verificar
            if not hash_guardado or not hash_guardado.startswith("$2b$"):
                raise Exception("Hash inválido en BD. Re-registra el usuario.")

            if not PasswordHash.verify_password(contrasena_actual, hash_guardado):
                raise Exception("Contraseña actual incorrecta")

            nuevo_hash = PasswordHash.hash_password(contrasena_nueva)

            cursor.execute("""
                UPDATE cuentas
                SET contrasena = %s
                WHERE id = %s
            """, (nuevo_hash, usuario_id))

            conn.commit()
            return True

        except Exception as e:
            conn.rollback()
            raise e

        finally:
            cursor.close()

    @staticmethod
    def obtener_alumnos_con_estado():
        conn = Database.get_connection()
        cursor = conn.cursor()

        cursor.execute("""
            SELECT 
                u.id,
                u.nombre,
                u.apellido,
                u.codigo_estudiante,
                u.telefono,
                u.correo,
                u.foto_perfil,
                e.tipo_evento as ultimo_evento,
                e.fecha_hora as ultima_fecha
            FROM cuentas u
            LEFT JOIN (
                SELECT DISTINCT ON (usuario_id) 
                    usuario_id, tipo_evento, fecha_hora
                FROM escaneos
                ORDER BY usuario_id, fecha_hora DESC
            ) e ON u.id = e.usuario_id
            WHERE u.rol != 'admin'
            ORDER BY u.nombre
        """)

        datos = cursor.fetchall()
        cursor.close()

        # FIX 4: usar claves de dict en lugar de índices numéricos
        return [
            {
                "id": fila["id"],
                "nombre": fila["nombre"],
                "apellido": fila["apellido"],
                "codigo_estudiante": fila["codigo_estudiante"],
                "telefono": fila["telefono"],
                "correo": fila["correo"],
                "foto_perfil": fila["foto_perfil"],
                "ultimo_evento": fila["ultimo_evento"],
                "ultima_fecha": str(fila["ultima_fecha"]) if fila["ultima_fecha"] else None
            }
            for fila in datos
        ]

    @staticmethod
    def obtener_historial_alumno(usuario_id: int, limite: int = 50):
        conn = Database.get_connection()
        cursor = conn.cursor()

        cursor.execute("""
            SELECT e.id, o.nombre, o.qr_code, e.ubicacion, 
                   e.dispositivo, e.fecha_hora, e.tipo_evento
            FROM escaneos e
            JOIN objetos o ON e.objeto_id = o.id
            WHERE e.usuario_id = %s
            ORDER BY e.fecha_hora DESC
            LIMIT %s
        """, (usuario_id, limite))

        datos = cursor.fetchall()
        cursor.close()

        # FIX 4: usar claves de dict
        return [
            {
                "id": fila["id"],
                "objeto": fila["nombre"],
                "qr_code": fila["qr_code"],
                "ubicacion": fila["ubicacion"],
                "dispositivo": fila["dispositivo"],
                "fecha_hora": str(fila["fecha_hora"]),
                "tipo_evento": fila["tipo_evento"]
            }
            for fila in datos
        ]


class ObjetoModel:

    @staticmethod
    def crear_objeto(
        nombre: str,
        categoria_id: int,
        usuario_id: int,
        descripcion: str = None
    ):
        conn = Database.get_connection()
        cursor = conn.cursor()

        qr_code = QRGenerator.generate_unique_qr_code()

        try:
            cursor.execute("""
                INSERT INTO objetos(
                    nombre,
                    qr_code,
                    categoria_id,
                    usuario_id,
                    descripcion
                )
                VALUES (%s, %s, %s, %s, %s)
                RETURNING id
            """, (nombre, qr_code, categoria_id, usuario_id, descripcion))

            objeto_id = cursor.fetchone()["id"]
            conn.commit()

            return {
                "id": objeto_id,
                "nombre": nombre,
                "qr_code": qr_code
            }

        except Exception as e:
            conn.rollback()
            raise e

        finally:
            cursor.close()

    @staticmethod
    def obtener_todos():
        conn = Database.get_connection()
        cursor = conn.cursor()

        cursor.execute("""
            SELECT
                o.id,
                o.nombre,
                o.qr_code,
                o.descripcion,
                c.nombre as categoria,
                u.nombre as dueno
            FROM objetos o
            JOIN categorias c ON o.categoria_id = c.id
            JOIN cuentas u ON o.usuario_id = u.id
            ORDER BY o.nombre
        """)

        datos = cursor.fetchall()
        cursor.close()

        return [
            {
                "id": fila["id"],
                "nombre": fila["nombre"],
                "qr_code": fila["qr_code"],
                "descripcion": fila["descripcion"],
                "categoria": fila["categoria"],
                "dueno": fila["dueno"]
            }
            for fila in datos
        ]

    @staticmethod
    def obtener_por_qr(qr_code: str):
        conn = Database.get_connection()
        cursor = conn.cursor()

        cursor.execute("""
            SELECT
                o.id,
                o.nombre,
                o.qr_code,
                o.descripcion,
                c.nombre as categoria,
                u.nombre as dueno,
                o.usuario_id
            FROM objetos o
            JOIN categorias c ON o.categoria_id = c.id
            JOIN cuentas u ON o.usuario_id = u.id
            WHERE o.qr_code = %s
        """, (qr_code,))

        resultado = cursor.fetchone()
        cursor.close()
        return resultado

    @staticmethod
    def obtener_por_id(objeto_id: int):
        conn = Database.get_connection()
        cursor = conn.cursor()

        cursor.execute("""
            SELECT
                o.id,
                o.nombre,
                o.qr_code,
                o.descripcion,
                c.nombre as categoria,
                u.nombre as dueno,
                o.fecha_creacion
            FROM objetos o
            JOIN categorias c ON o.categoria_id = c.id
            JOIN cuentas u ON o.usuario_id = u.id
            WHERE o.id = %s
        """, (objeto_id,))

        resultado = cursor.fetchone()
        cursor.close()
        return resultado

    @staticmethod
    def obtener_objetos_usuario(usuario_id: int):
        conn = Database.get_connection()
        cursor = conn.cursor()

        cursor.execute("""
            SELECT
                o.id,
                o.nombre,
                o.qr_code,
                o.descripcion,
                c.nombre as categoria,
                o.fecha_creacion,
                o.usuario_id
            FROM objetos o
            LEFT JOIN categorias c ON o.categoria_id = c.id
            WHERE o.usuario_id = %s
            ORDER BY o.fecha_creacion DESC
        """, (usuario_id,))

        resultado = cursor.fetchall()
        cursor.close()
        return resultado


class EscaneoModel:

    @staticmethod
    def registrar_escaneo(
        objeto_id: int,
        ubicacion: str = None,
        dispositivo: str = "ESP32",
        usuario_id: int = None
    ):
        conn = Database.get_connection()
        cursor = conn.cursor()

        try:
            if usuario_id is None:
                cursor.execute("SELECT usuario_id FROM objetos WHERE id = %s", (objeto_id,))
                resultado = cursor.fetchone()
                if resultado:
                    usuario_id = resultado["usuario_id"]
                else:
                    raise Exception("Objeto no encontrado")

            cursor.execute("""
                SELECT tipo_evento FROM escaneos
                WHERE objeto_id = %s
                ORDER BY fecha_hora DESC
                LIMIT 1
            """, (objeto_id,))
            ultimo = cursor.fetchone()

            if ultimo is None or ultimo["tipo_evento"] == 'SALIDA':
                tipo_evento = 'ENTRADA'
            else:
                tipo_evento = 'SALIDA'

            cursor.execute("""
                INSERT INTO escaneos(objeto_id, ubicacion, dispositivo, usuario_id, tipo_evento)
                VALUES (%s, %s, %s, %s, %s)
                RETURNING id
            """, (objeto_id, ubicacion, dispositivo, usuario_id, tipo_evento))

            escaneo_id = cursor.fetchone()["id"]
            conn.commit()
            return {"id": escaneo_id, "tipo_evento": tipo_evento}

        except Exception as e:
            conn.rollback()
            raise e

        finally:
            cursor.close()

    @staticmethod
    def obtener_historial(limite: int = 100):
        conn = Database.get_connection()
        cursor = conn.cursor()

        cursor.execute("""
            SELECT
                e.id,
                o.nombre,
                o.qr_code,
                e.ubicacion,
                e.dispositivo,
                e.fecha_hora,
                u.nombre as alumno,
                u.apellido,
                u.codigo_estudiante,
                u.telefono,
                e.tipo_evento
            FROM escaneos e
            JOIN objetos o ON e.objeto_id = o.id
            JOIN cuentas u ON e.usuario_id = u.id
            ORDER BY e.fecha_hora DESC
            LIMIT %s
        """, (limite,))

        datos = cursor.fetchall()
        cursor.close()

        # FIX 4: usar claves de dict
        return [
            {
                "id": fila["id"],
                "objeto": fila["nombre"],
                "qr_code": fila["qr_code"],
                "ubicacion": fila["ubicacion"],
                "dispositivo": fila["dispositivo"],
                "fecha_hora": str(fila["fecha_hora"]),
                "alumno": fila["alumno"],
                "apellido": fila["apellido"],
                "codigo_estudiante": fila["codigo_estudiante"],
                "telefono": fila["telefono"],
                "tipo_evento": fila["tipo_evento"]
            }
            for fila in datos
        ]

    @staticmethod
    def obtener_historial_objeto(
        objeto_id: int,
        limite: int = 50
    ):
        conn = Database.get_connection()
        cursor = conn.cursor()

        cursor.execute("""
            SELECT
                e.id,
                e.ubicacion,
                e.dispositivo,
                e.fecha_hora
            FROM escaneos e
            WHERE e.objeto_id = %s
            ORDER BY e.fecha_hora DESC
            LIMIT %s
        """, (objeto_id, limite))

        resultado = cursor.fetchall()
        cursor.close()
        return resultado

    @staticmethod
    def obtener_historial_usuario(
        usuario_id: int,
        limite: int = 100
    ):
        conn = Database.get_connection()
        cursor = conn.cursor()

        cursor.execute("""
            SELECT
                e.id,
                o.id as objeto_id,
                o.nombre,
                o.qr_code,
                e.ubicacion,
                e.dispositivo,
                e.fecha_hora
            FROM escaneos e
            JOIN objetos o ON e.objeto_id = o.id
            WHERE e.usuario_id = %s
            ORDER BY e.fecha_hora DESC
            LIMIT %s
        """, (usuario_id, limite))

        resultado = cursor.fetchall()
        cursor.close()
        return resultado


class EstadisticasModel:

    @staticmethod
    def obtener_estadisticas():
        conn = Database.get_connection()
        cursor = conn.cursor()

        cursor.execute("SELECT COUNT(*) as total FROM objetos")
        total_objetos = cursor.fetchone()["total"]

        cursor.execute("SELECT COUNT(*) as total FROM escaneos")
        total_escaneos = cursor.fetchone()["total"]

        cursor.execute("SELECT COUNT(*) as total FROM categorias")
        total_categorias = cursor.fetchone()["total"]

        cursor.execute("""
            SELECT
                c.nombre,
                COUNT(o.id) as cantidad
            FROM categorias c
            LEFT JOIN objetos o ON c.id = o.categoria_id
            GROUP BY c.id, c.nombre
        """)
        objetos_por_categoria = {row["nombre"]: row["cantidad"] for row in cursor.fetchall()}

        cursor.execute("""
            SELECT
                dispositivo,
                COUNT(*) as cantidad
            FROM escaneos
            GROUP BY dispositivo
        """)
        escaneos_por_dispositivo = {row["dispositivo"]: row["cantidad"] for row in cursor.fetchall()}

        cursor.execute("""
            SELECT COUNT(*) as total
            FROM escaneos
            WHERE fecha_hora >= NOW() - INTERVAL '1 day'
        """)
        escaneos_ultimo_dia = cursor.fetchone()["total"]

        cursor.execute("""
            SELECT COUNT(*) as total
            FROM escaneos
            WHERE fecha_hora >= NOW() - INTERVAL '7 days'
        """)
        escaneos_ultima_semana = cursor.fetchone()["total"]

        cursor.close()

        return {
            "total_objetos": total_objetos,
            "total_escaneos": total_escaneos,
            "total_categorias": total_categorias,
            "objetos_por_categoria": objetos_por_categoria,
            "escaneos_por_dispositivo": escaneos_por_dispositivo,
            "escaneos_ultimo_dia": escaneos_ultimo_dia,
            "escaneos_ultima_semana": escaneos_ultima_semana
        }