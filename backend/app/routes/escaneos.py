from fastapi import APIRouter, HTTPException, Query, Depends
import traceback
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
                "id": h["id"],
                "objeto_id": h["objeto_id"],
                "objeto": h["objeto"],
                "qr_code": h["qr_code"],
                "ubicacion": h["ubicacion"],
                "dispositivo": h["dispositivo"],
                "fecha_hora": h["fecha_hora"]
            })
        return resultado
    except HTTPException:
        raise
    except Exception as e:
        print(traceback.format_exc())
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/historial/{objeto_id}", response_model=list)
def obtener_historial_objeto(objeto_id: int, limite: int = Query(50, le=100)):
    try:
        historial = EscaneoModel.obtener_historial_objeto(objeto_id, limite)
        return historial
    except Exception as e:
        print(traceback.format_exc())
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/", response_model=list)
def obtener_historial_general(
    token: str = Depends(TokenManager.verify_token_from_header),
    limite: int = Query(100, le=500)
):
    try:
        rol = token.get("rol")
        if rol != "admin":
            raise HTTPException(status_code=403, detail="No tiene permisos para esta acción")
        historial = EscaneoModel.obtener_historial(limite)
        return historial
    except HTTPException:
        raise
    except Exception as e:
        print(traceback.format_exc())
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/{qr_code}", response_model=dict)
def registrar_escaneo(qr_code: str, escaneo_data: EscaneoCreate):
    try:
        objeto = ObjetoModel.obtener_por_qr(qr_code)
        if not objeto:
            raise HTTPException(status_code=404, detail="Objeto no encontrado")

        objeto_id = objeto["id"]                    # ✅
        usuario_id = objeto.get("usuario_id")       # ✅ usa .get() por seguridad

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
            "objeto": objeto["nombre"],             # ✅ ajusta si el campo tiene otro nombre
            "qr_code": qr_code,
            "escaneo_id": escaneo["id"]
        }
    except HTTPException:
        raise
    except Exception as e:
        print(traceback.format_exc())
        raise HTTPException(status_code=500, detail=str(e))