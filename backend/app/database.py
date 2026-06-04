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
        try:
            if cls._connection is None or cls._connection.closed != 0:
                return cls.connect()

            # ✅ ping correcto: cursor cerrado después de usarse
            with cls._connection.cursor() as cur:
                cur.execute("SELECT 1")
                cur.fetchone()

            return cls._connection

        except Exception:
            print("Conexión caída, reconectando...")
            # ✅ cerrar la conexión vieja antes de reconectar
            try:
                cls._connection.close()
            except Exception:
                pass
            return cls.connect()