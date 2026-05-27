import time
import random
import requests

API_URL = "http://localhost:8000/lecturas"
ESTACION_ID = 1
TOKEN = "123456"
def leer_sensor_emulado():
    """Simula la lectura de un sensor con valores aleatorios."""
    return round(random.uniform(10.5, 85.0), 2)

def enviar_telemetria():
    print("Iniciando emisor IoT para Estación [ESTACION_ID].")
    while True:
        valor = leer_sensor_emulado()
        payload = {
            "valor": valor,
            "estacion_id": ESTACION_ID
        }
        headers = {"Authorization": f"Bearer {TOKEN}"}

        try:
            response = requests.post(API_URL, json=payload, headers=headers)
            if response.status_code == 200:
                print(f"[OK] Lectura enviada: {valor} cm ")
            else:
                print(f"[ERROR]Error al enviar telemetría: {response.status_code}")
        except Exception as e:
            print(f"[CRÍTICO] No hay conexión con el servidor: {e}")        

        time.sleep(5)  # Espera 5 segundos antes de la siguiente lectura
    if __name__ == "__main__":
        enviar_telemetria()
        