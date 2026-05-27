from app.database import get_cursor, get_cursor_simple, Database
from app.utils.auth import PasswordHash
from app.utils.qr_manager import QRGenerator
from datetime import datetime

class UsuarioModel:
    @staticmethod
    def crear_usuario(nombre: str, apellido: str, correo: str, contrasena: str, telefono: str, codigo_estudiante: str, rol: str = "usuario"):
        cursor = get_cursor_simple()
        conn = Database.get_connection()
        hash_pwd = PasswordHash.hash_password(contrasena)
        try:
            cursor.execute("""
                INSERT INTO cuentas(nombre, apellido, correo, contrasena, telefono, codigo_estudiante, rol)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
                RETURNING id
            """, (nombre, apellido, correo, hash_pwd, telefono, codigo_estudiante, rol))
            usuario_id = cursor.fetchone()[0]
            conn.commit()
            return {"id": usuario_id, "nombre": nombre, "apellido": apellido, "correo": correo, "rol": rol}
        except Exception as e:
            conn.rollback()
            raise e
        finally:
            cursor.close()

    @staticmethod
    def obtener_por_correo(correo: str):
        cursor = get_cursor_simple()
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
        cursor = get_cursor_simple()
        cursor.execute("""
            SELECT id, nombre, correo, rol
            FROM cuentas
            WHERE id = %s
        """, (usuario_id,))
        resultado = cursor.fetchone()
        cursor.close()
        return resultado


class ObjetoModel:
    @staticmethod
    def crear_objeto(nombre: str, categoria_id: int, usuario_id: int, descripcion: str = None):
        cursor = get_cursor_simple()
        conn = Database.get_connection()
        qr_code = QRGenerator.generate_unique_qr_code()
        try:
            cursor.execute("""
                INSERT INTO objetos(nombre, qr_code, categoria_id, usuario_id, descripcion)
                VALUES (%s, %s, %s, %s, %s)
                RETURNING id
            """, (nombre, qr_code, categoria_id, usuario_id, descripcion))
            objeto_id = cursor.fetchone()[0]
            conn.commit()
            return {"id": objeto_id, "nombre": nombre, "qr_code": qr_code}
        except Exception as e:
            conn.rollback()
            raise e
        finally:
            cursor.close()

    @staticmethod
    def obtener_todos():
        cursor = get_cursor_simple()
        cursor.execute("""
            SELECT o.id, o.nombre, o.qr_code, o.descripcion, c.nombre as categoria, u.nombre as dueno
            FROM objetos o
            JOIN categorias c ON o.categoria_id = c.id
            JOIN cuentas u ON o.usuario_id = u.id
            ORDER BY o.nombre
        """)
        datos = cursor.fetchall()
        cursor.close()
        resultado = []
        for fila in datos:
            resultado.append({
                "id": fila[0],
                "nombre": fila[1],
                "qr_code": fila[2],
                "descripcion": fila[3],
                "categoria": fila[4],
                "dueno": fila[5]
            })
        return resultado

    @staticmethod
    def obtener_por_qr(qr_code: str):
        cursor = get_cursor_simple()
        cursor.execute("""
            SELECT o.id, o.nombre, o.qr_code, o.descripcion, c.nombre as categoria, u.nombre as dueno, o.usuario_id
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
        cursor = get_cursor_simple()
        cursor.execute("""
            SELECT o.id, o.nombre, o.qr_code, o.descripcion, c.nombre as categoria, u.nombre as dueno, o.fecha_creacion
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
        cursor = get_cursor_simple()
        cursor.execute("""
            SELECT o.id, o.nombre, o.qr_code, o.descripcion, c.nombre as categoria, o.fecha_creacion, o.usuario_id
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
    def registrar_escaneo(objeto_id: int, ubicacion: str = None, dispositivo: str = "ESP32", usuario_id: int = None):
        cursor = get_cursor_simple()
        conn = Database.get_connection()
        try:
            if usuario_id is None:
                cursor.execute("SELECT usuario_id FROM objetos WHERE id = %s", (objeto_id,))
                resultado = cursor.fetchone()
                if resultado:
                    usuario_id = resultado[0]
                else:
                    raise Exception("Objeto no encontrado")
            cursor.execute("""
                INSERT INTO escaneos(objeto_id, ubicacion, dispositivo, usuario_id)
                VALUES (%s, %s, %s, %s)
                RETURNING id
            """, (objeto_id, ubicacion, dispositivo, usuario_id))
            escaneo_id = cursor.fetchone()[0]
            conn.commit()
            return {"id": escaneo_id}
        except Exception as e:
            conn.rollback()
            raise e
        finally:
            cursor.close()

    @staticmethod
    def obtener_historial(limite: int = 100):
        cursor = get_cursor_simple()
        cursor.execute("""
            SELECT e.id, o.nombre, o.qr_code, e.ubicacion, e.dispositivo, e.fecha_hora, u.nombre as alumno
            FROM escaneos e
            JOIN objetos o ON e.objeto_id = o.id
            JOIN cuentas u ON e.usuario_id = u.id
            ORDER BY e.fecha_hora DESC
            LIMIT %s
        """, (limite,))
        datos = cursor.fetchall()
        cursor.close()
        resultado = []
        for fila in datos:
            resultado.append({
                "id": fila[0],
                "objeto": fila[1],
                "qr_code": fila[2],
                "ubicacion": fila[3],
                "dispositivo": fila[4],
                "fecha_hora": str(fila[5]),
                "alumno": fila[6]
            })
        return resultado

    @staticmethod
    def obtener_historial_objeto(objeto_id: int, limite: int = 50):
        cursor = get_cursor_simple()
        cursor.execute("""
            SELECT e.id, e.ubicacion, e.dispositivo, e.fecha_hora
            FROM escaneos e
            WHERE e.objeto_id = %s
            ORDER BY e.fecha_hora DESC
            LIMIT %s
        """, (objeto_id, limite))
        resultado = cursor.fetchall()
        cursor.close()
        return resultado

    @staticmethod
    def obtener_historial_usuario(usuario_id: int, limite: int = 100):
        cursor = get_cursor_simple()
        cursor.execute("""
            SELECT e.id, o.id as objeto_id, o.nombre, o.qr_code, e.ubicacion, e.dispositivo, e.fecha_hora
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
        cursor = get_cursor_simple()
        cursor.execute("SELECT COUNT(*) FROM objetos")
        total_objetos = cursor.fetchone()[0]
        cursor.execute("SELECT COUNT(*) FROM escaneos")
        total_escaneos = cursor.fetchone()[0]
        cursor.execute("SELECT COUNT(*) FROM categorias")
        total_categorias = cursor.fetchone()[0]
        cursor.execute("""
            SELECT c.nombre, COUNT(o.id) as cantidad
            FROM categorias c
            LEFT JOIN objetos o ON c.id = o.categoria_id
            GROUP BY c.id, c.nombre
        """)
        objetos_por_categoria = {row[0]: row[1] for row in cursor.fetchall()}
        cursor.execute("""
            SELECT dispositivo, COUNT(*) as cantidad
            FROM escaneos
            GROUP BY dispositivo
        """)
        escaneos_por_dispositivo = {row[0]: row[1] for row in cursor.fetchall()}
        cursor.execute("""
            SELECT COUNT(*) FROM escaneos
            WHERE fecha_hora >= NOW() - INTERVAL '1 day'
        """)
        escaneos_ultimo_dia = cursor.fetchone()[0]
        cursor.execute("""
            SELECT COUNT(*) FROM escaneos
            WHERE fecha_hora >= NOW() - INTERVAL '7 days'
        """)
        escaneos_ultima_semana = cursor.fetchone()[0]
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