# Script para ejecutar el proyecto completo (Backend + Flutter) en Windows
# Uso: .\run_project.ps1

Write-Host " QR System " -ForegroundColor Green

# Verificar que los directorios existen
if (-not (Test-Path "backend")) {
    Write-Host " Error: Carpeta 'backend' no encontrada" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path "flutter_app")) {
    Write-Host " Error: Carpeta 'flutter_app' no encontrada" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host " Iniciando Backend FastAPI..." -ForegroundColor Green

Push-Location backend

# Activar venv si existe
if (Test-Path "venv\Scripts\Activate.ps1") {
    & ".\venv\Scripts\Activate.ps1"
    Write-Host " Virtual environment activado" -ForegroundColor Green
}

# Verificar dependencias
try {
    python -c "import fastapi" 2>$null
} catch {
    Write-Host " Instalando dependencias del backend..." -ForegroundColor Yellow
    pip install -r requirements.txt
}

# Iniciar FastAPI en una nueva ventana
Write-Host " Backend ejecutándose en http://localhost:8000" -ForegroundColor Cyan
$backendProcess = Start-Process python -ArgumentList "main.py" -PassThru
Write-Host "Backend iniciado (PID: $($backendProcess.Id))" -ForegroundColor Green

# Esperar a que el backend esté listo
Write-Host " Esperando a que el backend esté listo..." -ForegroundColor Yellow
Start-Sleep -Seconds 3

Pop-Location

Write-Host ""
Write-Host " Iniciando Aplicación Flutter..." -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan

Push-Location flutter_app

# Verificar que Flutter está instalado
$flutterPath = where.exe flutter 2>$null
if (-not $flutterPath) {
    Write-Host " Error: Flutter no está instalado" -ForegroundColor Red
    Write-Host " Descarga Flutter desde: https://flutter.dev" -ForegroundColor Yellow
    $backendProcess | Stop-Process -Force
    Pop-Location
    exit 1
}

# Instalar dependencias
Write-Host " Instalando dependencias de Flutter..." -ForegroundColor Yellow
flutter pub get

# Ejecutar Flutter
Write-Host " Ejecutando Flutter..." -ForegroundColor Cyan
Write-Host ""

# Si se ejecuta correctamente, Flutter bloqueará la terminal
flutter run

Pop-Location

# Limpiar al salir
Write-Host ""
Write-Host " Deteniendo aplicación..." -ForegroundColor Yellow
$backendProcess | Stop-Process -Force -ErrorAction SilentlyContinue
Write-Host " Backend detenido" -ForegroundColor Green
Write-Host " Hasta luego!" -ForegroundColor Cyan
