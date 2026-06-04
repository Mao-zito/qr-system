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

        # FIX: usar claves de dict en lugar de índices numéricos
        return {
            "id": usuario["id"],
            "nombre": usuario["nombre"],
            "apellido": usuario["apellido"],
            "correo": usuario["correo"],
            "telefono": usuario["telefono"],
            "codigo_estudiante": usuario["codigo_estudiante"],
            "rol": usuario["rol"],
            "foto_perfil": usuario["foto_perfil"]
        }
    except HTTPException:
        raise
    except Exception as e:
        import traceback
        print(traceback.format_exc())
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

        # FIX: usar claves de dict
        return {
            "id": resultado["id"],
            "nombre": resultado["nombre"],
            "apellido": resultado["apellido"],
            "correo": resultado["correo"],
            "telefono": resultado["telefono"],
            "codigo_estudiante": resultado["codigo_estudiante"],
            "rol": resultado["rol"],
            "foto_perfil": resultado["foto_perfil"]
        }
    except HTTPException:
        raise
    except Exception as e:
        import traceback
        print(traceback.format_exc())
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

@router.get("/alumnos", response_model=list)
def obtener_alumnos(token: dict = Depends(TokenManager.verify_token_from_header)):
    try:
        rol = token.get("rol")
        if rol != "admin":
            raise HTTPException(status_code=403, detail="No tiene permisos")
        alumnos = UsuarioModel.obtener_alumnos_con_estado()
        return alumnos
    except HTTPException:
        raise
    except Exception as e:
        import traceback
        print(traceback.format_exc())
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/alumnos/{usuario_id}/historial", response_model=list)
def obtener_historial_alumno(
    usuario_id: int,
    token: dict = Depends(TokenManager.verify_token_from_header)
):
    try:
        rol = token.get("rol")
        if rol != "admin":
            raise HTTPException(status_code=403, detail="No tiene permisos")
        historial = UsuarioModel.obtener_historial_alumno(usuario_id)
        return historial
    except HTTPException:
        raise
    except Exception as e:
        import traceback
        print(traceback.format_exc())
        raise HTTPException(status_code=500, detail=str(e))