//
//  Message.swift
//  MQTTChat
//
//  Created by Vincent Joy on 07/08/25.
//

import Foundation

struct Message: Identifiable, Codable, Sendable {
    let id: UUID
    let content: String
    let topic: String
    let sender: String
    let timestamp: Date
    let isOutgoing: Bool
    let qos: UInt8
    let isRetained: Bool
    
    init(
        id: UUID = UUID(),
        content: String,
        topic: String,
        sender: String,
        timestamp: Date = Date(),
        isOutgoing: Bool,
        qos: UInt8 = 1,
        isRetained: Bool = false
    ) {
        self.id = id
        self.content = content
        self.topic = topic
        self.sender = sender
        self.timestamp = timestamp
        self.isOutgoing = isOutgoing
        self.qos = qos
        self.isRetained = isRetained
    }
}
