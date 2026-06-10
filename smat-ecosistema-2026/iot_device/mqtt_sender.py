import paho.mqtt.client as mqtt
import json
import time
import random
import requests
import sys

BROKER = "broker.hivemq.com"
PORT = 1883
TOPIC = "fisi/smat/estacion/+/lecturas"

client = mqtt.Client()
client.connect(BROKER, PORT)

while True:
    payload = {
        "valor": round(random.uniform(20, 60), 2),
        "timestamp": time.time()
    }
    client.publish(TOPIC, json.dumps(payload))
    time.sleep(10)