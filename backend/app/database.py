import os
import psycopg2
from psycopg2.extras import RealDictCursor

class Database:
    _connection = None

    @classmethod
    def connect(cls):
        if cls._connection is None:
            DATABASE_URL = os.getenv("DATABASE_URL")

            if not DATABASE_URL:
                raise Exception("DATABASE_URL no está configurada")

            cls._connection = psycopg2.connect(
                DATABASE_URL,
                cursor_factory=RealDictCursor,
                sslmode="require"
            )

        return cls._connection


def get_cursor():
    conn = Database.connect()
    return conn.cursor(), conn