//
//  MQTTService.swift
//  MQTTChat
//
//  Created by Vincent Joy on 08/08/25.
//

import Foundation
import CocoaMQTT
import Combine
import CocoaMQTTWebSocket

final class MQTTService: ObservableObject {
    @Published var connectionState: ConnectionState = .disconnected
    @Published private(set) var messages: [Message] = []
    @Published private(set) var events: [MQTTEvent] = []
    @Published var configuration = MQTTConfiguration()
    
    var reconnectAttempts = 0
    private var mqtt: CocoaMQTT?
    private var mqtt5: CocoaMQTT5?
    private var reconnectTask: Task<Void, Never>?
    private let maxReconnectAttempts = 10
    private let cancellables = Set<AnyCancellable>()
    
    // Network monitoring
    private let networkMonitor = NetworkMonitor()
    
    init() {
        setupNetworkMonitoring()
    }
    
    deinit {
        reconnectTask?.cancel()
        disconnect()
    }
    
    // MARK: - Public Methods
    
    func connect() async {
        await MainActor.run {
            connectionState = .connecting
        }
        
        logEvent(.connection, message: "Initiating connection to \(configuration.host):\(configuration.port)")
        
        do {
            if configuration.mqttVersion == .v5 {
                try await connectMQTT5()
            } else {
                try await connectMQTT311()
            }
        } catch {
            await MainActor.run {
                connectionState = .error
                logEvent(.error, message: "Connection failed", details: error.localizedDescription)
            }
        }
    }
    
    func disconnect() {
        reconnectTask?.cancel()
        reconnectTask = nil
        reconnectAttempts = 0
        
        if configuration.mqttVersion == .v5 {
            mqtt5?.disconnect()
        } else {
            mqtt?.disconnect()
        }
        
        connectionState = .disconnected
        logEvent(.connection, message: "Disconnected from broker")
    }
    
    func publish(_ content: String, retain: Bool = false) async {
        guard connectionState == .connected else {
            logEvent(.error, message: "Cannot publish: Not connected")
            return
        }
        
        let message = Message(
            content: content,
            topic: configuration.topic,
            sender: configuration.username.isEmpty ? "Me" : configuration.username,
            isOutgoing: true,
            qos: configuration.qos.rawValue,
            isRetained: retain
        )
        
        messages.append(message)
        
        if configuration.mqttVersion == .v5 {
            let msg = CocoaMQTT5Message(
                topic: configuration.topic,
                string: content,
                qos: CocoaMQTTQoS(rawValue: configuration.qos.rawValue) ?? .qos1
            )
            msg.retained = retain
            
            // Add user properties for MQTT v5
            let properties = MqttPublishProperties()
            if !configuration.userProperties.isEmpty {
                properties.userProperty = configuration.userProperties
            }
            
            mqtt5?.publish(msg, properties: properties)
        } else {
            let mqttMessage = CocoaMQTTMessage(
                topic: configuration.topic,
                string: content,
                qos: CocoaMQTTQoS(rawValue: configuration.qos.rawValue) ?? .qos1,
                retained: retain
            )
            mqtt?.publish(mqttMessage)
        }
        
        logEvent(.publish, message: "Published to \(configuration.topic)", details: "QoS: \(configuration.qos.rawValue), Retained: \(retain)")
    }
    
    func subscribe() async {
        guard connectionState == .connected else { return }
        
        if configuration.mqttVersion == .v5 {
            mqtt5?.subscribe(configuration.topic, qos: CocoaMQTTQoS(rawValue: configuration.qos.rawValue) ?? .qos1)
        } else {
            mqtt?.subscribe(configuration.topic, qos: CocoaMQTTQoS(rawValue: configuration.qos.rawValue) ?? .qos1)
        }
        
        logEvent(.subscription, message: "Subscribed to \(configuration.topic)")
    }
    
    func unsubscribe() async {
        guard connectionState == .connected else { return }
        
        if configuration.mqttVersion == .v5 {
            mqtt5?.unsubscribe(configuration.topic)
        } else {
            mqtt?.unsubscribe(configuration.topic)
        }
        
        logEvent(.subscription, message: "Unsubscribed from \(configuration.topic)")
    }
    
    func clearMessages() {
        messages.removeAll()
    }
    
    func clearEvents() {
        events.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func connectMQTT311() async throws {
        let clientID = configuration.clientId.isEmpty ? UUID().uuidString : configuration.clientId
        
        if configuration.useWebSocket {
            mqtt = CocoaMQTT(
                clientID: clientID,
                host: configuration.host,
                port: configuration.port,
                socket: CocoaMQTTWebSocket()
            )
        } else {
            mqtt = CocoaMQTT(
                clientID: clientID,
                host: configuration.host,
                port: configuration.port
            )
        }
        
        guard let mqtt = mqtt else { throw MQTTError.initializationFailed }
        
        configureMQTT311(mqtt)
        
        // Set delegate
        mqtt.delegate = self
        
        // Connect
        let connected = mqtt.connect()
        if !connected {
            throw MQTTError.connectionFailed
        }
    }
    
    private func connectMQTT5() async throws {
        let clientID = configuration.clientId.isEmpty ? UUID().uuidString : configuration.clientId
        
        if configuration.useWebSocket {
            mqtt5 = CocoaMQTT5(
                clientID: clientID,
                host: configuration.host,
                port: configuration.port,
                socket: CocoaMQTTWebSocket()
            )
        } else {
            mqtt5 = CocoaMQTT5(
                clientID: clientID,
                host: configuration.host,
                port: configuration.port
            )
        }
        
        guard let mqtt5 = mqtt5 else { throw MQTTError.initializationFailed }
        
        configureMQTT5(mqtt5)
        
        // Set delegate
        mqtt5.delegate = self
        
        // Set connect properties for MQTT v5
        let connectProperties = MqttConnectProperties()
        connectProperties.sessionExpiryInterval = 3600
        connectProperties.receiveMaximum = 100
        connectProperties.maximumPacketSize = 65535
        
        // Add user properties
        if !configuration.userProperties.isEmpty {
            connectProperties.userProperties = configuration.userProperties
        }
        
        mqtt5.connectProperties = connectProperties
        
        // Connect
        let connected = mqtt5.connect()
        if !connected {
            throw MQTTError.connectionFailed
        }
    }
    
    private func configureMQTT311(_ mqtt: CocoaMQTT) {
        mqtt.username = configuration.username.isEmpty ? nil : configuration.username
        mqtt.password = configuration.password.isEmpty ? nil : configuration.password
        mqtt.keepAlive = configuration.keepAlive
        mqtt.cleanSession = configuration.cleanSession
        mqtt.autoReconnect = false // We'll handle reconnection manually
        
        // Configure transport
        mqtt.enableSSL = configuration.useTLS
        
        // Allow self-signed certificates
        if configuration.allowSelfSignedCerts {
            mqtt.allowUntrustCACertificate = true
        }
        
        // Configure Last Will and Testament
        if configuration.enableLWT && !configuration.lwtTopic.isEmpty {
            mqtt.willMessage = CocoaMQTTMessage(
                topic: configuration.lwtTopic,
                string: configuration.lwtMessage,
                qos: CocoaMQTTQoS(rawValue: configuration.lwtQoS.rawValue) ?? .qos1,
                retained: configuration.lwtRetain
            )
        }
    }
    
    private func configureMQTT5(_ mqtt5: CocoaMQTT5) {
        mqtt5.username = configuration.username.isEmpty ? nil : configuration.username
        mqtt5.password = configuration.password.isEmpty ? nil : configuration.password
        mqtt5.keepAlive = configuration.keepAlive
        mqtt5.cleanSession = configuration.cleanSession
        mqtt5.autoReconnect = false // We'll handle reconnection manually
        
        // Configure transport
        mqtt5.enableSSL = configuration.useTLS
        
        // Allow self-signed certificates
        if configuration.allowSelfSignedCerts {
            mqtt5.allowUntrustCACertificate = true
        }
        
        if configuration.enableLWT && !configuration.lwtTopic.isEmpty {
            let willMessage = CocoaMQTT5Message(
                topic: configuration.lwtTopic,
                string: configuration.lwtMessage,
                qos: CocoaMQTTQoS(rawValue: configuration.lwtQoS.rawValue) ?? .qos1
            )
            willMessage.willDelayInterval = 10
            willMessage.retained = configuration.lwtRetain
            
            mqtt5.willMessage = willMessage
        }
    }
    
    private func setupNetworkMonitoring() {
        Task {
            for await isConnected in networkMonitor.isConnected.values {
                if isConnected && connectionState == .disconnected && reconnectAttempts > 0 {
                    // Network is back, try to reconnect
                    await attemptReconnection()
                }
            }
        }
    }
    
    func startReconnection() {
        guard reconnectTask == nil else { return }
        
        reconnectTask = Task {
            await attemptReconnection()
        }
    }
    
    private func attemptReconnection() async {
        guard reconnectAttempts < maxReconnectAttempts else {
            connectionState = .error
            logEvent(.error, message: "Max reconnection attempts reached")
            return
        }
        
        connectionState = .reconnecting
        reconnectAttempts += 1
        
        // Exponential backoff
        let delay = UInt64(min(pow(2.0, Double(reconnectAttempts)), 60.0)) * 1_000_000_000
        try? await Task.sleep(nanoseconds: delay)
        
        if !Task.isCancelled {
            await connect()
        }
    }
    
    func logEvent(_ type: MQTTEvent.EventType, message: String, details: String? = nil) {
        let event = MQTTEvent(type: type, message: message, details: details)
        events.insert(event, at: 0)
        
        // Keep only last 100 events
        if events.count > 100 {
            events = Array(events.prefix(100))
        }
        
        // Can log using analytics SDKs later
        // Since this is a demo app, that implementation is omitted (for now)
    }
    
    func handleReceivedMessage(topic: String, payload: String) {
        let message = Message(
            content: payload,
            topic: topic,
            sender: "Remote",
            isOutgoing: false,
            qos: configuration.qos.rawValue,
            isRetained: false
        )
        
        messages.append(message)
        logEvent(.receive, message: "Received from \(topic)", details: payload)
    }
}
