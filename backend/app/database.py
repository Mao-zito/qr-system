import os
import psycopg2
from psycopg2.extras import RealDictCursor


class Database:

    @classmethod
    def connect(cls):
        DATABASE_URL = os.getenv("DATABASE_URL")

        if not DATABASE_URL:
            raise Exception("DATABASE_URL no está configurada")

        conn = psycopg2.connect(
            DATABASE_URL,
            cursor_factory=RealDictCursor,
            sslmode="require"
        )

        print("Conexión establecida")
        return conn


def get_cursor():
    conn = Database.connect()
    return conn.cursor(), conn


def get_cursor_simple():
    conn = Database.connect()
    return conn.cursor(), conn