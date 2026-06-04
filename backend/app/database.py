import os
import psycopg2
from psycopg2.extras import RealDictCursor

class Database:
    _connection = None

    @classmethod
    def connect(cls):
        if cls._connection is None:
            DATABASE_URL = os.getenv("DATABASE_URL")

            cls._connection = psycopg2.connect(
                DATABASE_URL,
                cursor_factory=RealDictCursor,
                sslmode="require"
            )

            print("✅ Conectado a Neon DB")

        return cls._connection

    @classmethod
    def get_connection(cls):
        if cls._connection is None:
            return cls.connect()
        return cls._connection