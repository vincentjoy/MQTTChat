//
//  ConnectionState.swift
//  MQTTChat
//
//  Created by Vincent Joy on 07/08/25.
//

import Foundation

enum ConnectionState: String, Sendable {
    case disconnected = "Disconnected"
    case connecting = "Connecting..."
    case connected = "Connected"
    case disconnecting = "Disconnecting..."
    case reconnecting = "Reconnecting..."
    case error = "Error"
    
    var isConnected: Bool {
        self == .connected
    }
    
    var color: String {
        switch self {
        case .connected: return "green"
        case .disconnected: return "gray"
        case .connecting, .reconnecting: return "orange"
        case .disconnecting: return "yellow"
        case .error: return "red"
        }
    }
}
