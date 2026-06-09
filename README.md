# QR System

Sistema de registro y control de objetos con códigos QR. Desarrollado con Flutter (móvil), FastAPI (backend) desplegado en Railway y PostgreSQL en Neon.

## Arquitectura

```
ESP32 + GM65 (lector QR)
        ↓ POST /escaneos/{qr_code}
FastAPI (Railway) ←→ PostgreSQL (Neon)
        ↑
App Flutter (Android APK)
```

## Tecnologías

| Capa | Tecnología |
|------|-----------|
| Mobile | Flutter 3.32.5 |
| Backend | Python 3.13 + FastAPI |
| Base de datos | PostgreSQL (Neon) |
| Despliegue backend | Railway |
| Autenticación | JWT + bcrypt |
| ML | scikit-learn (KMeans + Isolation Forest) |
| Email | Resend API |

---

## Base de Datos

Ejecutar en Neon SQL Editor:

```sql
CREATE TABLE cuentas (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100),
    correo VARCHAR(100) UNIQUE NOT NULL,
    contrasena VARCHAR(255) NOT NULL,
    telefono VARCHAR(20),
    codigo_estudiante VARCHAR(50),
    rol VARCHAR(20) DEFAULT 'usuario',
    foto_perfil TEXT
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
    fecha_hora TIMESTAMP DEFAULT NOW(),
    tipo_evento VARCHAR(10) DEFAULT 'ENTRADA'
);

CREATE TABLE password_reset_codes (
    id SERIAL PRIMARY KEY,
    correo VARCHAR(255) NOT NULL,
    codigo VARCHAR(6) NOT NULL,
    expira_en TIMESTAMP NOT NULL,
    usado BOOLEAN DEFAULT FALSE,
    creado_en TIMESTAMP DEFAULT NOW()
);

CREATE TABLE ml_perfiles_alumnos (
    id SERIAL PRIMARY KEY,
    usuario_id INTEGER UNIQUE REFERENCES cuentas(id),
    perfil VARCHAR(20),
    total_escaneos INTEGER,
    dias_activo INTEGER,
    hora_promedio FLOAT,
    frecuencia_semanal FLOAT,
    actualizado_en TIMESTAMP DEFAULT NOW()
);

CREATE TABLE ml_anomalias_escaneos (
    id SERIAL PRIMARY KEY,
    escaneo_id INTEGER UNIQUE REFERENCES escaneos(id),
    usuario_id INTEGER REFERENCES cuentas(id),
    score FLOAT,
    motivo VARCHAR(100),
    detectado_en TIMESTAMP DEFAULT NOW()
);

INSERT INTO categorias (nombre) VALUES
('Laptop'), ('Tablet'), ('Celular'), ('Otro');
```

---

## Backend (Railway)

### Variables de entorno en Railway

```
DATABASE_URL     = postgresql://...neon.tech/neondb?sslmode=require
SECRET_KEY       = tu_clave_secreta
ALGORITHM        = HS256
ACCESS_TOKEN_EXPIRE_MINUTES = 1440
FRONTEND_URL     = *
RESEND_API_KEY   = re_xxxxxxxxxxxx
```

### Instalación local (desarrollo)

```bash
cd backend
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
```

Crear `.env` en `backend/`:

```
DATABASE_URL=postgresql://...neon.tech/neondb?sslmode=require
SECRET_KEY=tu_clave_secreta
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=1440
FRONTEND_URL=*
RESEND_API_KEY=re_xxxxxxxxxxxx
```

Correr servidor:

```bash
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

### Machine Learning

Generar datos de prueba (primera vez):

```bash
DATABASE_URL="tu_url" python generar_datos.py
```

Ejecutar modelos ML:

```bash
DATABASE_URL="tu_url" python ml_service.py
```

---

## Flutter

### Configuración

Editar `lib/constants/api_constants.dart`:

```dart
// Producción (Railway)
static const String baseUrl = 'https://tu-app.up.railway.app';

// Desarrollo local
// static const String baseUrl = 'http://TU_IP:8000';
```

### Correr en desarrollo

```bash
cd flutter_app
flutter pub get
flutter run

```
## Roles

| Rol | Acceso |
|-----|--------|
| `usuario` | Registrar objetos, ver QRs, ver historial propio, cambiar contraseña |
| `admin` | Todo lo anterior + ver todos los escaneos, ver alumnos, análisis ML |


## Endpoints

### Autenticación
| Método | Ruta | Descripción |
|--------|------|-------------|
| POST | `/auth/login` | Iniciar sesión |
| POST | `/auth/registro` | Registrar usuario |
| GET | `/auth/perfil` | Obtener perfil |
| PUT | `/auth/perfil` | Actualizar perfil |
| POST | `/auth/cambiar-contrasena` | Cambiar contraseña |
| POST | `/auth/solicitar-reset` | Solicitar código de reset |
| POST | `/auth/verificar-codigo` | Verificar código de reset |
| POST | `/auth/restablecer-contrasena` | Restablecer contraseña |

### Objetos
| Método | Ruta | Descripción |
|--------|------|-------------|
| GET | `/objetos/mis-objetos` | Objetos del usuario |
| POST | `/objetos/` | Crear objeto con QR |
| GET | `/objetos/{id}` | Detalle de objeto |

### Escaneos
| Método | Ruta | Descripción |
|--------|------|-------------|
| POST | `/escaneos/{qr_code}` | Registrar escaneo (ESP32) |
| GET | `/escaneos/mi-historial` | Historial del usuario |
| GET | `/escaneos/` | Todos los escaneos (admin) |

### Machine Learning
| Método | Ruta | Descripción |
|--------|------|-------------|
| GET | `/ml/perfiles` | Clasificación de alumnos (KMeans) |
| GET | `/ml/anomalias` | Escaneos sospechosos (Isolation Forest) |
| GET | `/ml/resumen` | Resumen general ML |

### Estadísticas
| Método | Ruta | Descripción |
|--------|------|-------------|
| GET | `/stats/` | Estadísticas generales |

---

## Hardware (ESP32 + GM65)

El ESP32 con lector QR GM65 escanea el código y hace un POST al backend:

```
POST https://tu-app.up.railway.app/escaneos/{qr_code}
Content-Type: application/json

{
  "ubicacion": "Entrada principal",
  "dispositivo": "ESP32"
}
```

El sistema alterna automáticamente entre ENTRADA y SALIDA según el último evento registrado.

---
