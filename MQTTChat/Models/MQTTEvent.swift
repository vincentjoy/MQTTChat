//
//  MQTTEvent.swift
//  MQTTChat
//
//  Created by Vincent Joy on 07/08/25.
//

import Foundation

struct MQTTEvent: Identifiable, Sendable {
    let id = UUID()
    let timestamp: Date
    let type: EventType
    let message: String
    let details: String?
    
    enum EventType: String, Sendable {
        case connection = "Connection"
        case subscription = "Subscription"
        case publish = "Publish"
        case receive = "Receive"
        case error = "Error"
        case debug = "Debug"
        
        var iconName: String {
            switch self {
            case .connection: return "network"
            case .subscription: return "bell"
            case .publish: return "arrow.up.circle"
            case .receive: return "arrow.down.circle"
            case .error: return "exclamationmark.triangle"
            case .debug: return "ant.circle"
            }
        }
    }
    
    init(type: EventType, message: String, details: String? = nil) {
        self.timestamp = Date()
        self.type = type
        self.message = message
        self.details = details
    }
}
