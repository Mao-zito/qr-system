# Backend routes - Estadísticas

from fastapi import APIRouter, HTTPException
from app.schemas.schemas import EstadisticasResponse
from app.models.models import EstadisticasModel

router = APIRouter(prefix="/stats", tags=["estadisticas"])

@router.get("/", response_model=dict)
def obtener_estadisticas():
    """Obtiene estadísticas generales del sistema"""
    try:
        stats = EstadisticasModel.obtener_estadisticas()
        return stats
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
