import traceback
from fastapi import APIRouter, HTTPException, Depends, Query
from app.utils.auth import TokenManager
from app.models.ml_model import MLModel

router = APIRouter(prefix="/ml", tags=["machine learning"])


def _solo_admin(token: dict = Depends(TokenManager.verify_token_from_header)):
    if token.get("rol") != "admin":
        raise HTTPException(status_code=403, detail="Solo administradores")
    return token


@router.get("/perfiles", response_model=list)
def obtener_perfiles(token: dict = Depends(_solo_admin)):
    """Clasificación de alumnos por comportamiento (KMeans)"""
    try:
        return MLModel.obtener_perfiles()
    except Exception as e:
        print(traceback.format_exc())
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/anomalias", response_model=list)
def obtener_anomalias(
    limite: int = Query(100, le=500),
    token: dict = Depends(_solo_admin),
):
    """Escaneos sospechosos detectados (Isolation Forest)"""
    try:
        return MLModel.obtener_anomalias(limite)
    except Exception as e:
        print(traceback.format_exc())
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/resumen", response_model=dict)
def obtener_resumen(token: dict = Depends(_solo_admin)):
    """Resumen general de los resultados ML"""
    try:
        return MLModel.obtener_resumen()
    except Exception as e:
        print(traceback.format_exc())
        raise HTTPException(status_code=500, detail=str(e))