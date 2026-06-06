import os
import traceback
import psycopg2
from psycopg2 import pool
from psycopg2.extras import RealDictCursor


class Database:
    _pool = None

    @classmethod
    def init(cls):
        DATABASE_URL = os.getenv("DATABASE_URL")
        if not DATABASE_URL:
            raise Exception("DATABASE_URL no está configurada")

        cls._pool = pool.ThreadedConnectionPool(
            minconn=1,
            maxconn=5,
            dsn=DATABASE_URL,
            cursor_factory=RealDictCursor,
            sslmode="require"
        )
        print("Pool de conexiones iniciado")

    @classmethod
    def get_connection(cls):
        try:
            if cls._pool is None:
                cls.init()
            return cls._pool.getconn()
        except Exception:
            print("Error obteniendo conexión del pool:")
            print(traceback.format_exc())
            raise

    @classmethod
    def release(cls, conn):
        try:
            if cls._pool and conn:
                cls._pool.putconn(conn)
        except Exception:
            print("Error liberando conexión:")
            print(traceback.format_exc())