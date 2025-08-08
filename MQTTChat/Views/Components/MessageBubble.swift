//
//  MessageBubble.swift
//  MQTTChat
//
//  Created by Vincent Joy on 08/08/25.
//

import SwiftUI

struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isOutgoing { Spacer() }
            
            VStack(alignment: message.isOutgoing ? .trailing : .leading, spacing: 4) {
                // Sender and metadata
                HStack(spacing: 4) {
                    Text(message.sender)
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    if message.isRetained {
                        Image(systemName: "pin.fill")
                            .font(.caption2)
                    }
                    
                    Text("QoS \(message.qos)")
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(4)
                }
                .foregroundColor(.secondary)
                
                // Message content
                Text(message.content)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        message.isOutgoing ?
                        Color.blue : Color(UIColor.systemGray5)
                    )
                    .foregroundColor(
                        message.isOutgoing ? .white : .primary
                    )
                    .cornerRadius(16)
                
                // Timestamp
                Text(formatTime(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: message.isOutgoing ? .trailing : .leading)
            
            if !message.isOutgoing { Spacer() }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
