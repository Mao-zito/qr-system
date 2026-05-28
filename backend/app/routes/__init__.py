# __init__.py para routes

from .auth import router as auth_router
from .objetos import router as objetos_router
from .escaneos import router as escaneos_router
from .estadisticas import router as estadisticas_router
from .perfil import router as perfil_router

__all__ = ["auth_router", "objetos_router", "escaneos_router", "estadisticas_router"]
