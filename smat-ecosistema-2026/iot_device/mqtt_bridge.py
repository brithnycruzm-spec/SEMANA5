import paho.mqtt.client as mqtt
import json
import requests
import sys  
import time
last_sen = {}

MQTT_BROKER = "broker.hivemq.com"
MQTT_PORT = 1883  # ✅ Faltaba definir MQTT_PORT
MQTT_TOPIC = "fisi/smat/estacion/+/lecturas"
API_URL = "http://localhost:8000/lecturas/"

DEADBAND_PORCENTAJE = 0.05  # 5% de variación mínima
DEADBAND_TIEMPO_MAX = 60    # segundos máximos sin reportar

JWT_TOKEN = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ1c2VyQGV4YW1wbGUuY29tIiwiaWF0IjoxNjg4ODk3ODQxfQ.7s8n9mLh8lHjKZy7vVh5eXo9z8a9b6c5d4e3f2g1h0"

def debandband_filter(estacion_id, nuevo_valor):
    """
    Retorna (True, motivo) si el valor DEBE enviarse a la API.
    Retorna (False, motivo) si el valor es REDUNDANTE y debe bloquearse.
    """
    ahora = time.time()

    if estacion_id not in last_sen:
        return True, "🆕 Primera lectura de la estación"

    ultimo = last_sen[estacion_id]
    ultimo_valor = ultimo["valor"]
    ultimo_tiempo = ultimo["timestamp"]
    segundos_transcurridos = ahora - ultimo_tiempo

    if segundos_transcurridos >= DEADBAND_TIEMPO_MAX:
        return True, f"⏱️  Timeout alcanzado ({segundos_transcurridos:.1f}s >= {DEADBAND_TIEMPO_MAX}s) → Reporte de vida forzado"

    if ultimo_valor == 0:
        variacion = float("inf") if nuevo_valor != 0 else 0.0
    else:
        variacion = abs(nuevo_valor - ultimo_valor) / abs(ultimo_valor)

    if variacion > DEADBAND_PORCENTAJE:
        return True, f"📈 Cambio significativo detectado ({variacion * 100:.2f}% > {DEADBAND_PORCENTAJE * 100:.0f}%)"

    return False, (
        f"🔇 Filtrado — Δ={variacion * 100:.2f}% (umbral: {DEADBAND_PORCENTAJE * 100:.0f}%), "
        f"hace {segundos_transcurridos:.1f}s (timeout: {DEADBAND_TIEMPO_MAX}s)"
    )

def on_connect(client, userdata, flags, rc):
    if rc == 0:
        print("🟢 Conectado exitosamente al broker MQTT")
        client.subscribe(MQTT_TOPIC)
        print(f"📡 Escuchando transmisiones en el tópico: {MQTT_TOPIC}")
    else:
        print(f"🔴 Error de conexión MQTT: {rc}")
        sys.exit(1)

def on_message(client, userdata, msg):
    try:
        payload_raw = msg.payload.decode("utf-8")
        data = json.loads(payload_raw)
        print(f"Mensaje recibido en {msg.topic}: {data}")  

        topic_parts = msg.topic.split('/')
        estacion_id = int(topic_parts[3])

        print(f"📩 Telemetría recibida de la Estación [{estacion_id}]: {data}")  
        
        nuevo_valor = float(data["valor"])  
        debe_enviar, motivo = debandband_filter(estacion_id, nuevo_valor)
        print(f"   {motivo}")

        if not debe_enviar:
            print(f"   🚫 HTTP POST bloqueado — DB protegida de escritura redundante")
            return

        api_payload = {
            "valor": nuevo_valor,
            "estacion_id": estacion_id
        }
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {JWT_TOKEN}"
        }
        response = requests.post(API_URL, json=api_payload, headers=headers)

        if response.status_code == 200 or response.status_code == 201:
            last_sen[estacion_id] = {
                "valor": nuevo_valor,
                "timestamp": time.time()
            }
            print(f"💾 [DB Sincronizada] Lectura de {api_payload['valor']} cm guardada en SQLite.")
        else:
            print(f"⚠️ Error al guardar en DB (API {response.status_code}): {response.text}")

    except KeyError as e: 
        print(f"❌ Error de esquema: Falta la llave {e} en el payload MQTT.")
    except ValueError:  
        print(f"❌ Error de casteo: El valor o el ID no son numéricos.")
    except Exception as e: 
        print(f"❌ Error crítico en el Bridge: {e}")



if __name__ == "__main__":
    bridge_client = mqtt.Client()
    bridge_client.on_connect = on_connect
    bridge_client.on_message = on_message

    try:
        print("🚀 Inicializando el Bridge de Acoplamiento SMAT...")
        bridge_client.connect(MQTT_BROKER, MQTT_PORT, 60)
        bridge_client.loop_forever()
    except KeyboardInterrupt:
        print("🛑 Bridge detenido por el administrador.")