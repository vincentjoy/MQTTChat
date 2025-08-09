# MQTTChat - iOS MQTT Chat Application

A full-featured iOS chat application demonstrating MQTT protocol implementation using CocoaMQTT library with Swift 6 concurrency.

## Features

### Core MQTT Functions
- ✅ Connect to any MQTT broker (TCP/WebSocket)
- ✅ Publish/Subscribe with QoS levels (0, 1, 2)
- ✅ Retained messages support
- ✅ Clean session toggle
- ✅ Real-time message display

### Advanced MQTT v5 Features
- ✅ MQTT v5.0 protocol support
- ✅ Last Will and Testament (LWT)
- ✅ User properties and custom connect properties
- ✅ Reason codes and response details

### Security & Transport
- ✅ TLS/SSL encryption
- ✅ Self-signed certificates support
- ✅ WebSocket (WS/WSS) transport
- ✅ Username/password authentication
- ✅ JWT token support

### Connection Resilience
- ✅ Automatic reconnection with exponential backoff
- ✅ Background/foreground state handling
- ✅ Live connection status display
- ✅ Network change detection

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 6.0+

## Installation

### 1. Clone the repository
```bash
git clone https://github.com/vincentjoy/MQTTChat.git
cd MQTTChat
```

### 2. Install Dependencies

#### Using Swift Package Manager (Recommended)
1. Open the project in Xcode
2. Go to File → Add Package Dependencies
3. Add: `https://github.com/emqx/CocoaMQTT.git`
4. Select version: `2.1.0` or later

#### Using CocoaPods (Alternative)
```ruby
# Podfile
platform :ios, '17.0'
use_frameworks!

target 'MQTTChat' do
  pod 'CocoaMQTT', '~> 2.1'
end
```

Then run:
```bash
pod install
```

## Configuration

### Public Test Brokers

#### 1. Mosquitto Test Server
- **Host:** test.mosquitto.org
- **TCP Port:** 1883 (unencrypted), 8883 (TLS)
- **WebSocket Port:** 8080 (WS), 8081 (WSS)
- **Topic:** mqttchat/test/room1
- **No authentication required**

#### 2. EMQX Public Broker
- **Host:** broker.emqx.io
- **TCP Port:** 1883 (unencrypted), 8883 (TLS)
- **WebSocket Port:** 8083 (WS), 8084 (WSS)
- **Topic:** mqttchat/public/lobby
- **No authentication required**

#### 3. HiveMQ Public Broker
- **Host:** broker.hivemq.com
- **TCP Port:** 1883
- **WebSocket Port:** 8000
- **Topic:** mqttchat/demo/chat
- **No authentication required**

### Demo Configuration

For quick testing, use these settings:
```
Host: test.mosquitto.org
Port: 1883
Topic: mqttchat/demo/room1
Username: (leave empty)
Password: (leave empty)
TLS: Off
WebSocket: Off
MQTT Version: 5.0
QoS: 1
Clean Session: On
```

## Usage

### Basic Chat
1. Launch the app
2. Go to Settings tab
3. Enter broker details (use demo config above)
4. Tap "Connect"
5. Once connected, go to Chat tab
6. Start sending messages!

### Multi-User Simulation
1. Install the app on multiple devices
2. Use the same broker and topic
3. Set different usernames in Settings
4. Messages will appear with sender identification

### Advanced Features

#### Last Will and Testament (LWT)
1. In Settings, enable "Last Will"
2. Set LWT topic and message
3. When device disconnects unexpectedly, broker publishes LWT message

#### Retained Messages
1. Enable "Retain" toggle when sending
2. New subscribers will receive the last retained message

#### QoS Levels
- **QoS 0:** At most once (fire and forget)
- **QoS 1:** At least once (acknowledged)
- **QoS 2:** Exactly once (4-way handshake)

## Troubleshooting

### Connection Issues
- Verify broker is reachable: `ping broker.address`
- Check firewall settings
- For TLS connections, ensure correct port (usually 8883)
- For self-signed certificates, enable "Allow Self-Signed" option

### Message Not Received
- Verify both devices use same topic
- Check QoS settings
- Ensure subscription is active before publishing
- Check broker logs for errors

### Background Disconnections
- iOS limits background network activity
- App implements automatic reconnection on foreground
- Consider using push notifications for critical messages

## Security Considerations

- Always use TLS in production
- Implement proper authentication
- Use unique client IDs
- Sanitize message content
- Consider message encryption for sensitive data

## License

MIT License - See LICENSE file for details

## Support

For issues or questions:
- GitHub Issues: [Report a bug](https://github.com/yourusername/MQTTChat/issues)
- Documentation: [MQTT Protocol](https://mqtt.org/)
- CocoaMQTT: [Library Documentation](https://github.com/emqx/CocoaMQTT)
