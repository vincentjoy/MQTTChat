//
//  Untitled.swift
//  MQTTChat
//
//  Created by Vincent Joy on 08/08/25.
//

import Foundation
import CocoaMQTT
import Combine

extension MQTTService: CocoaMQTT5Delegate {
    func mqtt5(_ mqtt5: CocoaMQTT5, didConnectAck ack: CocoaMQTTCONNACKReasonCode, connAckData: MqttDecodeConnAck?) {
        if ack == .success {
            connectionState = .connected
            reconnectAttempts = 0
            var details = "Reason: \(ack)"
            if let data = connAckData {
                details += "\nServer keep alive: \(data.serverKeepAlive ?? 0)"
                details += "\nMax packet size: \(data.maximumPacketSize ?? 0)"
            }
            logEvent(.connection, message: "Connected successfully (MQTT v5)", details: details)
            Task {
                await subscribe()
            }
        } else {
            connectionState = .error
            logEvent(.error, message: "Connection rejected", details: "Reason: \(ack)")
        }
    }
    
    func mqtt5(_ mqtt5: CocoaMQTT5, didPublishMessage message: CocoaMQTT5Message, id: UInt16) {
        logEvent(.publish, message: "Message published (v5)", details: "ID: \(id)")
    }
    
    func mqtt5(_ mqtt5: CocoaMQTT5, didPublishAck id: UInt16, pubAckData: MqttDecodePubAck?) { // Broker received the published message
        var details = "ID: \(id)"
        if let data = pubAckData {
            details += "\nReason: \(data.reasonCode ?? .unspecifiedError)"
        }
        logEvent(.publish, message: "Publish acknowledged (v5)", details: details)
    }
    
    func mqtt5(_ mqtt5: CocoaMQTT5, didPublishRec id: UInt16, pubRecData: MqttDecodePubRec?) { // Client received the published message
        logEvent(.publish, message: "Publish received (QoS 2)", details: "ID: \(id)")
    }
    
    func mqtt5(_ mqtt5: CocoaMQTT5, didReceiveMessage message: CocoaMQTT5Message, id: UInt16, publishData: MqttDecodePublish?) {
        if let payload = message.string {
            handleReceivedMessage(topic: message.topic, payload: payload)
            
            // Log MQTT v5 specific properties
            if let props = publishData {
                var details = "Topic: \(message.topic)"
                if let userProps = props.userProperty {
                    details += "\nUser Properties: \(userProps)"
                }
                if let contentType = props.contentType {
                    details += "\nContent Type: \(contentType)"
                }
                logEvent(.receive, message: "Message properties (v5)", details: details)
            }
        }
    }
    
    func mqtt5(_ mqtt5: CocoaMQTT5, didSubscribeTopics success: NSDictionary, failed: [String], subAckData: MqttDecodeSubAck?) {
        if !success.allKeys.isEmpty {
            var details = "Topics: \(success.allKeys)"
            if let data = subAckData {
                details += "\nReason codes: \(data.reasonCodes)"
            }
            logEvent(.subscription, message: "Subscribed successfully (v5)", details: details)
        }
        if !failed.isEmpty {
            logEvent(.error, message: "Subscription failed", details: "Topics: \(failed)")
        }
    }
    
    func mqtt5(_ mqtt5: CocoaMQTT5, didUnsubscribeTopics topics: [String], UnsubAckData unsubAckData: MqttDecodeUnsubAck?) {
        var details = "Topics: \(topics)"
        if let data = unsubAckData {
            details += "\nReason codes: \(data.reasonCodes)"
        }
        logEvent(.subscription, message: "Unsubscribed (v5)", details: details)
    }
    
    func mqtt5DidPing(_ mqtt5: CocoaMQTT5) {
        // Silent - too frequent for logging
        // Client sent a PINGREQ message to broker - as part of the keep-alive mechanism to ensure the connection between the client and broker remains active
    }
    
    func mqtt5DidReceivePong(_ mqtt5: CocoaMQTT5) {
        // Silent - too frequent for logging
        // A PONG message is sent by the client in response to a PINGREQ (Ping Request) message from the broker, confirming that the connection is still alive. This function is part of the standard MQTT keep-alive mechanism.
    }
    
    func mqtt5DidDisconnect(_ mqtt5: CocoaMQTT5, withError err: Error?) {
        connectionState = .disconnected
        if let error = err {
            logEvent(.error, message: "Disconnected with error", details: error.localizedDescription)
            startReconnection()
        } else {
            logEvent(.connection, message: "Disconnected")
        }
    }
    
    func mqtt5(_ mqtt5: CocoaMQTT5, didReceiveDisconnectReasonCode reasonCode: CocoaMQTTDISCONNECTReasonCode) {
        logEvent(.connection, message: "Disconnect reason (v5)", details: "Code: \(reasonCode)")
    }
    
    func mqtt5(_ mqtt5: CocoaMQTT5, didReceiveAuthReasonCode reasonCode: CocoaMQTTAUTHReasonCode) {
        logEvent(.connection, message: "Auth reason (v5)", details: "Code: \(reasonCode)")
    }
}
