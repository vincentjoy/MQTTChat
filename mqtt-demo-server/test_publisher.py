#!/usr/bin/env python3
"""
Test MQTT Publisher
Simple script to test publishing messages to the MQTT broker
"""

import paho.mqtt.client as mqtt
import json
import time
import sys
import argparse
from datetime import datetime

def on_connect(client, userdata, flags, rc):
    if rc == 0:
        print(f"✅ Connected to broker")
    else:
        print(f"❌ Connection failed with code {rc}")

def on_publish(client, userdata, mid):
    print(f"📤 Message {mid} published")

def publish_test_messages(host="localhost", port=1883, topic="mqttchat/demo/room1"):
    """Publish a series of test messages"""

    client = mqtt.Client(client_id=f"test_publisher_{int(time.time())}")
    client.on_connect = on_connect
    client.on_publish = on_publish

    print(f"🔗 Connecting to {host}:{port}...")
    client.connect(host, port, 60)
    client.loop_start()

    # Wait for connection
    time.sleep(1)

    # Test messages
    test_messages = [
        {
            "type": "text",
            "content": "Hello from test publisher! 👋",
            "qos": 1
        },
        {
            "type": "json",
            "content": json.dumps({
                "sensor": "test",
                "value": 42,
                "timestamp": datetime.now().isoformat()
            }),
            "qos": 1
        },
        {
            "type": "text",
            "content": "Testing QoS 0 (fire and forget)",
            "qos": 0
        },
        {
            "type": "text",
            "content": "Testing QoS 2 (exactly once)",
            "qos": 2
        },
        {
            "type": "text",
            "content": "This is a retained message 📌",
            "qos": 1,
            "retain": True
        }
    ]

    print(f"\n📨 Publishing to topic: {topic}\n")

    for i, msg in enumerate(test_messages, 1):
        content = msg["content"]
        qos = msg.get("qos", 1)
        retain = msg.get("retain", False)

        info = client.publish(topic, content, qos=qos, retain=retain)

        print(f"Message {i}:")
        print(f"  Content: {content[:50]}..." if len(content) > 50 else f"  Content: {content}")
        print(f"  QoS: {qos}, Retain: {retain}")
        print(f"  Status: {'Sent' if info.rc == mqtt.MQTT_ERR_SUCCESS else 'Failed'}")
        print()

        time.sleep(1)

    # Cleanup
    client.loop_stop()
    client.disconnect()
    print("✅ Test complete!")

def publish_custom_message(host, port, topic, message, qos=1, retain=False):
    """Publish a custom message"""

    client = mqtt.Client(client_id=f"custom_publisher_{int(time.time())}")
    client.on_connect = on_connect

    client.connect(host, port, 60)
    client.loop_start()

    time.sleep(1)

    info = client.publish(topic, message, qos=qos, retain=retain)

    if info.rc == mqtt.MQTT_ERR_SUCCESS:
        print(f"✅ Published: {message}")
        print(f"   Topic: {topic}")
        print(f"   QoS: {qos}, Retain: {retain}")
    else:
        print(f"❌ Failed to publish: {info.rc}")

    client.loop_stop()
    client.disconnect()

def subscribe_and_print(host, port, topic):
    """Subscribe to a topic and print messages"""

    def on_message(client, userdata, msg):
        timestamp = datetime.now().strftime("%H:%M:%S")
        print(f"[{timestamp}] {msg.topic}: {msg.payload.decode('utf-8')}")

    client = mqtt.Client(client_id=f"test_subscriber_{int(time.time())}")
    client.on_connect = on_connect
    client.on_message = on_message

    client.connect(host, port, 60)
    client.subscribe(topic, qos=1)

    print(f"📥 Subscribed to: {topic}")
    print("Press Ctrl+C to stop...\n")

    try:
        client.loop_forever()
    except KeyboardInterrupt:
        print("\n👋 Stopping subscriber...")
        client.disconnect()

def main():
    parser = argparse.ArgumentParser(description='MQTT Test Publisher')
    parser.add_argument('--host', default='localhost', help='MQTT broker host')
    parser.add_argument('--port', type=int, default=1883, help='MQTT broker port')
    parser.add_argument('--topic', default='mqttchat/demo/room1', help='Topic to publish to')
    parser.add_argument('--message', help='Custom message to send')
    parser.add_argument('--qos', type=int, default=1, choices=[0, 1, 2], help='QoS level')
    parser.add_argument('--retain', action='store_true', help='Set retain flag')
    parser.add_argument('--subscribe', action='store_true', help='Subscribe mode instead of publish')
    parser.add_argument('--test', action='store_true', help='Send test messages')

    args = parser.parse_args()

    print("🧪 MQTT Test Utility")
    print("=" * 40)

    if args.subscribe:
        subscribe_and_print(args.host, args.port, args.topic)
    elif args.message:
        publish_custom_message(args.host, args.port, args.topic, args.message, args.qos, args.retain)
    elif args.test:
        publish_test_messages(args.host, args.port, args.topic)
    else:
        # Default: send test messages
        publish_test_messages(args.host, args.port, args.topic)

if __name__ == "__main__":
    main()