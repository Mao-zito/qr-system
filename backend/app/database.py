import psycopg2
from psycopg2.extras import RealDictCursor
from app.config import settings

class Database:
    _connection = None
    
    @classmethod
    def connect(cls):
        """Establece conexión a la base de datos"""
        if cls._connection is None:
            cls._connection = psycopg2.connect(
                host=settings.DB_HOST,
                port=settings.DB_PORT,
                database=settings.DB_NAME,
                user=settings.DB_USER,
                password=settings.DB_PASSWORD
            )
        return cls._connection
    
    @classmethod
    def get_connection(cls):
        """Obtiene la conexión existente"""
        if cls._connection is None:
            return cls.connect()
        return cls._connection
    
    @classmethod
    def close(cls):
        """Cierra la conexión"""
        if cls._connection:
            cls._connection.close()
            cls._connection = None

# Función para obtener cursor
def get_cursor():
    conn = Database.get_connection()
    return conn.cursor(cursor_factory=RealDictCursor)

# Función para obtener cursor simple
def get_cursor_simple():
    conn = Database.get_connection()
    return conn.cursor()
