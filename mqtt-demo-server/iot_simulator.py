#!/usr/bin/env python3
"""
IoT Device Simulator for MQTT Demo
Simulates various IoT devices publishing to MQTT broker
"""

import paho.mqtt.client as mqtt
import json
import random
import time
import threading
from datetime import datetime
import argparse
import socket

class IoTDeviceSimulator:
    def __init__(self, broker_host="localhost", broker_port=1883):
        self.broker_host = broker_host
        self.broker_port = broker_port
        self.client = mqtt.Client(client_id=f"iot_simulator_{random.randint(1000, 9999)}")
        self.running = False

        # Configure callbacks
        self.client.on_connect = self.on_connect
        self.client.on_message = self.on_message
        self.client.on_disconnect = self.on_disconnect

    def on_connect(self, client, userdata, flags, rc):
        if rc == 0:
            print(f"✅ Connected to MQTT Broker at {self.broker_host}:{self.broker_port}")
            # Subscribe to command topics
            client.subscribe("home/+/command")
            client.subscribe("mqttchat/+/+")  # Subscribe to chat topics
            print("📥 Subscribed to command topics")
        else:
            print(f"❌ Failed to connect, return code {rc}")

    def on_message(self, client, userdata, msg):
        """Handle incoming messages (commands from iPhone app)"""
        try:
            topic = msg.topic
            payload = msg.payload.decode('utf-8')
            print(f"📨 Received: [{topic}] {payload}")

            # Respond to chat messages
            if "mqttchat" in topic:
                self.send_chat_response(payload)

            # Handle device commands
            elif "command" in topic:
                self.handle_command(topic, payload)

        except Exception as e:
            print(f"Error handling message: {e}")

    def on_disconnect(self, client, userdata, rc):
        print(f"🔌 Disconnected from broker (rc: {rc})")
        if rc != 0:
            print("Unexpected disconnection. Will auto-reconnect...")

    def connect(self):
        """Connect to MQTT broker"""
        try:
            print(f"🔄 Connecting to {self.broker_host}:{self.broker_port}...")
            self.client.connect(self.broker_host, self.broker_port, 60)
            self.client.loop_start()
            self.running = True
            return True
        except Exception as e:
            print(f"❌ Connection failed: {e}")
            return False

    def disconnect(self):
        """Disconnect from broker"""
        self.running = False
        self.client.loop_stop()
        self.client.disconnect()
        print("👋 Disconnected from broker")

    def send_chat_response(self, received_message):
        """Auto-respond to chat messages"""
        responses = [
            f"IoT Device received: '{received_message}'",
            "Hello from your MacBook IoT simulator! 🤖",
            f"Processing your message... Message length: {len(received_message)} chars",
            "All systems operational! 🟢",
            f"Timestamp: {datetime.now().strftime('%H:%M:%S')} - Message acknowledged"
        ]

        time.sleep(0.5)  # Small delay to simulate processing
        response = random.choice(responses)
        self.client.publish("mqttchat/demo/room1", response, qos=1)
        print(f"💬 Sent chat response: {response}")

    def handle_command(self, topic, payload):
        """Handle device control commands"""
        device = topic.split('/')[1]

        try:
            command = json.loads(payload) if payload.startswith('{') else {"action": payload}
            print(f"🎮 Executing command for {device}: {command}")

            # Send acknowledgment
            response = {
                "device": device,
                "command": command,
                "status": "executed",
                "timestamp": datetime.now().isoformat()
            }

            self.client.publish(f"home/{device}/status", json.dumps(response), qos=1)

        except Exception as e:
            print(f"Error handling command: {e}")

    def simulate_temperature_sensor(self):
        """Simulate temperature sensor data"""
        while self.running:
            temp = round(20 + random.uniform(-5, 5), 1)
            humidity = round(50 + random.uniform(-10, 10), 1)

            data = {
                "temperature": temp,
                "humidity": humidity,
                "unit": "celsius",
                "timestamp": datetime.now().isoformat(),
                "location": "living_room"
            }

            topic = "home/sensors/temperature"
            self.client.publish(topic, json.dumps(data), qos=1, retain=True)
            print(f"🌡️  Temperature: {temp}°C, Humidity: {humidity}%")

            time.sleep(5)  # Send every 5 seconds

    def simulate_motion_sensor(self):
        """Simulate motion sensor events"""
        while self.running:
            time.sleep(random.randint(10, 30))  # Random intervals

            if random.random() > 0.7:  # 30% chance of motion
                data = {
                    "motion": True,
                    "location": random.choice(["entrance", "hallway", "garage"]),
                    "timestamp": datetime.now().isoformat(),
                    "confidence": round(random.uniform(0.7, 1.0), 2)
                }

                topic = "home/sensors/motion"
                self.client.publish(topic, json.dumps(data), qos=2)
                print(f"🚶 Motion detected at {data['location']}!")

    def simulate_smart_light(self):
        """Simulate smart light status"""
        light_state = {"on": False, "brightness": 0, "color": "white"}

        while self.running:
            # Randomly change light state
            if random.random() > 0.8:
                light_state["on"] = not light_state["on"]
                light_state["brightness"] = random.randint(0, 100) if light_state["on"] else 0
                light_state["color"] = random.choice(["white", "warm", "cool", "red", "blue", "green"])

                data = {
                    **light_state,
                    "timestamp": datetime.now().isoformat(),
                    "device_id": "light_001"
                }

                topic = "home/lights/living_room"
                self.client.publish(topic, json.dumps(data), qos=1, retain=True)

                status = "ON" if light_state["on"] else "OFF"
                print(f"💡 Light: {status}, Brightness: {light_state['brightness']}%, Color: {light_state['color']}")

            time.sleep(8)

    def simulate_door_sensor(self):
        """Simulate door open/close events"""
        doors = ["front", "back", "garage"]
        door_states = {door: "closed" for door in doors}

        while self.running:
            time.sleep(random.randint(15, 45))

            door = random.choice(doors)
            door_states[door] = "open" if door_states[door] == "closed" else "closed"

            data = {
                "door": door,
                "state": door_states[door],
                "timestamp": datetime.now().isoformat(),
                "battery": random.randint(70, 100)
            }

            topic = f"home/doors/{door}"
            self.client.publish(topic, json.dumps(data), qos=1)

            emoji = "🚪" if door_states[door] == "open" else "🔒"
            print(f"{emoji} {door.capitalize()} door: {door_states[door]}")

    def simulate_energy_meter(self):
        """Simulate energy consumption data"""
        base_consumption = 2000  # Watts

        while self.running:
            consumption = base_consumption + random.randint(-500, 1000)

            data = {
                "power": consumption,
                "unit": "watts",
                "voltage": 220 + random.uniform(-5, 5),
                "current": consumption / 220,
                "timestamp": datetime.now().isoformat(),
                "total_today": round(random.uniform(10, 30), 2)  # kWh
            }

            topic = "home/energy/meter"
            self.client.publish(topic, json.dumps(data), qos=0)
            print(f"⚡ Power consumption: {consumption}W")

            time.sleep(10)

    def send_periodic_announcement(self):
        """Send periodic system status"""
        while self.running:
            time.sleep(30)  # Every 30 seconds

            # Get local IP address
            hostname = socket.gethostname()
            ip_address = socket.gethostbyname(hostname)

            status = {
                "system": "IoT Simulator",
                "status": "online",
                "hostname": hostname,
                "ip": ip_address,
                "devices": ["temperature", "motion", "light", "door", "energy"],
                "uptime": time.time(),
                "timestamp": datetime.now().isoformat()
            }

            self.client.publish("home/system/status", json.dumps(status), qos=1, retain=True)
            print(f"📢 System announcement sent")

    def start_all_simulators(self):
        """Start all device simulators in separate threads"""
        simulators = [
            ("Temperature", self.simulate_temperature_sensor),
            ("Motion", self.simulate_motion_sensor),
            ("Light", self.simulate_smart_light),
            ("Door", self.simulate_door_sensor),
            ("Energy", self.simulate_energy_meter),
            ("Announcer", self.send_periodic_announcement)
        ]

        threads = []
        for name, simulator in simulators:
            thread = threading.Thread(target=simulator, name=name)
            thread.daemon = True
            thread.start()
            threads.append(thread)
            print(f"✅ Started {name} simulator")

        return threads

    def run(self):
        """Main run loop"""
        if not self.connect():
            return

        print("\n🚀 Starting IoT Device Simulators...")
        print("=" * 50)

        # Start all simulators
        threads = self.start_all_simulators()

        print("\n📱 Configure your iPhone app with:")
        print(f"   Host: {self.get_local_ip()}")
        print(f"   Port: {self.broker_port}")
        print("   Topic: mqttchat/demo/room1")
        print("   Or subscribe to: home/+/+")
        print("\n Press Ctrl+C to stop...")
        print("=" * 50 + "\n")

        try:
            while self.running:
                time.sleep(1)
        except KeyboardInterrupt:
            print("\n\n🛑 Shutting down simulators...")
            self.disconnect()

    def get_local_ip(self):
        """Get local IP address for iPhone connection"""
        try:
            # Create a socket to get local IP
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.connect(("8.8.8.8", 80))
            ip = s.getsockname()[0]
            s.close()
            return ip
        except:
            return socket.gethostbyname(socket.gethostname())

def main():
    parser = argparse.ArgumentParser(description='IoT Device Simulator for MQTT')
    parser.add_argument('--host', default='localhost', help='MQTT broker host')
    parser.add_argument('--port', type=int, default=1883, help='MQTT broker port')

    args = parser.parse_args()

    print("🤖 IoT Device Simulator for MQTT Demo")
    print("=" * 50)

    simulator = IoTDeviceSimulator(args.host, args.port)
    simulator.run()

if __name__ == "__main__":
    main()