# Esquemas Pydantic para validación de datos

from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import datetime

# ============ LOGIN ============
class LoginRequest(BaseModel):
    correo: EmailStr
    contrasena: str = Field(..., min_length=6)

class LoginResponse(BaseModel):
    mensaje: str
    nombre: str
    rol: str
    token: str

# ============ USUARIOS ============
class UsuarioCreate(BaseModel):
    nombre: str = Field(..., min_length=2)
    apellido: str = Field(..., min_length=2)
    correo: EmailStr
    contrasena: str = Field(..., min_length=6)
    telefono: str = Field(..., min_length=7)
    codigo_estudiante: str = Field(..., min_length=3)
    rol: str = Field(default="usuario")

class UsuarioResponse(BaseModel):
    id: int
    nombre: str
    correo: str
    rol: str

# ============ OBJETOS ============
class ObjetoCreate(BaseModel):
    nombre: str = Field(..., min_length=2)
    categoria_id: Optional[int] = None
    descripcion: Optional[str] = None

class ObjetoResponse(BaseModel):
    id: int
    nombre: str
    qr_code: str
    categoria: Optional[str]
    dueño: Optional[str]
    descripcion: Optional[str]

class ObjetoDetalladoResponse(BaseModel):
    id: int
    nombre: str
    qr_code: str
    categoria: Optional[str]
    dueño: Optional[str]
    descripcion: Optional[str]
    fecha_creacion: datetime

# ============ ESCANEOS ============
class EscaneoCreate(BaseModel):
    ubicacion: Optional[str] = None
    dispositivo: str = Field(default="ESP32")

class EscaneoResponse(BaseModel):
    objeto: str
    ubicacion: Optional[str]
    dispositivo: str
    fecha: datetime

class EscaneoHistorialResponse(BaseModel):
    id: int
    objeto: str
    ubicacion: Optional[str]
    dispositivo: str
    fecha_hora: datetime

# ============ CATEGORÍAS ============
class CategoriaCreate(BaseModel):
    nombre: str = Field(..., min_length=2)
    descripcion: Optional[str] = None

class CategoriaResponse(BaseModel):
    id: int
    nombre: str
    descripcion: Optional[str]

# ============ ESTADÍSTICAS ============
class EstadisticasResponse(BaseModel):
    total_objetos: int
    total_escaneos: int
    total_categorias: int
    objetos_por_categoria: dict
    escaneos_por_dispositivo: dict
    escaneos_ultimo_dia: int
    escaneos_ultima_semana: int

# ============ PERFIL ============
class PerfilResponse(BaseModel):
    id: int
    nombre: str
    apellido: Optional[str]
    correo: str
    telefono: Optional[str]
    codigo_estudiante: Optional[str]
    rol: str
    foto_perfil: Optional[str]

class PerfilUpdate(BaseModel):
    nombre: Optional[str] = None
    apellido: Optional[str] = None
    telefono: Optional[str] = None
    foto_perfil: Optional[str] = None

class CambiarContrasena(BaseModel):
    contrasena_actual: str
    contrasena_nueva: str = Field(..., min_length=6)