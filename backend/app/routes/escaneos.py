from fastapi import APIRouter, HTTPException, Query, Depends
from app.schemas.schemas import EscaneoCreate
from app.models.models import EscaneoModel, ObjetoModel
from app.utils.auth import TokenManager

router = APIRouter(prefix="/escaneos", tags=["escaneos"])

@router.get("/mi-historial", response_model=list)
def obtener_mi_historial(
    token: str = Depends(TokenManager.verify_token_from_header),
    limite: int = Query(100, le=500)
):
    try:
        usuario_id = int(token.get("sub"))
        if not usuario_id:
            raise HTTPException(status_code=401, detail="Usuario no identificado")
        historial = EscaneoModel.obtener_historial_usuario(usuario_id, limite)
        resultado = []
        for h in historial:
            resultado.append({
                "id": h[0],
                "objeto_id": h[1],
                "objeto": h[2],
                "qr_code": h[3],
                "ubicacion": h[4],
                "dispositivo": h[5],
                "fecha_hora": h[6]
            })
        return resultado
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/historial/{objeto_id}", response_model=list)
def obtener_historial_objeto(objeto_id: int, limite: int = Query(50, le=100)):
    try:
        historial = EscaneoModel.obtener_historial_objeto(objeto_id, limite)
        return historial
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/", response_model=list)
def obtener_historial_general(
    token: str = Depends(TokenManager.verify_token_from_header),
    limite: int = Query(100, le=500)
):
    try:
        print(f"TOKEN PAYLOAD: {token}")
        print(f"ROL: {token.get('rol')}")
        rol = token.get("rol")
        if rol != "admin":
            raise HTTPException(status_code=403, detail="No tiene permisos para esta acción")
        historial = EscaneoModel.obtener_historial(limite)
        return historial
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/{qr_code}", response_model=dict)
def registrar_escaneo(qr_code: str, escaneo_data: EscaneoCreate):
    try:
        objeto = ObjetoModel.obtener_por_qr(qr_code)
        if not objeto:
            raise HTTPException(status_code=404, detail="Objeto no encontrado")
        objeto_id = objeto[0]
        usuario_id = objeto[6] if len(objeto) > 6 else None
        if usuario_id is None:
            raise HTTPException(status_code=500, detail="Usuario del objeto no identificado")
        escaneo = EscaneoModel.registrar_escaneo(
            objeto_id=objeto_id,
            ubicacion=escaneo_data.ubicacion,
            dispositivo=escaneo_data.dispositivo or "ESP32",
            usuario_id=usuario_id
        )
        return {
            "mensaje": "Escaneo registrado exitosamente",
            "objeto": objeto[1],
            "qr_code": qr_code,
            "escaneo_id": escaneo["id"]
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))