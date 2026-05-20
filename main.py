from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import psycopg2

app = FastAPI()

# PERMITIR CONEXIONES DESDE EL FRONTEND
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# CONEXION A POSTGRESQL
conexion = psycopg2.connect(
    host="localhost",
    database="qr_system",
    user="postgres",
    password="Kirito2018"
)

# MODELOS
class LoginData(BaseModel):
    correo: str
    contrasena: str  # sin ñ, igual que Flutter

class RegistroData(BaseModel):
    nombre: str
    correo: str
    contrasena: str
    rol: str

class EscaneoData(BaseModel):
    ubicacion: str | None = None
    dispositivo: str

class ObjetoData(BaseModel):
    nombre: str
    descripcion: str | None = None
    categoria_id: int | None = None

# ─────────────────────────────────────────
# RUTA PRINCIPAL
# ─────────────────────────────────────────
@app.get("/")
def inicio():
    return {"mensaje": "API funcionando"}

# ─────────────────────────────────────────
# AUTH
# ─────────────────────────────────────────
@app.post("/auth/login")
def login(datos: LoginData):
    cursor = conexion.cursor()
    cursor.execute("""
        SELECT nombre, rol
        FROM cuentas
        WHERE correo = %s
        AND contrasena = %s
    """, (datos.correo, datos.contrasena))
    usuario = cursor.fetchone()
    cursor.close()

    if usuario:
        return {
            "token": f"token-{datos.correo}",  # reemplaza con JWT real si tienes
            "nombre": usuario[0],
            "rol": usuario[1]
        }
    raise HTTPException(status_code=401, detail="Correo o contraseña incorrectos")

@app.post("/auth/registro")
def registro(datos: RegistroData):
    cursor = conexion.cursor()
    try:
        cursor.execute("""
            INSERT INTO cuentas (nombre, correo, contrasena, rol)
            VALUES (%s, %s, %s, %s)
        """, (datos.nombre, datos.correo, datos.contrasena, datos.rol))
        conexion.commit()
        cursor.close()
        return {"mensaje": "Usuario registrado correctamente"}
    except Exception as e:
        conexion.rollback()
        cursor.close()
        raise HTTPException(status_code=400, detail=f"Error al registrar: {str(e)}")

# ─────────────────────────────────────────
# OBJETOS
# ─────────────────────────────────────────
@app.get("/objetos/")
def obtener_objetos():
    cursor = conexion.cursor()
    cursor.execute("""
        SELECT id, nombre, descripcion, categoria_id
        FROM objetos
    """)
    datos = cursor.fetchall()
    cursor.close()

    lista = []
    for fila in datos:
        lista.append({
            "id": fila[0],
            "nombre": fila[1],
            "descripcion": fila[2],
            "categoria_id": fila[3]
        })
    return lista

@app.get("/objetos/mis-objetos")
def mis_objetos():
    # Si tienes auth con JWT real, aquí filtrarías por usuario
    # Por ahora devuelve todos
    cursor = conexion.cursor()
    cursor.execute("""
        SELECT id, nombre, descripcion, categoria_id
        FROM objetos
    """)
    datos = cursor.fetchall()
    cursor.close()

    lista = []
    for fila in datos:
        lista.append({
            "id": fila[0],
            "nombre": fila[1],
            "descripcion": fila[2],
            "categoria_id": fila[3]
        })
    return lista

@app.post("/objetos/")
def registrar_objeto(datos: ObjetoData):
    cursor = conexion.cursor()
    try:
        cursor.execute("""
            INSERT INTO objetos (nombre, descripcion, categoria_id)
            VALUES (%s, %s, %s)
            RETURNING id
        """, (datos.nombre, datos.descripcion, datos.categoria_id))
        nuevo_id = cursor.fetchone()[0]
        conexion.commit()
        cursor.close()
        return {"id": nuevo_id, "nombre": datos.nombre}
    except Exception as e:
        conexion.rollback()
        cursor.close()
        raise HTTPException(status_code=400, detail=f"Error al registrar objeto: {str(e)}")

@app.get("/objetos/{objeto_id}")
def obtener_objeto(objeto_id: int):
    cursor = conexion.cursor()
    cursor.execute("""
        SELECT id, nombre, descripcion, categoria_id
        FROM objetos
        WHERE id = %s
    """, (objeto_id,))
    dato = cursor.fetchone()
    cursor.close()

    if dato:
        return {
            "id": dato[0],
            "nombre": dato[1],
            "descripcion": dato[2],
            "categoria_id": dato[3]
        }
    raise HTTPException(status_code=404, detail="Objeto no encontrado")

@app.get("/objetos/qr/{qr_code}")
def buscar_por_qr(qr_code: str):
    cursor = conexion.cursor()
    cursor.execute("""
        SELECT objetos.id,
               objetos.nombre,
               objetos.descripcion,
               categorias.nombre,
               usuarios.nombre
        FROM objetos
        JOIN categorias ON objetos.categoria_id = categorias.id
        JOIN usuarios ON objetos.usuario_id = usuarios.id
        WHERE objetos.qr_code = %s
    """, (qr_code,))
    dato = cursor.fetchone()
    cursor.close()

    if dato:
        return {
            "id": dato[0],
            "nombre": dato[1],
            "descripcion": dato[2],
            "categoria": dato[3],
            "dueño": dato[4]
        }
    raise HTTPException(status_code=404, detail="Objeto QR no encontrado")

# ─────────────────────────────────────────
# ESCANEOS
# ─────────────────────────────────────────
@app.post("/escaneos/{qr_code}")
def registrar_escaneo(qr_code: str, datos: EscaneoData):
    cursor = conexion.cursor()
    cursor.execute("""
        SELECT id, nombre FROM objetos WHERE qr_code = %s
    """, (qr_code,))
    objeto = cursor.fetchone()

    if objeto is None:
        cursor.close()
        raise HTTPException(status_code=404, detail="Objeto no encontrado")

    objeto_id = objeto[0]
    nombre_objeto = objeto[1]

    cursor.execute("""
        INSERT INTO escaneos (objeto_id, ubicacion, dispositivo)
        VALUES (%s, %s, %s)
    """, (objeto_id, datos.ubicacion, datos.dispositivo))
    conexion.commit()
    cursor.close()

    return {"mensaje": "Escaneo registrado", "objeto": nombre_objeto}

@app.get("/escaneos/mi-historial")
def mi_historial(limite: int = 100):
    cursor = conexion.cursor()
    cursor.execute("""
        SELECT objetos.nombre,
               escaneos.ubicacion,
               escaneos.fecha_hora
        FROM escaneos
        JOIN objetos ON escaneos.objeto_id = objetos.id
        ORDER BY escaneos.fecha_hora DESC
        LIMIT %s
    """, (limite,))
    datos = cursor.fetchall()
    cursor.close()

    historial = []
    for fila in datos:
        historial.append({
            "objeto": fila[0],
            "ubicacion": fila[1],
            "fecha": str(fila[2])
        })
    return historial

@app.get("/escaneos/historial/{objeto_id}")
def historial_por_objeto(objeto_id: int):
    cursor = conexion.cursor()
    cursor.execute("""
        SELECT objetos.nombre,
               escaneos.ubicacion,
               escaneos.fecha_hora
        FROM escaneos
        JOIN objetos ON escaneos.objeto_id = objetos.id
        WHERE escaneos.objeto_id = %s
        ORDER BY escaneos.fecha_hora DESC
    """, (objeto_id,))
    datos = cursor.fetchall()
    cursor.close()

    historial = []
    for fila in datos:
        historial.append({
            "objeto": fila[0],
            "ubicacion": fila[1],
            "fecha": str(fila[2])
        })
    return historial