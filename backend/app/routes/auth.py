# Backend routes - Autenticación

from fastapi import APIRouter, HTTPException
from app.schemas.schemas import LoginRequest, LoginResponse, UsuarioCreate
from app.models.models import UsuarioModel
from app.utils.auth import PasswordHash, TokenManager

router = APIRouter(prefix="/auth", tags=["autenticacion"])

@router.post("/login", response_model=LoginResponse)
def login(datos: LoginRequest):
    """Endpoint de login con autenticación segura"""
    
    usuario = UsuarioModel.obtener_por_correo(datos.correo)
    
    if not usuario:
        raise HTTPException(status_code=401, detail="Correo o contraseña incorrectos")
    
    usuario_id, nombre, correo, contraseña_hash, rol = usuario

    # 🔥 DEBUG IMPORTANTE
    print("HASH DESDE DB:", repr(contraseña_hash))

    if not PasswordHash.verify_password(datos.contrasena, contraseña_hash):
        raise HTTPException(status_code=401, detail="Correo o contraseña incorrectos")
    
    token = TokenManager.create_access_token(
        data={"sub": str(usuario_id), "correo": correo, "rol": rol}
    )
    
    return {
        "mensaje": "Login correcto",
        "nombre": nombre,
        "rol": rol,
        "token": token
    }

@router.post("/registro", response_model=dict)
def registro(usuario_data: UsuarioCreate):
    """Endpoint para registrar nuevos usuarios"""
    
    usuario_existente = UsuarioModel.obtener_por_correo(usuario_data.correo)
    if usuario_existente:
        raise HTTPException(status_code=400, detail="El correo ya está registrado")
    
    try:
        usuario = UsuarioModel.crear_usuario(
            nombre=usuario_data.nombre,
            apellido=usuario_data.apellido,
            correo=usuario_data.correo,
            telefono=usuario_data.telefono,
            codigo_estudiante=usuario_data.codigo_estudiante,
            contrasena=usuario_data.contrasena,
            rol=usuario_data.rol
        )
        return {"mensaje": "Usuario registrado exitosamente", "usuario": usuario}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
