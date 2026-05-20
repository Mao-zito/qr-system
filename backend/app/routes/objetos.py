from fastapi import APIRouter, HTTPException, Header
from app.schemas.schemas import ObjetoCreate
from app.models.models import ObjetoModel
from app.utils.auth import TokenManager
from app.utils.qr_manager import QRGenerator

router = APIRouter(prefix="/objetos", tags=["objetos"])

@router.get("/mis-objetos", response_model=list)
def obtener_mis_objetos(authorization: str = Header(None)):
    try:
        if not authorization:
            raise HTTPException(status_code=401, detail="Token no proporcionado")
        parts = authorization.split()
        if len(parts) != 2 or parts[0] != "Bearer":
            raise HTTPException(status_code=401, detail="Formato de token inválido")
        payload = TokenManager.verify_token(parts[1])
        usuario_id = int(payload.get("sub"))
        if not usuario_id:
            raise HTTPException(status_code=401, detail="Usuario no identificado")
        objetos = ObjetoModel.obtener_objetos_usuario(usuario_id)
        resultado = []
        for obj in objetos:
            resultado.append({
                "id": obj[0],
                "nombre": obj[1],
                "qr_code": obj[2],
                "descripcion": obj[3],
                "categoria": obj[4],
                "fecha_creacion": obj[5]
            })
        return resultado
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/qr/{qr_code}", response_model=dict)
def buscar_por_qr(qr_code: str):
    try:
        objeto = ObjetoModel.obtener_por_qr(qr_code)
        if not objeto:
            raise HTTPException(status_code=404, detail="Objeto no encontrado")
        return objeto
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/", response_model=list)
def obtener_objetos():
    try:
        objetos = ObjetoModel.obtener_todos()
        return objetos
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/", response_model=dict)
def crear_objeto(objeto_data: ObjetoCreate, authorization: str = Header(None)):
    try:
        if not authorization:
            raise HTTPException(status_code=401, detail="Token no proporcionado")
        parts = authorization.split()
        if len(parts) != 2 or parts[0] != "Bearer":
            raise HTTPException(status_code=401, detail="Formato de token inválido")
        payload = TokenManager.verify_token(parts[1])
        usuario_id = int(payload.get("sub"))
        if not usuario_id:
            raise HTTPException(status_code=401, detail="Usuario no identificado")
        objeto = ObjetoModel.crear_objeto(
            nombre=objeto_data.nombre,
            categoria_id=objeto_data.categoria_id,
            usuario_id=usuario_id,
            descripcion=objeto_data.descripcion
        )
        qr_image = QRGenerator.generate_qr_code(objeto["qr_code"])
        return {
            "mensaje": "Objeto creado exitosamente",
            "objeto": objeto,
            "qr_imagen": qr_image
        }
    except HTTPException:
        raise
    except Exception as e:
        import traceback
        print(traceback.format_exc())
        raise HTTPException(status_code=500, detail=str(e))
         

@router.get("/{objeto_id}", response_model=dict)
def obtener_objeto(objeto_id: int):
    try:
        objeto = ObjetoModel.obtener_por_id(objeto_id)
        if not objeto:
            raise HTTPException(status_code=404, detail="Objeto no encontrado")
        return objeto
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))