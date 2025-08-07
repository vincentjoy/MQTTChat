//
//  MQTTConfiguration.swift
//  MQTTChat
//
//  Created by Vincent Joy on 07/08/25.
//

import Foundation

struct MQTTConfiguration: Codable, Sendable {
    var host: String = "test.mosquitto.org"
    var port: UInt16 = 1883
    var topic: String = "mqttchat/demo/room1"
    var clientId: String = UUID().uuidString
    var username: String = ""
    var password: String = ""
    var useTLS: Bool = false
    var useWebSocket: Bool = false
    var allowSelfSignedCerts: Bool = false
    var mqttVersion: MQTTVersion = .v5
    var qos: QoSLevel = .atLeastOnce
    var cleanSession: Bool = true
    var keepAlive: UInt16 = 60
    
    // Last Will and Testament
    var enableLWT: Bool = false
    var lwtTopic: String = ""
    var lwtMessage: String = ""
    var lwtQoS: QoSLevel = .atLeastOnce
    var lwtRetain: Bool = false
    
    // User Properties (MQTT v5)
    var userProperties: [String: String] = [:]
    
    enum MQTTVersion: String, Codable, CaseIterable {
        case v311 = "3.1.1"
        case v5 = "5.0"
        
        var protocolLevel: UInt8 {
            switch self {
            case .v311: return 4
            case .v5: return 5
            }
        }
    }
    
    enum QoSLevel: UInt8, Codable, CaseIterable {
        case atMostOnce = 0
        case atLeastOnce = 1
        case exactlyOnce = 2
        
        var description: String {
            switch self {
            case .atMostOnce: return "At Most Once (0)"
            case .atLeastOnce: return "At Least Once (1)"
            case .exactlyOnce: return "Exactly Once (2)"
            }
        }
    }
}
