//
//  MQTTService+ CocoaMQTTDelegate.swift
//  MQTTChat
//
//  Created by Vincent Joy on 08/08/25.
//

import Foundation
import CocoaMQTT
import Combine

extension MQTTService: CocoaMQTTDelegate {
    nonisolated func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        Task { @MainActor in
            if ack == .accept {
                connectionState = .connected
                reconnectAttempts = 0
                logEvent(.connection, message: "Connected successfully")
                await subscribe()
            } else {
                connectionState = .error
                logEvent(.error, message: "Connection rejected", details: "ACK: \(ack)")
            }
        }
    }
    
    nonisolated func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        Task { @MainActor in
            logEvent(.publish, message: "Message published", details: "ID: \(id)")
        }
    }
    
    nonisolated func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        Task { @MainActor in
            logEvent(.publish, message: "Publish acknowledged", details: "ID: \(id)")
        }
    }
    
    nonisolated func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
        Task { @MainActor in
            if let payload = message.string {
                handleReceivedMessage(topic: message.topic, payload: payload)
            }
        }
    }
    
    nonisolated func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopics success: NSDictionary, failed: [String]) {
        Task { @MainActor in
            if !success.allKeys.isEmpty {
                logEvent(.subscription, message: "Subscribed successfully", details: "Topics: \(success.allKeys)")
            }
            if !failed.isEmpty {
                logEvent(.error, message: "Subscription failed", details: "Topics: \(failed)")
            }
        }
    }
    
    nonisolated func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopics topics: [String]) {
        Task { @MainActor in
            logEvent(.subscription, message: "Unsubscribed", details: "Topics: \(topics)")
        }
    }
    
    nonisolated func mqttDidPing(_ mqtt: CocoaMQTT) {
        // Silent - too frequent for logging
    }
    
    nonisolated func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
        // Silent - too frequent for logging
    }
    
    nonisolated func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
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
}
