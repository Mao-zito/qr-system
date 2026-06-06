"""
ML Service — Detección de anomalías + Clustering de alumnos
Uso:
  python ml_service.py
  
Genera dos resultados:
  1. Clustering: clasifica alumnos en Normal / Irregular / Ausente
  2. Anomalías:  detecta escaneos en horarios sospechosos
  
Guarda resultados en tablas:
  - ml_perfiles_alumnos
  - ml_anomalias_escaneos
"""

import os
import traceback

import numpy as np
import pandas as pd
import psycopg2
from psycopg2.extras import RealDictCursor
from sklearn.cluster import KMeans
from sklearn.ensemble import IsolationForest
from sklearn.preprocessing import StandardScaler

# ─── CONEXIÓN ─────────────────────────────────────────────────────────────────

DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    raise Exception("Falta DATABASE_URL.\n  Windows: set DATABASE_URL=tu_url && python ml_service.py")

conn   = psycopg2.connect(DATABASE_URL, cursor_factory=RealDictCursor, sslmode="require")
cursor = conn.cursor()
print("✅ Conectado a la BD")

# ─── CREAR TABLAS DE RESULTADOS ───────────────────────────────────────────────

cursor.execute("""
    CREATE TABLE IF NOT EXISTS ml_perfiles_alumnos (
        id              SERIAL PRIMARY KEY,
        usuario_id      INTEGER UNIQUE REFERENCES cuentas(id),
        perfil          VARCHAR(20),   -- Normal / Irregular / Ausente
        total_escaneos  INTEGER,
        dias_activo     INTEGER,
        hora_promedio   FLOAT,
        frecuencia_semanal FLOAT,
        actualizado_en  TIMESTAMP DEFAULT NOW()
    )
""")

cursor.execute("""
    CREATE TABLE IF NOT EXISTS ml_anomalias_escaneos (
        id          SERIAL PRIMARY KEY,
        escaneo_id  INTEGER UNIQUE REFERENCES escaneos(id),
        usuario_id  INTEGER REFERENCES cuentas(id),
        score       FLOAT,
        motivo      VARCHAR(100),
        detectado_en TIMESTAMP DEFAULT NOW()
    )
""")
conn.commit()
print("✅ Tablas ML creadas/verificadas")

# ─── CARGAR DATOS ─────────────────────────────────────────────────────────────

print("\n📥 Cargando datos...")

cursor.execute("""
    SELECT
        e.id          as escaneo_id,
        e.usuario_id,
        e.fecha_hora,
        e.tipo_evento,
        e.ubicacion,
        EXTRACT(HOUR   FROM e.fecha_hora) as hora,
        EXTRACT(DOW    FROM e.fecha_hora) as dia_semana,
        EXTRACT(WEEK   FROM e.fecha_hora) as semana,
        c.nombre,
        c.apellido
    FROM escaneos e
    JOIN cuentas c ON e.usuario_id = c.id
    ORDER BY e.fecha_hora
""")

rows = cursor.fetchall()
df = pd.DataFrame([dict(r) for r in rows])

if df.empty:
    print("❌ No hay escaneos en la BD. Corre generar_datos.py primero.")
    exit(1)

print(f"   {len(df)} escaneos cargados de {df['usuario_id'].nunique()} alumnos")

# ─── MÓDULO 1: CLUSTERING DE ALUMNOS ──────────────────────────────────────────

print("\n🔵 Módulo 1: Clustering de alumnos...")

# Features por alumno
features_alumnos = []
usuario_ids      = df['usuario_id'].unique()

for uid in usuario_ids:
    u = df[df['usuario_id'] == uid]

    total_escaneos     = len(u)
    dias_unicos        = u['fecha_hora'].dt.date.nunique()
    hora_promedio      = u['hora'].mean()
    semanas_unicas     = u['semana'].nunique()
    frecuencia_semanal = total_escaneos / max(semanas_unicas, 1)
    dias_fin_semana    = u[u['dia_semana'].isin([0, 6])].shape[0]  # dom y sab

    features_alumnos.append({
        'usuario_id':         uid,
        'total_escaneos':     total_escaneos,
        'dias_activo':        dias_unicos,
        'hora_promedio':      hora_promedio,
        'frecuencia_semanal': frecuencia_semanal,
        'dias_fin_semana':    dias_fin_semana,
    })

df_alumnos = pd.DataFrame(features_alumnos)

# Normalizar features
X_alumnos = df_alumnos[['total_escaneos', 'dias_activo', 'frecuencia_semanal', 'dias_fin_semana']].values
scaler    = StandardScaler()
X_scaled  = scaler.fit_transform(X_alumnos)

# KMeans con 3 clusters
kmeans  = KMeans(n_clusters=3, random_state=42, n_init=10)
labels  = kmeans.fit_predict(X_scaled)

# Asignar nombre al cluster según frecuencia promedio
cluster_freq = {}
for i in range(3):
    mask = labels == i
    cluster_freq[i] = df_alumnos[mask]['frecuencia_semanal'].mean()

sorted_clusters = sorted(cluster_freq, key=cluster_freq.get, reverse=True)
nombre_cluster  = {
    sorted_clusters[0]: 'Normal',
    sorted_clusters[1]: 'Irregular',
    sorted_clusters[2]: 'Ausente',
}

df_alumnos['perfil'] = [nombre_cluster[l] for l in labels]

# Guardar en BD
cursor.execute("DELETE FROM ml_perfiles_alumnos")
for _, row in df_alumnos.iterrows():
    cursor.execute("""
        INSERT INTO ml_perfiles_alumnos
            (usuario_id, perfil, total_escaneos, dias_activo, hora_promedio, frecuencia_semanal)
        VALUES (%s, %s, %s, %s, %s, %s)
        ON CONFLICT (usuario_id) DO UPDATE SET
            perfil             = EXCLUDED.perfil,
            total_escaneos     = EXCLUDED.total_escaneos,
            dias_activo        = EXCLUDED.dias_activo,
            hora_promedio      = EXCLUDED.hora_promedio,
            frecuencia_semanal = EXCLUDED.frecuencia_semanal,
            actualizado_en     = NOW()
    """, (
        int(row['usuario_id']),
        row['perfil'],
        int(row['total_escaneos']),
        int(row['dias_activo']),
        float(row['hora_promedio']),
        float(row['frecuencia_semanal']),
    ))

conn.commit()

# Resumen
for perfil in ['Normal', 'Irregular', 'Ausente']:
    count = (df_alumnos['perfil'] == perfil).sum()
    print(f"   {perfil}: {count} alumnos")

# ─── MÓDULO 2: DETECCIÓN DE ANOMALÍAS ─────────────────────────────────────────

print("\n🔴 Módulo 2: Detección de anomalías...")

# Features por escaneo
df['hora']       = df['hora'].astype(float)
df['dia_semana'] = df['dia_semana'].astype(float)
df['es_madrugada']    = ((df['hora'] >= 0) & (df['hora'] < 6)).astype(int)
df['es_fin_semana']   = df['dia_semana'].isin([0, 6]).astype(int)
df['hora_sin']        = np.sin(2 * np.pi * df['hora'] / 24)
df['hora_cos']        = np.cos(2 * np.pi * df['hora'] / 24)

X_escaneos = df[['hora', 'dia_semana', 'es_madrugada', 'es_fin_semana', 'hora_sin', 'hora_cos']].values
scaler2    = StandardScaler()
X_esc_sc   = scaler2.fit_transform(X_escaneos)

# Isolation Forest — contamination = % esperado de anomalías
iso = IsolationForest(contamination=0.05, random_state=42, n_estimators=100)
preds  = iso.fit_predict(X_esc_sc)
scores = iso.score_samples(X_esc_sc)

df['anomalia'] = preds   # -1 = anomalía, 1 = normal
df['score']    = scores

anomalias = df[df['anomalia'] == -1].copy()

# Motivo de la anomalía
def motivo(row):
    if row['es_madrugada']:
        return f"Escaneo en madrugada ({int(row['hora'])}:00h)"
    if row['es_fin_semana']:
        dias = {0: 'domingo', 6: 'sábado'}
        return f"Escaneo en {dias.get(int(row['dia_semana']), 'fin de semana')}"
    return f"Patrón inusual (hora {int(row['hora'])}:00h)"

anomalias['motivo'] = anomalias.apply(motivo, axis=1)

# Guardar en BD
cursor.execute("DELETE FROM ml_anomalias_escaneos")
for _, row in anomalias.iterrows():
    cursor.execute("""
        INSERT INTO ml_anomalias_escaneos(escaneo_id, usuario_id, score, motivo)
        VALUES (%s, %s, %s, %s)
        ON CONFLICT (escaneo_id) DO UPDATE SET
            score        = EXCLUDED.score,
            motivo       = EXCLUDED.motivo,
            detectado_en = NOW()
    """, (
        int(row['escaneo_id']),
        int(row['usuario_id']),
        float(row['score']),
        row['motivo'],
    ))

conn.commit()
print(f"   {len(anomalias)} anomalías detectadas y guardadas")

# ─── RESUMEN FINAL ────────────────────────────────────────────────────────────

print("\n📊 RESUMEN FINAL ML:")
print(f"   Alumnos clasificados: {len(df_alumnos)}")
for perfil in ['Normal', 'Irregular', 'Ausente']:
    count = (df_alumnos['perfil'] == perfil).sum()
    print(f"     → {perfil}: {count}")
print(f"   Anomalías detectadas: {len(anomalias)}")

cursor.execute("""
    SELECT motivo, COUNT(*) as total
    FROM ml_anomalias_escaneos
    GROUP BY motivo
    ORDER BY total DESC
    LIMIT 5
""")
for r in cursor.fetchall():
    print(f"     → {r['motivo']}: {r['total']}")

cursor.close()
conn.close()
print("\n✅ ML completado — resultados guardados en BD")
print("   Tablas: ml_perfiles_alumnos, ml_anomalias_escaneos")