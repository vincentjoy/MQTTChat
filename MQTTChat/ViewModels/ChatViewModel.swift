//
//  ChatViewModel.swift
//  MQTTChat
//
//  Created by Vincent Joy on 08/08/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messageText: String = ""
    @Published var isRetainEnabled: Bool = false
    @Published var showingDebugConsole: Bool = false
    
    private let mqttService: MQTTService
    private var cancellables = Set<AnyCancellable>()
    
    var messages: [Message] {
        mqttService.messages
    }
    
    var events: [MQTTEvent] {
        mqttService.events
    }
    
    var connectionState: ConnectionState {
        mqttService.connectionState
    }
    
    var isConnected: Bool {
        mqttService.connectionState == .connected
    }
    
    var currentTopic: String {
        mqttService.configuration.topic
    }
    
    init(mqttService: MQTTService) {
        self.mqttService = mqttService
        setupBindings()
    }
    
    private func setupBindings() {
        // Observe MQTT service changes
        mqttService.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    func sendMessage() async {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let message = messageText
        messageText = ""
        
        await mqttService.publish(message, retain: isRetainEnabled)
    }
    
    func clearMessages() {
        mqttService.clearMessages()
    }
    
    func clearEvents() {
        mqttService.clearEvents()
    }
    
    func toggleDebugConsole() {
        showingDebugConsole.toggle()
    }
    
    func formatMessageTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    func formatEventTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}
