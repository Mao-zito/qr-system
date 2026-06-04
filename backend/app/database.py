import os
import psycopg2
from psycopg2.extras import RealDictCursor


class Database:

    @staticmethod
    def connect():
        DATABASE_URL = os.getenv("DATABASE_URL")

        if not DATABASE_URL:
            raise Exception("DATABASE_URL no está configurada")

        return psycopg2.connect(
            dsn=DATABASE_URL,
            cursor_factory=RealDictCursor,
            sslmode="require"
        )


def get_cursor():
    conn = Database.connect()
    return conn.cursor()


def get_cursor_simple():
    conn = Database.connect()
    return conn.cursor()