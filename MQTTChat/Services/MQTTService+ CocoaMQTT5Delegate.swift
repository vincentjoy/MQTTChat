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
    nonisolated func mqtt5(_ mqtt5: CocoaMQTT5, didConnectAck ack: CocoaMQTTCONNACKReasonCode, connAckData: MqttDecodeConnAck?) {
        Task { @MainActor in
            if ack == .success {
                connectionState = .connected
                reconnectAttempts = 0
                var details = "Reason: \(ack)"
                if let data = connAckData {
                    if let props = data.properties {
                        details += "\nServer keep alive: \(props.serverKeepAlive ?? 0)"
                        details += "\nMax packet size: \(props.maximumPacketSize ?? 0)"
                    }
                }
                logEvent(.connection, message: "Connected successfully (MQTT v5)", details: details)
                await subscribe()
            } else {
                connectionState = .error
                logEvent(.error, message: "Connection rejected", details: "Reason: \(ack)")
            }
        }
    }
    
    nonisolated func mqtt5(_ mqtt5: CocoaMQTT5, didPublishMessage message: CocoaMQTT5Message, id: UInt16) {
        Task { @MainActor in
            logEvent(.publish, message: "Message published (v5)", details: "ID: \(id)")
        }
    }
    
    nonisolated func mqtt5(_ mqtt5: CocoaMQTT5, didPublishAck id: UInt16, pubAckData: MqttDecodePubAck?) {
        Task { @MainActor in
            var details = "ID: \(id)"
            if let data = pubAckData {
                details += "\nReason: \(data.reasonCode)"
            }
            logEvent(.publish, message: "Publish acknowledged (v5)", details: details)
        }
    }
    
    nonisolated func mqtt5(_ mqtt5: CocoaMQTT5, didPublishRec id: UInt16, pubRecData: MqttDecodePubRec?) {
        Task { @MainActor in
            logEvent(.publish, message: "Publish received (QoS 2)", details: "ID: \(id)")
        }
    }
    
    nonisolated func mqtt5(_ mqtt5: CocoaMQTT5, didReceiveMessage message: CocoaMQTT5Message, id: UInt16, publishData: MqttDecodePublish?) {
        Task { @MainActor in
            if let payload = message.string {
                handleReceivedMessage(topic: message.topic, payload: payload)
                
                // Log MQTT v5 specific properties
                if let props = publishData?.properties {
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
    }
    
    nonisolated func mqtt5(_ mqtt5: CocoaMQTT5, didSubscribeTopics success: NSDictionary, failed: [String], subAckData: MqttDecodeSubAck?) {
        Task { @MainActor in
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
    }
    
    nonisolated func mqtt5(_ mqtt5: CocoaMQTT5, didUnsubscribeTopics topics: [String], unsubAckData: MqttDecodeUnsubAck?) {
        Task { @MainActor in
            var details = "Topics: \(topics)"
            if let data = unsubAckData {
                details += "\nReason codes: \(data.reasonCodes)"
            }
            logEvent(.subscription, message: "Unsubscribed (v5)", details: details)
        }
    }
    
    nonisolated func mqtt5DidPing(_ mqtt5: CocoaMQTT5) {
        // Silent - too frequent for logging
    }
    
    nonisolated func mqtt5DidReceivePong(_ mqtt5: CocoaMQTT5) {
        // Silent - too frequent for logging
    }
    
    nonisolated func mqtt5DidDisconnect(_ mqtt5: CocoaMQTT5, withError err: Error?) {
        Task { @MainActor in
            connectionState = .disconnected
            if let error = err {
                logEvent(.error, message: "Disconnected with error", details: error.localizedDescription)
                startReconnection()
            } else {
                logEvent(.connection, message: "Disconnected")
            }
        }
    }
    
    nonisolated func mqtt5(_ mqtt5: CocoaMQTT5, didReceiveDisconnectReasonCode reasonCode: CocoaMQTTDISCONNECTReasonCode) {
        Task { @MainActor in
            logEvent(.connection, message: "Disconnect reason (v5)", details: "Code: \(reasonCode)")
        }
    }
    
    nonisolated func mqtt5(_ mqtt5: CocoaMQTT5, didReceiveAuthReasonCode reasonCode: CocoaMQTTAUTHReasonCode) {
        Task { @MainActor in
            logEvent(.connection, message: "Auth reason (v5)", details: "Code: \(reasonCode)")
        }
    }
}
