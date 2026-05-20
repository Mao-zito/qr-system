# Guía de Instalación Completa

## 🔧 Requisitos del Sistema

- **SO**: Windows 10+, Linux, MacOS
- **Python**: 3.8 o superior
- **PostgreSQL**: 13 o superior
- **Node.js**: 14+ (opcional, para frontend)
- **Navegador**: Chrome, Firefox, Edge (compatible con ES6)
- **Git**: Para clonar repositorios

## 📋 Paso 1: Instalación de PostgreSQL

### Windows
1. Descargar desde [postgresql.org](https://www.postgresql.org/download/windows/)
2. Ejecutar el instalador
3. Anotar la contraseña de `postgres`
4. Puerto por defecto: 5432
5. Seleccionar pgAdmin en la instalación

### Linux (Ubuntu/Debian)
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib pgadmin4
sudo systemctl start postgresql
```

### MacOS
```bash
brew install postgresql
brew services start postgresql
```

## 🗄️ Paso 2: Crear Base de Datos

### Método 1: Usar pgAdmin
1. Abrir pgAdmin 4 (http://localhost:5050)
2. Login con credenciales de instalación
3. Click derecho en "Servers" → "Register" → "Server"
4. Nombre: "QR System", Host: "localhost"
5. Create Database → Nombre: "qr_system"

### Método 2: Usar psql
```bash
# Conectar a PostgreSQL
psql -U postgres

# En la terminal de PostgreSQL:
CREATE DATABASE qr_system;
\c qr_system

# Crear tablas (ver script SQL completo abajo)
```

### Script SQL Completo
```sql
-- Crear tablas
CREATE TABLE usuarios (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE
);

CREATE TABLE categorias (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT
);

CREATE TABLE objetos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    qr_code VARCHAR(50) UNIQUE NOT NULL,
    categoria_id INTEGER NOT NULL REFERENCES categorias(id),
    usuario_id INTEGER NOT NULL REFERENCES usuarios(id),
    descripcion TEXT,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE escaneos (
    id SERIAL PRIMARY KEY,
    objeto_id INTEGER NOT NULL REFERENCES objetos(id),
    ubicacion VARCHAR(100),
    dispositivo VARCHAR(50) DEFAULT 'WEB',
    fecha_hora TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE cuentas (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    correo VARCHAR(100) UNIQUE NOT NULL,
    contraseña VARCHAR(255) NOT NULL,
    rol VARCHAR(20) DEFAULT 'user',
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Crear índices
CREATE INDEX idx_objetos_qr ON objetos(qr_code);
CREATE INDEX idx_objetos_categoria ON objetos(categoria_id);
CREATE INDEX idx_escaneos_objeto ON escaneos(objeto_id);
CREATE INDEX idx_escaneos_fecha ON escaneos(fecha_hora);
CREATE INDEX idx_cuentas_correo ON cuentas(correo);

-- Insertar datos de ejemplo
INSERT INTO categorias (nombre, descripcion) VALUES
    ('Electrónica', 'Dispositivos electrónicos'),
    ('Herramientas', 'Herramientas de trabajo'),
    ('Inventario', 'Artículos de inventario');

INSERT INTO usuarios (nombre, email) VALUES
    ('Admin', 'admin@example.com'),
    ('Usuario', 'usuario@example.com');
```

## 🐍 Paso 3: Configurar Backend Python

### 3.1 Crear Entorno Virtual

```bash
# Navegar a la carpeta backend
cd "d:\Documentos\proyecto Micro\backend"

# Crear entorno virtual
python -m venv venv

# Activar entorno (Windows)
venv\Scripts\activate

# Activar entorno (Linux/Mac)
source venv/bin/activate
```

### 3.2 Instalar Dependencias

```bash
# Asegurarse de estar en la carpeta backend con venv activado
pip install -r requirements.txt

# Verificar instalación
pip list
```

### 3.3 Configurar Variables de Entorno

Editar o crear `backend/.env`:

```env
# DATABASE
DB_HOST=localhost
DB_PORT=5432
DB_NAME=qr_system
DB_USER=postgres
DB_PASSWORD=Tu_Contraseña_De_Postgres

# SECURITY
SECRET_KEY=tu-clave-secreta-super-segura-cambiar-en-produccion-es-muy-importante
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# API
API_HOST=127.0.0.1
API_PORT=8000
DEBUG=True

# FRONTEND
FRONTEND_URL=http://127.0.0.1:3000
```

⚠️ **IMPORTANTE**: Cambiar:
- `DB_PASSWORD` con tu contraseña de PostgreSQL
- `SECRET_KEY` con una cadena aleatoria fuerte

### 3.4 Pruebas Iniciales

```bash
# Verificar conexión a BD
python -c "from app.database import Database; Database.connect(); print('✓ Conectado a BD')"

# Verificar instalación de bcrypt
python -c "import bcrypt; print('✓ bcrypt instalado')"

# Verificar JWT
python -c "import jwt; print('✓ JWT instalado')"
```

## 🌐 Paso 4: Ejecutar el Backend

```bash
# Asegurarse de estar en backend/
cd "d:\Documentos\proyecto Micro\backend"

# Activar venv si no está activado
venv\Scripts\activate  # Windows

# Ejecutar servidor
python main.py

# Deberías ver:
# INFO:     Uvicorn running on http://127.0.0.1:8000
# INFO:     Application startup complete
```

**Verificar que la API funciona:**
- Abrir navegador: `http://127.0.0.1:8000`
- Documentación interactiva: `http://127.0.0.1:8000/docs`

## 🎨 Paso 5: Servir el Frontend

### Opción A: Live Server (VS Code) - ⭐ Recomendado

1. Instalar extensión "Live Server" de Ritwick Dey
2. Click derecho en `frontend/login.html`
3. Seleccionar "Open with Live Server"
4. Se abrirá en `http://127.0.0.1:5500`

### Opción B: Python

```bash
# En la carpeta frontend
cd "d:\Documentos\proyecto Micro\frontend"

# Python 3.x
python -m http.server 3000

# Acceder a: http://127.0.0.1:3000
```

### Opción C: Node.js http-server

```bash
# Instalar globalmente (una sola vez)
npm install -g http-server

# En la carpeta frontend
cd "d:\Documentos\proyecto Micro\frontend"
http-server -p 3000

# Acceder a: http://127.0.0.1:3000
```

### Opción D: VS Code Extension "Web Server for Chrome"

1. Instalar extensión
2. Click derecho en carpeta `frontend`
3. "Open with Web Server"

## ✅ Paso 6: Pruebas Iniciales

### Test de Login

1. Ir a `http://127.0.0.1:5500/registro.html` (o tu puerto)
2. Registrar usuario:
   - Nombre: Test
   - Correo: test@example.com
   - Contraseña: 123456
3. Click "Crear Cuenta"
4. Ir a `http://127.0.0.1:5500/login.html`
5. Ingresar credenciales
6. Debería redirigir a dashboard

### Test de Objetos

1. En dashboard, click "Registrar Objeto"
2. Llenar formulario:
   - Nombre: Objeto Test
   - Categoría: Electrónica
   - Descripción: Test
3. Click "Guardar Objeto"
4. Debería aparecer en la lista

### Test de API con curl

```bash
# Test endpoint principal
curl http://127.0.0.1:8000/

# Test login
curl -X POST http://127.0.0.1:8000/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"correo\": \"test@example.com\", \"contraseña\": \"123456\"}"

# Test obtener objetos
curl http://127.0.0.1:8000/objetos/

# Test estadísticas
curl http://127.0.0.1:8000/stats/
```

## 🎯 Verificación de Checklist

- ✅ PostgreSQL instalado y corriendo
- ✅ Base de datos `qr_system` creada
- ✅ Tablas creadas
- ✅ Python 3.8+ instalado
- ✅ Entorno virtual creado y activado
- ✅ Dependencias instaladas (requirements.txt)
- ✅ Variables de entorno (.env) configuradas
- ✅ Backend corriendo en puerto 8000
- ✅ Frontend servido en puerto 3000 o 5500
- ✅ Navegador accede sin errores

## 🚀 Comandos Rápidos

```bash
# Terminal 1: Backend
cd backend
venv\Scripts\activate
python main.py

# Terminal 2: Frontend (Python)
cd frontend
python -m http.server 3000

# Acceder en navegador:
# Frontend: http://127.0.0.1:3000 (o 5500 si usas Live Server)
# API Docs: http://127.0.0.1:8000/docs
# pgAdmin: http://127.0.0.1:5050
```

## 🔧 Solución de Problemas Comunes

### "Connection refused" a PostgreSQL
```
- Verificar que PostgreSQL está corriendo: services.msc (Windows)
- Verificar puerto 5432 no está bloqueado
- Verificar credenciales en .env
```

### "ModuleNotFoundError: No module named..."
```
- Activar entorno virtual: venv\Scripts\activate
- Reinstalar: pip install -r requirements.txt
```

### CORS errors en consola
```
- Verificar FRONTEND_URL en .env
- Verificar allow_origins en main.py
- Usar mismos puertos configurados
```

### "Objeto no encontrado" al crear QR
```
- Verificar categoría existe en BD
- Verificar usuario_id es válido
- Revisar logs del backend
```

### QR no se muestra
```
- Verificar qrcode[pil] está instalado: pip install qrcode[pil]
- Verificar que el código QR se generó
- Usar herramienta online para validar QR
```

## 📚 Archivos Importantes

| Archivo | Propósito |
|---------|-----------|
| `.env` | Variables de entorno y secretos |
| `main.py` | Aplicación FastAPI principal |
| `app/models.py` | Modelos de datos |
| `app/routes/` | Rutas API |
| `app/utils/auth.py` | Bcrypt y JWT |
| `frontend/index.html` | Dashboard principal |
| `frontend/static/js/config.js` | Cliente API |

## 🎓 Siguientes Pasos

1. **Generar datos de prueba** - Crear varios objetos y escaneos
2. **Explorar la API** - Ir a `http://127.0.0.1:8000/docs`
3. **Configurar ESP32** - Ver `ESP32_INTEGRACION.md`
4. **Personalizar** - Agregar tus campos y rutas
5. **Desplegar** - Usar Heroku, DigitalOcean, AWS, etc.

## 📞 Ayuda

Si encuentras problemas:
1. Revisar logs en terminal
2. Consultar pgAdmin para verificar BD
3. Abrir consola del navegador (F12) para errores
4. Probar endpoints con Postman o Insomnia

---

**¡Felicidades! Tu sistema QR está listo para usar 🎉**
