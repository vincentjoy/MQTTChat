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
    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        if ack == .accept {
            connectionState = .connected
            reconnectAttempts = 0
            logEvent(.connection, message: "Connected successfully")
            Task {
                await subscribe()
            }
        } else {
            connectionState = .error
            logEvent(.error, message: "Connection rejected", details: "ACK: \(ack)")
        }
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        logEvent(.publish, message: "Message published", details: "ID: \(id)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        logEvent(.publish, message: "Publish acknowledged", details: "ID: \(id)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
        if let payload = message.string {
            handleReceivedMessage(topic: message.topic, payload: payload)
        }
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopics success: NSDictionary, failed: [String]) {
        if !success.allKeys.isEmpty {
            logEvent(.subscription, message: "Subscribed successfully", details: "Topics: \(success.allKeys)")
        }
        if !failed.isEmpty {
            logEvent(.error, message: "Subscription failed", details: "Topics: \(failed)")
        }
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopics topics: [String]) {
        logEvent(.subscription, message: "Unsubscribed", details: "Topics: \(topics)")
    }
    
    func mqttDidPing(_ mqtt: CocoaMQTT) {
        // Silent - too frequent for logging
    }
    
    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
        // Silent - too frequent for logging
    }
    
    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        connectionState = .disconnected
        if let error = err {
            logEvent(.error, message: "Disconnected with error", details: error.localizedDescription)
            startReconnection()
        } else {
            logEvent(.connection, message: "Disconnected")
        }
    }
}
