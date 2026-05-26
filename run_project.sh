#!/bin/bash
# Script para ejecutar el proyecto completo (Backend + Flutter)
# Uso: bash run_project.sh

echo " QR System "

# Verificar que los directorios existen
if [ ! -d "backend" ]; then
    echo " Error: Carpeta 'backend' no encontrada"
    exit 1
fi

if [ ! -d "flutter_app" ]; then
    echo " Error: Carpeta 'flutter_app' no encontrada"
    exit 1
fi

echo ""
echo "Iniciando Backend FastAPI..."
echo "==========================================="
cd backend

# Activar venv si existe
if [ -d "venv" ]; then
    source venv/bin/activate
    echo " Virtual environment activado"
fi

# Instalar dependencias si es necesario
if ! python -c "import fastapi" 2>/dev/null; then
    echo " Instalando dependencias del backend..."
    pip install -r requirements.txt
fi

# Iniciar FastAPI
echo " Backend ejecutándose en http://localhost:8000"
python main.py &
BACKEND_PID=$!
echo " Backend iniciado (PID: $BACKEND_PID)"

# Esperar a que el backend esté listo
echo " Esperando a que el backend esté listo..."
sleep 3

echo ""
echo " Iniciando Aplicación Flutter..."
echo "==========================================="
cd ../flutter_app

# Verificar que Flutter está instalado
if ! command -v flutter &> /dev/null; then
    echo " Error: Flutter no está instalado"
    echo " Descarga Flutter desde: https://flutter.dev"
    kill $BACKEND_PID
    exit 1
fi

# Instalar dependencias
echo " Instalando dependencias de Flutter..."
flutter pub get

# Ejecutar Flutter
echo " Flutter ejecutándose..."
flutter run

# Limpiar al salir
echo ""
echo " Deteniendo aplicación..."
kill $BACKEND_PID
echo " Backend detenido"
echo " Hasta luego!"
