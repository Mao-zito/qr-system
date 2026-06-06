import bcrypt
from datetime import datetime, timedelta, timezone
from typing import Optional
import jwt
from fastapi import HTTPException, Header
from app.config import settings


class PasswordHash:
    """Utilidades para hash de contraseñas con bcrypt"""

    @staticmethod
    def hash_password(password: str) -> str:
        salt = bcrypt.gensalt()
        return bcrypt.hashpw(password.encode(), salt).decode()

    @staticmethod
    def verify_password(password: str, hash_password: str) -> bool:
        return bcrypt.checkpw(password.encode(), hash_password.encode())


class TokenManager:
    """Manejo de tokens JWT"""

    @staticmethod
    def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
        to_encode = data.copy()
        # ✅ datetime.utcnow() deprecado en Python 3.12 — usar timezone.utc
        if expires_delta:
            expire = datetime.now(timezone.utc) + expires_delta
        else:
            expire = datetime.now(timezone.utc) + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)

        to_encode.update({"exp": expire})
        return jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)

    @staticmethod
    def verify_token(token: str) -> dict:
        try:
            return jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        except jwt.ExpiredSignatureError:
            raise Exception("Token expirado")
        except jwt.InvalidTokenError:
            raise Exception("Token inválido")

    @staticmethod
    def verify_token_from_header(authorization: str = Header(None)) -> dict:
        if not authorization:
            raise HTTPException(status_code=401, detail="Token no proporcionado")

        parts = authorization.split()
        if len(parts) != 2 or parts[0] != "Bearer":
            raise HTTPException(status_code=401, detail="Formato de token inválido")

        try:
            return TokenManager.verify_token(parts[1])
        except Exception as e:
            raise HTTPException(status_code=401, detail=str(e))