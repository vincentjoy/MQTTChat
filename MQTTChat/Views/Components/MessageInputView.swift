//
//  MessageInputView.swift
//  MQTTChat
//
//  Created by Vincent Joy on 08/08/25.
//

import SwiftUI

struct MessageInputView: View {
    @Binding var text: String
    @Binding var isRetainEnabled: Bool
    let isConnected: Bool
    let onSend: () -> Void
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            // Retain toggle
            Button(action: { isRetainEnabled.toggle() }) {
                Image(systemName: isRetainEnabled ? "pin.fill" : "pin")
                    .foregroundColor(isRetainEnabled ? .blue : .secondary)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Text field
            TextField("Type a message...", text: $text, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(1...5)
                .disabled(!isConnected)
                .onSubmit {
                    if !text.isEmpty && isConnected {
                        onSend()
                    }
                }
            
            // Send button
            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundColor(canSend ? .blue : .gray)
            }
            .disabled(!canSend)
        }
    }
    
    private var canSend: Bool {
        isConnected && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
