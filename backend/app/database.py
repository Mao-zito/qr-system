import os
import psycopg2
from psycopg2.extras import RealDictCursor


class Database:
    _connection = None

    @classmethod
    def connect(cls):
        DATABASE_URL = os.getenv("DATABASE_URL")

        if not DATABASE_URL:
            raise Exception("DATABASE_URL no está configurada")

        cls._connection = psycopg2.connect(
            DATABASE_URL,
            cursor_factory=RealDictCursor,
            sslmode="require"
        )

        print("Conexión establecida")
        return cls._connection

    @classmethod
    def get_connection(cls):
        if cls._connection is None:
            return cls.connect()
        return cls._connection


def get_cursor():
    conn = Database.get_connection()
    return conn.cursor(), conn


def get_cursor_simple():
    conn = Database.get_connection()
    return conn.cursor()