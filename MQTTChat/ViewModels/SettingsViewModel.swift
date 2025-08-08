//
//  SettingsViewModel.swift
//  MQTTChat
//
//  Created by Vincent Joy on 08/08/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var configuration: MQTTConfiguration
    @Published var showingAdvancedSettings: Bool = false
    @Published var showingLWTSettings: Bool = false
    @Published var showingUserProperties: Bool = false
    @Published var newPropertyKey: String = ""
    @Published var newPropertyValue: String = ""
    
    private let mqttService: MQTTService
    private var cancellables = Set<AnyCancellable>()
    private let userDefaults = UserDefaults.standard
    private let configurationKey = "MQTTConfiguration"
    
    var connectionState: ConnectionState {
        mqttService.connectionState
    }
    
    var isConnected: Bool {
        mqttService.connectionState == .connected
    }
    
    var canConnect: Bool {
        !configuration.host.isEmpty && configuration.port > 0 && !configuration.topic.isEmpty
    }
    
    // Computed property for WebSocket URL
    var webSocketURL: String {
        if configuration.useWebSocket {
            let scheme = configuration.useTLS ? "wss" : "ws"
            return "\(scheme)://\(configuration.host):\(configuration.port)/mqtt"
        }
        return ""
    }
    
    init(mqttService: MQTTService) {
        self.mqttService = mqttService
        self.configuration = mqttService.configuration
        setupBindings()
    }
    
    private func setupBindings() {
        // Sync configuration changes to service
        $configuration
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] config in
                self?.mqttService.configuration = config
                self?.saveSettings()
            }
            .store(in: &cancellables)
        
        // Observe connection state changes
        mqttService.$connectionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    func connect() async {
        if isConnected {
            mqttService.disconnect()
        } else {
            await mqttService.connect()
        }
    }
    
    func loadSavedSettings() async {
        if let data = userDefaults.data(forKey: configurationKey),
           let savedConfig = try? JSONDecoder().decode(MQTTConfiguration.self, from: data) {
            configuration = savedConfig
            mqttService.configuration = savedConfig
        }
    }
    
    func saveSettings() {
        if let data = try? JSONEncoder().encode(configuration) {
            userDefaults.set(data, forKey: configurationKey)
        }
    }
    
    func resetToDefaults() {
        configuration = MQTTConfiguration()
        mqttService.configuration = configuration
        saveSettings()
    }
    
    func addUserProperty() {
        guard !newPropertyKey.isEmpty && !newPropertyValue.isEmpty else { return }
        configuration.userProperties[newPropertyKey] = newPropertyValue
        newPropertyKey = ""
        newPropertyValue = ""
    }
    
    func removeUserProperty(key: String) {
        configuration.userProperties.removeValue(forKey: key)
    }
    
    func updatePort(for useTLS: Bool, useWebSocket: Bool) {
        if useWebSocket {
            configuration.port = useTLS ? 8081 : 8080
        } else {
            configuration.port = useTLS ? 8883 : 1883
        }
    }
    
    func generateClientId() {
        configuration.clientId = UUID().uuidString
    }
    
    // Validation
    func validateHost() -> Bool {
        !configuration.host.isEmpty && (
            configuration.host.contains(".") ||
            configuration.host == "localhost" ||
            configuration.host.range(of: #"^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$"#, options: .regularExpression) != nil
        )
    }
    
    func validatePort() -> Bool {
        configuration.port > 0 && configuration.port <= 65535
    }
    
    func validateTopic() -> Bool {
        !configuration.topic.isEmpty && !configuration.topic.contains(" ")
    }
}
