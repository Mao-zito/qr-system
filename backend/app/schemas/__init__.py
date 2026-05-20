# __init__.py para schemas

from .schemas import (
    LoginRequest, LoginResponse, UsuarioCreate, UsuarioResponse,
    ObjetoCreate, ObjetoResponse, ObjetoDetalladoResponse,
    EscaneoCreate, EscaneoResponse, EscaneoHistorialResponse,
    CategoriaCreate, CategoriaResponse,
    EstadisticasResponse
)

__all__ = [
    "LoginRequest", "LoginResponse", "UsuarioCreate", "UsuarioResponse",
    "ObjetoCreate", "ObjetoResponse", "ObjetoDetalladoResponse",
    "EscaneoCreate", "EscaneoResponse", "EscaneoHistorialResponse",
    "CategoriaCreate", "CategoriaResponse",
    "EstadisticasResponse"
]
