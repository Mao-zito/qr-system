from fastapi import APIRouter, HTTPException
import traceback
from app.models.models import EstadisticasModel  # EstadisticasResponse no se usa, se puede quitar

router = APIRouter(prefix="/stats", tags=["estadisticas"])

@router.get("/", response_model=dict)
def obtener_estadisticas():
    try:
        stats = EstadisticasModel.obtener_estadisticas()
        return stats
    except Exception as e:
        print(traceback.format_exc())
        raise HTTPException(status_code=500, detail=str(e))