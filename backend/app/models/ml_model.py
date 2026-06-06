from app.database import Database


class MLModel:

    @staticmethod
    def obtener_perfiles():
        conn = Database.get_connection()
        try:
            with conn.cursor() as cursor:
                cursor.execute("""
                    SELECT
                        p.usuario_id,
                        c.nombre,
                        c.apellido,
                        c.codigo_estudiante,
                        c.correo,
                        p.perfil,
                        p.total_escaneos,
                        p.dias_activo,
                        p.hora_promedio,
                        p.frecuencia_semanal,
                        p.actualizado_en
                    FROM ml_perfiles_alumnos p
                    JOIN cuentas c ON p.usuario_id = c.id
                    ORDER BY
                        CASE p.perfil
                            WHEN 'Ausente'    THEN 1
                            WHEN 'Irregular'  THEN 2
                            WHEN 'Normal'     THEN 3
                        END,
                        p.frecuencia_semanal DESC
                """)
                datos = cursor.fetchall()
                return [
                    {
                        "usuario_id":         fila["usuario_id"],
                        "nombre":             fila["nombre"],
                        "apellido":           fila["apellido"],
                        "codigo_estudiante":  fila["codigo_estudiante"],
                        "correo":             fila["correo"],
                        "perfil":             fila["perfil"],
                        "total_escaneos":     fila["total_escaneos"],
                        "dias_activo":        fila["dias_activo"],
                        "hora_promedio":      round(float(fila["hora_promedio"]), 1),
                        "frecuencia_semanal": round(float(fila["frecuencia_semanal"]), 2),
                        "actualizado_en":     str(fila["actualizado_en"]),
                    }
                    for fila in datos
                ]
        finally:
            Database.release(conn)

    @staticmethod
    def obtener_anomalias(limite: int = 100):
        conn = Database.get_connection()
        try:
            with conn.cursor() as cursor:
                cursor.execute("""
                    SELECT
                        a.id,
                        a.escaneo_id,
                        a.usuario_id,
                        c.nombre,
                        c.apellido,
                        c.codigo_estudiante,
                        a.score,
                        a.motivo,
                        a.detectado_en,
                        e.fecha_hora,
                        e.ubicacion,
                        e.tipo_evento,
                        o.nombre as objeto
                    FROM ml_anomalias_escaneos a
                    JOIN cuentas  c ON a.usuario_id  = c.id
                    JOIN escaneos e ON a.escaneo_id  = e.id
                    JOIN objetos  o ON e.objeto_id   = o.id
                    ORDER BY a.score ASC
                    LIMIT %s
                """, (limite,))
                datos = cursor.fetchall()
                return [
                    {
                        "id":                fila["id"],
                        "escaneo_id":        fila["escaneo_id"],
                        "usuario_id":        fila["usuario_id"],
                        "nombre":            fila["nombre"],
                        "apellido":          fila["apellido"],
                        "codigo_estudiante": fila["codigo_estudiante"],
                        "score":             round(float(fila["score"]), 4),
                        "motivo":            fila["motivo"],
                        "detectado_en":      str(fila["detectado_en"]),
                        "fecha_hora":        str(fila["fecha_hora"]),
                        "ubicacion":         fila["ubicacion"],
                        "tipo_evento":       fila["tipo_evento"],
                        "objeto":            fila["objeto"],
                    }
                    for fila in datos
                ]
        finally:
            Database.release(conn)

    @staticmethod
    def obtener_resumen():
        conn = Database.get_connection()
        try:
            with conn.cursor() as cursor:
                # Conteo por perfil
                cursor.execute("""
                    SELECT perfil, COUNT(*) as total
                    FROM ml_perfiles_alumnos
                    GROUP BY perfil
                """)
                perfiles = {r["perfil"]: r["total"] for r in cursor.fetchall()}

                # Total anomalías
                cursor.execute("SELECT COUNT(*) as total FROM ml_anomalias_escaneos")
                total_anomalias = cursor.fetchone()["total"]

                # Anomalías por motivo
                cursor.execute("""
                    SELECT motivo, COUNT(*) as total
                    FROM ml_anomalias_escaneos
                    GROUP BY motivo
                    ORDER BY total DESC
                    LIMIT 5
                """)
                por_motivo = [
                    {"motivo": r["motivo"], "total": r["total"]}
                    for r in cursor.fetchall()
                ]

                # Última actualización
                cursor.execute("SELECT MAX(actualizado_en) as ultima FROM ml_perfiles_alumnos")
                ultima = cursor.fetchone()["ultima"]

                return {
                    "perfiles":         perfiles,
                    "total_anomalias":  total_anomalias,
                    "anomalias_por_motivo": por_motivo,
                    "ultima_actualizacion": str(ultima) if ultima else None,
                }
        finally:
            Database.release(conn)