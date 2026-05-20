import bcrypt
from datetime import datetime, timedelta
from typing import Optional
import jwt
from fastapi import HTTPException, Header
from app.config import settings

class PasswordHash:
    """Utilidades para hash de contraseñas con bcrypt"""
    
    @staticmethod
    def hash_password(password: str) -> str:
        """Genera hash de contraseña"""
        salt = bcrypt.gensalt()
        return bcrypt.hashpw(password.encode(), salt).decode()
    
    @staticmethod
    def verify_password(password: str, hash_password: str) -> bool:
        """Verifica contraseña contra hash"""
        return bcrypt.checkpw(password.encode(), hash_password.encode())

class TokenManager:
    """Manejo de tokens JWT"""
    
    @staticmethod
    def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
        """Crea token JWT"""
        to_encode = data.copy()
        if expires_delta:
            expire = datetime.utcnow() + expires_delta
        else:
            expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
        
        to_encode.update({"exp": expire})
        encoded_jwt = jwt.encode(
            to_encode,
            settings.SECRET_KEY,
            algorithm=settings.ALGORITHM
        )
        return encoded_jwt
    
    @staticmethod
    def verify_token(token: str) -> dict:
        """Verifica y decodifica token JWT"""
        try:
            payload = jwt.decode(
                token,
                settings.SECRET_KEY,
                algorithms=[settings.ALGORITHM]
            )
            return payload
        except jwt.ExpiredSignatureError:
            raise Exception("Token expirado")
        except jwt.InvalidTokenError:
            raise Exception("Token inválido")
    
    @staticmethod
    def verify_token_from_header(authorization: str = Header(None)) -> dict:
        """Extrae y verifica token del header Authorization"""
        if not authorization:
            raise HTTPException(status_code=401, detail="Token no proporcionado")
        
        parts = authorization.split()
        if len(parts) != 2 or parts[0] != "Bearer":
            raise HTTPException(status_code=401, detail="Formato de token inválido")
        
        token = parts[1]
        try:
            payload = TokenManager.verify_token(token)
            return payload
        except Exception as e:
            raise HTTPException(status_code=401, detail=str(e))
