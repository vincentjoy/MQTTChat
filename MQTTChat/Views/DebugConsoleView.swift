//
//  DebugConsoleView.swift
//  MQTTChat
//
//  Created by Vincent Joy on 08/08/25.
//

import SwiftUI

struct DebugConsoleView: View {
    let events: [MQTTEvent]
    let onClear: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List(events) { event in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: event.type.iconName)
                            .foregroundColor(colorForEventType(event.type))
                            .frame(width: 20)
                        
                        Text(event.type.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(colorForEventType(event.type))
                        
                        Spacer()
                        
                        Text(formatTime(event.timestamp))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(event.message)
                        .font(.system(.caption, design: .monospaced))
                    
                    if let details = event.details {
                        Text(details)
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                    }
                }
                .padding(.vertical, 4)
            }
            .listStyle(PlainListStyle())
            .navigationTitle("Debug Console")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear", action: onClear)
                        .disabled(events.isEmpty)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func colorForEventType(_ type: MQTTEvent.EventType) -> Color {
        switch type {
        case .connection: return .green
        case .subscription: return .blue
        case .publish: return .orange
        case .receive: return .purple
        case .error: return .red
        case .debug: return .gray
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}
