from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routes import auth_router, objetos_router, escaneos_router, estadisticas_router, perfil_router
from app.config import settings
from app.database import Database

app = FastAPI(
    title="QR System API",
    description="API para Sistema de Registro y Control de Objetos con QR",
    version="2.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[settings.FRONTEND_URL, "http://localhost:3000", "http://127.0.0.1:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router)
app.include_router(objetos_router)
app.include_router(escaneos_router)
app.include_router(estadisticas_router)
app.include_router(perfil_router)


@app.get("/")
def inicio():
    return {
        "mensaje": "API QR System funcionando correctamente",
        "versión": "2.0.0",
        "endpoints": {
            "autenticación": "/auth/login",
            "objetos": "/objetos",
            "escaneos": "/escaneos",
            "estadísticas": "/stats",
            "documentación": "/docs"
        }
    }


@app.on_event("startup")
def startup():
    print("Iniciando pool de conexiones...")
    Database.init()
    print("Pool de conexiones iniciado")


@app.on_event("shutdown")
def shutdown():
    print("Cerrando pool de conexiones...")
    if Database._pool:
        Database._pool.closeall()
    print("Pool cerrado")


if __name__ == "__main__":
    import uvicorn
    import os

    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=int(os.getenv("PORT", 8000)),
    )