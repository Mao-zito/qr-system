from fastapi import APIRouter, HTTPException, Depends
from app.schemas.schemas import PerfilResponse, PerfilUpdate, CambiarContrasena
from app.models.models import UsuarioModel
from app.utils.auth import TokenManager

router = APIRouter(prefix="/auth", tags=["perfil"])

@router.get("/perfil", response_model=dict)
def obtener_perfil(token: dict = Depends(TokenManager.verify_token_from_header)):
    try:
        usuario_id = int(token.get("sub"))
        usuario = UsuarioModel.obtener_perfil(usuario_id)
        if not usuario:
            raise HTTPException(status_code=404, detail="Usuario no encontrado")
        return {
            "id": usuario[0],
            "nombre": usuario[1],
            "apellido": usuario[2],
            "correo": usuario[3],
            "telefono": usuario[4],
            "codigo_estudiante": usuario[5],
            "rol": usuario[6],
            "foto_perfil": usuario[7]
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.put("/perfil", response_model=dict)
def actualizar_perfil(
    datos: PerfilUpdate,
    token: dict = Depends(TokenManager.verify_token_from_header)
):
    try:
        usuario_id = int(token.get("sub"))
        resultado = UsuarioModel.actualizar_perfil(
            usuario_id=usuario_id,
            nombre=datos.nombre,
            apellido=datos.apellido,
            telefono=datos.telefono,
            foto_perfil=datos.foto_perfil
        )
        if not resultado:
            raise HTTPException(status_code=400, detail="No hay datos para actualizar")
        return {
            "id": resultado[0],
            "nombre": resultado[1],
            "apellido": resultado[2],
            "correo": resultado[3],
            "telefono": resultado[4],
            "codigo_estudiante": resultado[5],
            "rol": resultado[6],
            "foto_perfil": resultado[7]
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/cambiar-contrasena", response_model=dict)
def cambiar_contrasena(
    datos: CambiarContrasena,
    token: dict = Depends(TokenManager.verify_token_from_header)
):
    try:
        usuario_id = int(token.get("sub"))
        UsuarioModel.cambiar_contrasena(
            usuario_id=usuario_id,
            contrasena_actual=datos.contrasena_actual,
            contrasena_nueva=datos.contrasena_nueva
        )
        return {"mensaje": "Contraseña cambiada exitosamente"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))