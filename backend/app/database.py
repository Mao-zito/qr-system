import os
import psycopg2
from psycopg2.extras import RealDictCursor

class Database:
    _connection = None

    @classmethod
    def connect(cls):
        if cls._connection is None:
            cls._connection = psycopg2.connect(
                host=os.getenv("DB_HOST"),
                database=os.getenv("DB_NAME"),
                user=os.getenv("DB_USER"),
                password=os.getenv("DB_PASSWORD"),
                port=os.getenv("DB_PORT"),
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


def get_cursor():
    conn = Database.get_connection()
    return conn.cursor()


def get_cursor_simple():
    conn = Database.get_connection()
    return conn.cursor()