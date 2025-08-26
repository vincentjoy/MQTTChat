# Local MQTT Demo Setup Guide

This guide explains how to set up your MacBook as both an MQTT broker and IoT device simulator for testing the MQTTChat iOS app locally without requiring an internet connection.

## 🎯 Overview

This setup creates a complete MQTT ecosystem on your local network:
- **MQTT Broker**: Mosquitto running on your MacBook
- **IoT Simulator**: Python script simulating multiple smart home devices
- **iOS Client**: MQTTChat app on your iPhone/Simulator

## 📋 Prerequisites

- macOS 10.15 or later
- Xcode 15+ with iOS 17+ SDK
- Python 3.8+
- iPhone with iOS 17+ (or iOS Simulator)
- Both devices on the same WiFi network

## 🚀 Quick Start

### 1. Navigate to the demo server directory
```bash
cd MQTTChat/mqtt-demo-server
```

### 2. Run the setup script
```bash
chmod +x setup_mqtt_demo.sh
./setup_mqtt_demo.sh
```

This script will:
- Install Homebrew (if needed)
- Install Mosquitto MQTT broker
- Install Python dependencies
- Create all necessary configuration files

### 3. Start the demo environment
```bash
./start_mqtt_demo.sh
```

You'll see output like:
```
📱 iPhone App Configuration:
=========================================
Host:     192.168.1.100
Port:     1883
Topic:    mqttchat/demo/room1
=========================================
```

### 4. Configure the iOS app
Open MQTTChat on your iPhone:
1. Go to **Settings** tab
2. Enter the configuration shown by the script
3. Tap **Connect**
4. Go to **Chat** tab and start messaging!

## 🏗️ Architecture

```
┌─────────────┐       MQTT        ┌──────────────┐
│   iPhone    │◄──────────────────►│   MacBook    │
│  MQTTChat   │      Protocol      │              │
│    App      │                    │  ┌────────┐  │
└─────────────┘                    │  │Mosquito│  │
                                   │  │ Broker │  │
                                   │  └────────┘  │
                                   │       ▲      │
                                   │       │      │
                                   │  ┌────▼────┐ │
                                   │  │   IoT   │ │
                                   │  │Simulator│ │
                                   │  └─────────┘ │
                                   └──────────────┘
```

## 🤖 Simulated IoT Devices

The simulator creates multiple virtual devices:

### 1. **Temperature Sensor**
- **Topic**: `home/sensors/temperature`
- **Updates**: Every 5 seconds
- **Data**: Temperature (°C) and humidity (%)

### 2. **Motion Sensor**
- **Topic**: `home/sensors/motion`
- **Updates**: Random intervals (10-30 seconds)
- **Data**: Motion detection with location

### 3. **Smart Lights**
- **Topic**: `home/lights/living_room`
- **Updates**: State changes every 8 seconds
- **Data**: On/off state, brightness, color

### 4. **Door Sensors**
- **Topic**: `home/doors/{front|back|garage}`
- **Updates**: Random door events
- **Data**: Open/closed state, battery level

### 5. **Energy Meter**
- **Topic**: `home/energy/meter`
- **Updates**: Every 10 seconds
- **Data**: Power consumption in watts

### 6. **Chat Bot**
- **Topic**: `mqttchat/demo/room1`
- **Response**: Auto-responds to chat messages

## 📱 Demo Scenarios

### Scenario 1: Basic Chat Communication
1. Send a message from the iPhone app
2. The IoT simulator will auto-respond
3. Observe bidirectional real-time messaging

### Scenario 2: Monitor IoT Devices
Change the topic in Settings to monitor different devices:
- `home/sensors/+` - All sensors
- `home/lights/+` - All lights
- `home/doors/+` - All doors
- `home/#` - Everything

### Scenario 3: Send Commands
Publish commands to control virtual devices:
```json
Topic: home/lights/command
Message: {"action": "toggle", "brightness": 75}

Topic: home/door/command
Message: {"action": "lock"}
```

### Scenario 4: Test MQTT Features
- **QoS Levels**: Try QoS 0, 1, and 2
- **Retained Messages**: Enable retain and reconnect
- **LWT**: Configure Last Will and disconnect
- **Clean Session**: Test with on/off

## 🔧 Advanced Configuration

### Custom Broker Settings
Edit `mosquitto_demo.conf`:
```conf
# Change port
listener 1884

# Enable authentication
allow_anonymous false
password_file /path/to/passwords

# Enable TLS
listener 8883
certfile /path/to/cert.pem
keyfile /path/to/key.pem
```

### Modify IoT Simulator
Edit `iot_simulator.py` to:
- Add new device types
- Change update intervals
- Modify data formats
- Add custom responses

### Network Testing
Simulate network issues:
```bash
# Delay packets (100ms)
sudo pfctl -E
echo "dummynet in proto tcp from any to any port 1883 pipe 1" | sudo pfctl -f -
sudo dnctl pipe 1 config delay 100

# Cleanup
sudo pfctl -F all -d
```

## 🛠️ Troubleshooting

### Can't Connect from iPhone

1. **Check IP address**:
```bash
# Get your current IP
ipconfig getifaddr en0  # WiFi
ipconfig getifaddr en1  # Ethernet
```

2. **Verify broker is running**:
```bash
# Check if Mosquitto is listening
lsof -i :1883

# Test locally
mosquitto_sub -h localhost -t "#" -v
```

3. **Firewall issues**:
```bash
# Allow Mosquitto through firewall
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /usr/local/sbin/mosquitto
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --unblockapp /usr/local/sbin/mosquitto
```

4. **Same network check**:
- Ensure iPhone and MacBook are on the same WiFi
- Disable VPNs on both devices
- Try using iPhone hotspot as a test

### Port Already in Use
```bash
# Find process using port 1883
lsof -i :1883

# Kill the process
kill -9 <PID>

# Or use a different port
mosquitto -p 1884 -c mosquitto_demo.conf
```

### Python Module Not Found
```bash
# Install with pip3
pip3 install paho-mqtt

# If you get permissions error
pip3 install --user paho-mqtt

# Or with virtual environment
python3 -m venv venv
source venv/bin/activate
pip install paho-mqtt
```

### iOS Simulator Connection
When using iOS Simulator instead of physical device:
- Use `localhost` or `127.0.0.1` as host
- Ensure broker allows localhost connections

## 📊 Monitoring Tools

### Watch All MQTT Traffic
```bash
# Subscribe to all topics with timestamp
mosquitto_sub -h localhost -t "#" -v | while read line; do
    echo "[$(date '+%H:%M:%S')] $line"
done
```

### GUI Monitoring with MQTT Explorer
```bash
# Install MQTT Explorer
brew install --cask mqtt-explorer

# Connect to localhost:1883
```

### Test Publishing
```bash
# Simple message
mosquitto_pub -h localhost -t test -m "Hello World"

# JSON payload
mosquitto_pub -h localhost -t sensor -m '{"temp": 25, "humidity": 60}'

# With QoS and retain
mosquitto_pub -h localhost -t status -m "Online" -q 2 -r
```

## 🎬 Demo Presentation Script

Perfect for demonstrating MQTT capabilities:

1. **Setup** (1 min)
   - Start the demo environment
   - Connect iPhone to broker
   - Show successful connection

2. **Basic Messaging** (2 min)
   - Send "Hello from iPhone!"
   - Receive auto-response
   - Show message metadata (QoS, timestamp)

3. **IoT Monitoring** (3 min)
   - Subscribe to temperature sensor
   - Show real-time updates
   - Switch to motion sensor
   - Demonstrate event-driven updates

4. **Advanced Features** (3 min)
   - Send retained message
   - Disconnect and reconnect
   - Show retained message received
   - Demo different QoS levels
   - Configure and test LWT

5. **Resilience** (2 min)
   - Stop broker (Ctrl+C)
   - Show reconnection attempts
   - Restart broker
   - Show automatic recovery

## 🔐 Security Notes

This demo setup is for **development only**:
- Anonymous access is enabled
- No encryption by default
- All topics are public

For production:
- Enable TLS/SSL
- Implement authentication
- Use ACL for topic permissions
- Never expose broker to internet

## 📚 Learning Resources

- [MQTT Protocol Specification](https://mqtt.org/mqtt-specification/)
- [Mosquitto Documentation](https://mosquitto.org/documentation/)
- [Paho MQTT Python](https://pypi.org/project/paho-mqtt/)
- [CocoaMQTT iOS Library](https://github.com/emqx/CocoaMQTT)

## 🆘 Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review logs in the terminal
3. Ensure all prerequisites are installed
4. Verify network connectivity

## 📝 Notes

- The simulator generates random but realistic IoT data
- All data is ephemeral (not persisted)
- Suitable for development and testing
- Can handle multiple simultaneous connections
- Supports MQTT v3.1.1 and v5.0 protocols

---

**Happy Testing! 🚀**