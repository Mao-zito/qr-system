import psycopg2

conexion = psycopg2.connect(
    host="localhost",
    database="qr_system",
    user="postgres",
    password="Kirito2018"
)

cursor = conexion.cursor()

cursor.execute("SELECT nombre FROM objetos")

datos = cursor.fetchall()

print("OBJETOS REGISTRADOS:")

for fila in datos:
    print(fila[0])

cursor.close()
conexion.close()