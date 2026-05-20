# QR System - Aplicación Flutter

Aplicación móvil Flutter para el Sistema de Gestión de Objetos con Código QR.

## Características

- 🔐 **Autenticación**: Sistema seguro de login y registro con JWT
- 📱 **Escaneo QR**: Captura y lectura de códigos QR en tiempo real
- 📊 **Gestión de Objetos**: Lista de objetos registrados en el sistema
- 📈 **Historial de Escaneos**: Registro de todos los escaneos realizados
- 🔄 **Sincronización**: Sincronización con el backend FastAPI

## Requisitos

- Flutter 3.0.0 o superior
- Dart 3.0.0 o superior
- Android SDK 21+ (para desarrollo Android)
- iOS 11.0+ (para desarrollo iOS)

## Instalación

1. Clona el proyecto o copia la carpeta `flutter_app`
2. Navega al directorio del proyecto:

```bash
cd flutter_app
```

3. Instala las dependencias:

```bash
flutter pub get
```

## Configuración

### Configurar la URL del Backend

Abre el archivo `lib/constants/api_constants.dart` y modifica la URL base si es necesario:

```dart
static const String baseUrl = 'http://TU_IP_DEL_SERVIDOR:8000';
```

- **Desde emulador Android**: usa `http://10.0.2.2:8000`
- **Desde dispositivo físico**: usa la IP de tu servidor `http://192.168.X.X:8000`
- **Desde iOS**: usa `http://localhost:8000` o la IP del servidor

## Ejecución

### En emulador/dispositivo conectado

```bash
flutter run
```

### Compilar APK (Android)

```bash
flutter build apk --release
```

### Compilar iOS

```bash
flutter build ios --release
```

## Estructura del Proyecto

```
flutter_app/
├── lib/
│   ├── main.dart              # Punto de entrada
│   ├── screens/               # Pantallas de la aplicación
│   │   ├── login_screen.dart
│   │   ├── home_screen.dart
│   │   └── qr_scan_screen.dart
│   ├── models/                # Modelos de datos
│   │   ├── user_model.dart
│   │   └── objeto_model.dart
│   ├── services/              # Servicios (API)
│   │   └── api_service.dart
│   └── constants/             # Constantes
│       └── api_constants.dart
├── pubspec.yaml               # Dependencias del proyecto
└── README.md
```

## Pantallas

### 1. Login
- Formulario de autenticación
- Opción para registrar nuevos usuarios
- Validación de campos

### 2. Pantalla Principal (Home)
- Lista de objetos registrados
- Información del usuario
- Acceso rápido al escaneo
- Menú para cerrar sesión

### 3. Escaneo QR
- Captura en tiempo real de la cámara
- Lectura automática de códigos QR
- Registro de ubicación y dispositivo del escaneo

## Dependencias Principales

- **http**: Para llamadas HTTP al backend
- **provider**: Gestión de estado (opcional)
- **mobile_scanner**: Escaneo de códigos QR
- **shared_preferences**: Almacenamiento local

## Endpoints de la API

- `POST /auth/login` - Autenticación
- `POST /auth/registro` - Registro de usuarios
- `GET /objetos/` - Obtener lista de objetos
- `GET /objetos/{id}` - Obtener objeto por ID
- `GET /objetos/qr/{qr_code}` - Buscar objeto por QR
- `POST /escaneos/{qr_code}` - Registrar escaneo
- `GET /escaneos/historial/{objeto_id}` - Historial de escaneos

## Solución de Problemas

### Error de conexión con el backend
- Verifica que el backend esté corriendo
- Comprueba la URL en `api_constants.dart`
- Para dispositivos físicos, usa la IP local del servidor

### Permisos de cámara
- La aplicación solicitará permisos automáticamente
- En Android: asegúrate de tener permisos en `AndroidManifest.xml`
- En iOS: agrega permisos en `Info.plist`

## Licencia

Proyecto de Micro - 2026
