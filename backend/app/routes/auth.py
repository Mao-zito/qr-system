from fastapi import APIRouter, HTTPException
from app.schemas.schemas import LoginRequest, LoginResponse, UsuarioCreate
from app.models.models import UsuarioModel
from app.utils.auth import PasswordHash, TokenManager

router = APIRouter(prefix="/auth", tags=["autenticacion"])


@router.post("/login", response_model=LoginResponse)
def login(datos: LoginRequest):

    usuario = UsuarioModel.obtener_por_correo(datos.correo)

    if not usuario:
        raise HTTPException(status_code=401, detail="Correo o contraseña incorrectos")

    usuario_id      = usuario["id"]
    nombre          = usuario["nombre"]
    correo          = usuario["correo"]
    contrasena_hash = usuario["contrasena"]
    rol             = usuario["rol"]

    if not contrasena_hash or not contrasena_hash.startswith("$2b$"):
        raise HTTPException(
            status_code=401,
            detail="Credenciales inválidas. Vuelve a registrarte."
        )

    if not PasswordHash.verify_password(datos.contrasena, contrasena_hash):
        raise HTTPException(status_code=401, detail="Correo o contraseña incorrectos")

    token = TokenManager.create_access_token(
        data={"sub": str(usuario_id), "correo": correo, "rol": rol}
    )

    return {"mensaje": "Login correcto", "nombre": nombre, "rol": rol, "token": token}


@router.post("/registro", response_model=dict)
def registro(usuario_data: UsuarioCreate):

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
            rol="usuario"  # ✅ siempre usuario, nunca admin desde el cliente
        )
        return {"mensaje": "Usuario registrado exitosamente", "usuario": usuario}

    except Exception as e:
        print("ERROR EN REGISTRO:", str(e))
        raise HTTPException(status_code=500, detail="Error interno en registro")