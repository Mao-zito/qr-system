# QR System 

Sistema de registro y control de objetos con códigos QR. Desarrollado con Flutter (móvil) y FastAPI + PostgreSQL (backend).

##  Requisitos

- Python 3.13.0
- Flutter 3.32.5
- PostgreSQL 14+

## 🗄️ Base de Datos

1. Instala PostgreSQL y crea la base de datos:

```sql
CREATE DATABASE qr_system;
```

2. Crea las tablas:

```sql
CREATE TABLE cuentas (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    correo VARCHAR(100) UNIQUE NOT NULL,
    contrasena VARCHAR(255) NOT NULL,
    rol VARCHAR(20) DEFAULT 'usuario'
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
    descripcion TEXT,
    categoria_id INTEGER REFERENCES categorias(id),
    usuario_id INTEGER REFERENCES cuentas(id),
    fecha_creacion TIMESTAMP DEFAULT NOW()
);

CREATE TABLE escaneos (
    id SERIAL PRIMARY KEY,
    objeto_id INTEGER REFERENCES objetos(id),
    usuario_id INTEGER REFERENCES cuentas(id),
    ubicacion VARCHAR(100),
    dispositivo VARCHAR(50),
    fecha_hora TIMESTAMP DEFAULT NOW()
);
```

##  Backend (FastAPI)

1. Entra a la carpeta backend:

```bash
cd backend
```

2. Crea y activa el entorno virtual:

```bash
python -m venv venv
venv\Scripts\activate
```

3. Instala dependencias:

```bash
pip install -r requirements.txt
```

4. Crea el archivo `.env` dentro de `backend/`:

```
DB_HOST=localhost
DB_PORT=5432
DB_NAME=qr_system
DB_USER=postgres
DB_PASSWORD=TU_PASSWORD

SECRET_KEY=tu_clave_secreta_aqui
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=1440

API_HOST=0.0.0.0
API_PORT=8000

FRONTEND_URL=http://localhost:3000
```

5. Corre el servidor:

```bash
py -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

Backend disponible en `http://localhost:8000`
Documentación en `http://localhost:8000/docs`

##  Flutter

1. Entra a la carpeta flutter_app:

```bash
cd flutter_app
```

2. Instala dependencias:

```bash
flutter pub get
```

3. Configura la IP en `lib/constants/api_constants.dart`:

```dart
static const String baseUrl = 'http://TU_IP:8000';
```

> Reemplaza `TU_IP` con la IP de tu PC. Ejecuta `ipconfig` en Windows para verla. El celular y la PC deben estar en la misma red WiFi.

4. Conecta el celular por USB con depuración USB activada y corre:

```bash
flutter run
```

##  Roles

| Rol | Acceso |
|-----|--------|
| `usuario` | Registrar objetos, ver QRs, ver historial propio |
| `admin` | Ver todos los escaneos, filtrar por fecha y alumno |

##  Crear usuario admin

```sql
UPDATE cuentas SET rol = 'admin' WHERE correo = 'tu_correo@ejemplo.com';
```

##  Endpoints

| Método | Ruta | Descripción |
|--------|------|-------------|
| POST | `/auth/login` | Iniciar sesión |
| POST | `/auth/registro` | Registrar usuario |
| GET | `/objetos/mis-objetos` | Objetos del usuario |
| POST | `/objetos/` | Crear objeto con QR |
| GET | `/escaneos/mi-historial` | Historial del usuario |
| GET | `/escaneos/` | Todos los escaneos (admin) |
| POST | `/escaneos/{qr_code}` | Registrar escaneo (ESP32) |

