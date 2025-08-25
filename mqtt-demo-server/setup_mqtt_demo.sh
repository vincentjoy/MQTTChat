#!/bin/bash

# MQTT Demo Setup Script for MacBook
# This script sets up everything needed for the MQTT demo

set -e

echo "🚀 MQTT Demo Setup Script"
echo "========================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to get local IP
get_local_ip() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        ipconfig getifaddr en0 || ipconfig getifaddr en1 || echo "localhost"
    else
        # Linux
        hostname -I | awk '{print $1}' || echo "localhost"
    fi
}

# Step 1: Check and install Homebrew
echo -e "\n${YELLOW}Step 1: Checking Homebrew...${NC}"
if ! command_exists brew; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo -e "${GREEN}✓ Homebrew is installed${NC}"
fi

# Step 2: Install Mosquitto
echo -e "\n${YELLOW}Step 2: Installing Mosquitto MQTT Broker...${NC}"
if ! command_exists mosquitto; then
    brew install mosquitto
    echo -e "${GREEN}✓ Mosquitto installed${NC}"
else
    echo -e "${GREEN}✓ Mosquitto is already installed${NC}"
fi

# Step 3: Install Python dependencies
echo -e "\n${YELLOW}Step 3: Installing Python dependencies...${NC}"
if ! command_exists python3; then
    echo "Installing Python 3..."
    brew install python3
fi

echo "Installing paho-mqtt..."
pip3 install paho-mqtt --break-system-packages 2>/dev/null || pip3 install paho-mqtt

echo -e "${GREEN}✓ Python dependencies installed${NC}"

# Step 4: Create configuration files
echo -e "\n${YELLOW}Step 4: Creating configuration files...${NC}"

# Create mosquitto config
cat > mosquitto_demo.conf << 'EOF'
# Mosquitto Configuration for MQTT Demo
listener 1883
protocol mqtt

# WebSocket support
listener 9001
protocol websockets

# Allow anonymous access for demo
allow_anonymous true

# Logging
log_type all
log_dest stdout

# Persistence
persistence false

# Max connections
max_connections 100
EOF

echo -e "${GREEN}✓ Created mosquitto_demo.conf${NC}"

# Step 5: Create start script
cat > start_mqtt_demo.sh << 'EOF'
#!/bin/bash

# Start MQTT Demo Script

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Get local IP
LOCAL_IP=$(ipconfig getifaddr en0 || ipconfig getifaddr en1 || echo "localhost")

echo -e "${GREEN}Starting MQTT Demo Environment${NC}"
echo "================================"

# Start Mosquitto in background
echo -e "\n${YELLOW}Starting Mosquitto Broker...${NC}"
mosquitto -c mosquitto_demo.conf &
MOSQUITTO_PID=$!
echo -e "${GREEN}✓ Mosquitto started (PID: $MOSQUITTO_PID)${NC}"

sleep 2

# Start IoT Simulator
echo -e "\n${YELLOW}Starting IoT Device Simulator...${NC}"
python3 iot_simulator.py &
SIMULATOR_PID=$!
echo -e "${GREEN}✓ IoT Simulator started (PID: $SIMULATOR_PID)${NC}"

echo ""
echo "========================================="
echo -e "${GREEN}📱 iPhone App Configuration:${NC}"
echo "========================================="
echo -e "Host:     ${YELLOW}$LOCAL_IP${NC}"
echo -e "Port:     ${YELLOW}1883${NC}"
echo -e "Topic:    ${YELLOW}mqttchat/demo/room1${NC}"
echo ""
echo "Alternative topics to subscribe:"
echo "  • home/sensors/temperature"
echo "  • home/sensors/motion"
echo "  • home/lights/+"
echo "  • home/doors/+"
echo "  • home/energy/meter"
echo "========================================="
echo ""
echo -e "${YELLOW}Press Ctrl+C to stop all services${NC}"

# Function to cleanup on exit
cleanup() {
    echo -e "\n${RED}Stopping services...${NC}"
    kill $MOSQUITTO_PID 2>/dev/null
    kill $SIMULATOR_PID 2>/dev/null
    echo -e "${GREEN}✓ All services stopped${NC}"
    exit 0
}

# Set trap for cleanup
trap cleanup INT TERM

# Wait for interrupt
while true; do
    sleep 1
done
EOF

chmod +x start_mqtt_demo.sh
echo -e "${GREEN}✓ Created start_mqtt_demo.sh${NC}"

# Step 6: Create test publisher script
cat > test_publisher.py << 'EOF'
#!/usr/bin/env python3
"""Simple MQTT test publisher"""

import paho.mqtt.client as mqtt
import time
import sys

def on_connect(client, userdata, flags, rc):
    print(f"Connected with result code {rc}")

client = mqtt.Client()
client.on_connect = on_connect

# Get IP from command line or use localhost
host = sys.argv[1] if len(sys.argv) > 1 else "localhost"

client.connect(host, 1883, 60)
client.loop_start()

messages = [
    "Hello from MacBook! 👋",
    "This is a test message 🧪",
    "MQTT is working! ✅",
    "IoT devices are online 🤖",
    "Temperature: 22°C 🌡️"
]

for msg in messages:
    client.publish("mqttchat/demo/room1", msg, qos=1)
    print(f"Sent: {msg}")
    time.sleep(2)

client.loop_stop()
client.disconnect()
EOF

chmod +x test_publisher.py
echo -e "${GREEN}✓ Created test_publisher.py${NC}"

# Final instructions
LOCAL_IP=$(get_local_ip)

echo ""
echo "========================================="
echo -e "${GREEN}✅ Setup Complete!${NC}"
echo "========================================="
echo ""
echo "To start the demo:"
echo -e "  ${YELLOW}./start_mqtt_demo.sh${NC}"
echo ""
echo "Your iPhone app configuration:"
echo -e "  Host: ${YELLOW}$LOCAL_IP${NC}"
echo -e "  Port: ${YELLOW}1883${NC}"
echo ""
echo "To test publishing:"
echo -e "  ${YELLOW}python3 test_publisher.py${NC}"
echo ""
echo "========================================="