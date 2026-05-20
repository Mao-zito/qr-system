-- Script de Migración: Agregar soporte de usuario_id en tabla escaneos
-- EJECUTAR ESTE SCRIPT SI LA TABLA ESCANEOS NO TIENE LA COLUMNA usuario_id

-- ============================================================
-- PASO 1: Agregar columna usuario_id si no existe
-- ============================================================
ALTER TABLE escaneos
ADD COLUMN IF NOT EXISTS usuario_id INTEGER;

-- ============================================================
-- PASO 2: Agregar constraint de foreign key
-- ============================================================
ALTER TABLE escaneos
ADD CONSTRAINT IF NOT EXISTS fk_escaneos_usuario
FOREIGN KEY (usuario_id) REFERENCES cuentas(id);

-- ============================================================
-- PASO 3: Llenar usuario_id con datos existentes
-- ============================================================
-- Si hay escaneos sin usuario_id, asignamos el usuario del objeto
UPDATE escaneos
SET usuario_id = (
    SELECT o.usuario_id 
    FROM objetos o 
    WHERE o.id = escaneos.objeto_id
)
WHERE usuario_id IS NULL;

-- ============================================================
-- PASO 4: Hacer la columna usuario_id NOT NULL (opcional)
-- ============================================================
-- ALTER TABLE escaneos
-- ALTER COLUMN usuario_id SET NOT NULL;

-- ============================================================
-- Verificación: Listar campos de la tabla escaneos
-- ============================================================
-- SELECT column_name, data_type, is_nullable 
-- FROM information_schema.columns 
-- WHERE table_name = 'escaneos';
