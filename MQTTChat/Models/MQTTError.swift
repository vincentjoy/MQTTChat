//
//  MQTTError.swift
//  MQTTChat
//
//  Created by Vincent Joy on 07/08/25.
//

import Foundation

enum MQTTError: LocalizedError {
    case initializationFailed
    case connectionFailed
    case subscriptionFailed
    
    var errorDescription: String? {
        switch self {
        case .initializationFailed:
            return "Failed to initialize MQTT client"
        case .connectionFailed:
            return "Failed to connect to broker"
        case .subscriptionFailed:
            return "Failed to subscribe to topic"
        }
    }
}
