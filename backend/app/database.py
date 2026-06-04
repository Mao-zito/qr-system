import os
import psycopg2
from psycopg2.extras import RealDictCursor


class Database:
    _connection = None

    @classmethod
    def connect(cls):
        if cls._connection is None:
            DATABASE_URL = os.getenv("DATABASE_URL")

            print("Conectando a la base de datos...")
            print("DATABASE_URL:", DATABASE_URL)

            if not DATABASE_URL:
                raise Exception("DATABASE_URL no está configurada en variables de entorno")

            cls._connection = psycopg2.connect(
                DATABASE_URL,
                cursor_factory=RealDictCursor,
                sslmode="require"
            )

            print("✅ Conectado a la base de datos")

        return cls._connection

    @classmethod
    def get_connection(cls):
        if cls._connection is None:
            return cls.connect()
        return cls._connection

    @classmethod
    def close(cls):
        if cls._connection:
            cls._connection.close()
            cls._connection = None


# =========================
# CURSORES (IMPORTANTE)
# =========================

def get_cursor():
    conn = Database.get_connection()
    return conn.cursor()


def get_cursor_simple():
    conn = Database.get_connection()
    return conn.cursor()