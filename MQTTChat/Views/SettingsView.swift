//
//  SettingsView.swift
//  MQTTChat
//
//  Created by Vincent Joy on 08/08/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: SettingsViewModel
    
    var body: some View {
        NavigationStack {
            Form {
                // Connection Section
                Section("Connection") {
                    HStack {
                        Label("Status", systemImage: "network")
                        Spacer()
                        ConnectionStatusView(state: viewModel.connectionState)
                    }
                    
                    Button(action: {
                        Task {
                            await viewModel.connect()
                        }
                    }) {
                        HStack {
                            Image(systemName: viewModel.isConnected ? "stop.circle" : "play.circle")
                            Text(viewModel.isConnected ? "Disconnect" : "Connect")
                        }
                    }
                    .disabled(!viewModel.canConnect && !viewModel.isConnected)
                }
                
                // Broker Configuration
                Section("Broker Configuration") {
                    TextField("Host", text: $viewModel.configuration.host)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .disabled(viewModel.isConnected)
                    
                    HStack {
                        Text("Port")
                        Spacer()
                        TextField("Port", value: $viewModel.configuration.port, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                            .multilineTextAlignment(.trailing)
                            .disabled(viewModel.isConnected)
                    }
                    
                    TextField("Topic", text: $viewModel.configuration.topic)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .disabled(viewModel.isConnected)
                    
                    HStack {
                        Text("Client ID")
                        Spacer()
                        Button(action: viewModel.generateClientId) {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption)
                        }
                        .disabled(viewModel.isConnected)
                    }
                    
                    TextField("Client ID", text: $viewModel.configuration.clientId)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.caption)
                        .disabled(viewModel.isConnected)
                }
                
                // Authentication
                Section("Authentication") {
                    TextField("Username", text: $viewModel.configuration.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .disabled(viewModel.isConnected)
                    
                    SecureField("Password / Token", text: $viewModel.configuration.password)
                        .disabled(viewModel.isConnected)
                }
                
                // Transport & Security
                Section("Transport & Security") {
                    Toggle("Use TLS/SSL", isOn: $viewModel.configuration.useTLS)
                        .disabled(viewModel.isConnected)
                        .onChange(of: viewModel.configuration.useTLS) { _, newValue in
                            viewModel.updatePort(for: newValue, useWebSocket: viewModel.configuration.useWebSocket)
                        }
                    
                    Toggle("Use WebSocket", isOn: $viewModel.configuration.useWebSocket)
                        .disabled(viewModel.isConnected)
                        .onChange(of: viewModel.configuration.useWebSocket) { _, newValue in
                            viewModel.updatePort(for: viewModel.configuration.useTLS, useWebSocket: newValue)
                        }
                    
                    if viewModel.configuration.useWebSocket {
                        Text("URL: \(viewModel.webSocketURL)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Toggle("Allow Self-Signed Certificates", isOn: $viewModel.configuration.allowSelfSignedCerts)
                        .disabled(!viewModel.configuration.useTLS || viewModel.isConnected)
                }
                
                // MQTT Options
                Section("MQTT Options") {
                    Picker("MQTT Version", selection: $viewModel.configuration.mqttVersion) {
                        ForEach(MQTTConfiguration.MQTTVersion.allCases, id: \.self) { version in
                            Text(version.rawValue).tag(version)
                        }
                    }
                    .disabled(viewModel.isConnected)
                    
                    Picker("QoS Level", selection: $viewModel.configuration.qos) {
                        ForEach(MQTTConfiguration.QoSLevel.allCases, id: \.self) { qos in
                            Text(qos.description).tag(qos)
                        }
                    }
                    
                    Toggle("Clean Session", isOn: $viewModel.configuration.cleanSession)
                        .disabled(viewModel.isConnected)
                    
                    HStack {
                        Text("Keep Alive (seconds)")
                        Spacer()
                        TextField("60", value: $viewModel.configuration.keepAlive, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 60)
                            .multilineTextAlignment(.trailing)
                            .disabled(viewModel.isConnected)
                    }
                }
                
                // Advanced Settings
                Section("Advanced") {
                    // Last Will and Testament
                    DisclosureGroup("Last Will and Testament", isExpanded: $viewModel.showingLWTSettings) {
                        Toggle("Enable LWT", isOn: $viewModel.configuration.enableLWT)
                            .disabled(viewModel.isConnected)
                        
                        if viewModel.configuration.enableLWT {
                            TextField("LWT Topic", text: $viewModel.configuration.lwtTopic)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .disabled(viewModel.isConnected)
                            
                            TextField("LWT Message", text: $viewModel.configuration.lwtMessage)
                                .disabled(viewModel.isConnected)
                            
                            Picker("LWT QoS", selection: $viewModel.configuration.lwtQoS) {
                                ForEach(MQTTConfiguration.QoSLevel.allCases, id: \.self) { qos in
                                    Text(qos.description).tag(qos)
                                }
                            }
                            .disabled(viewModel.isConnected)
                            
                            Toggle("LWT Retain", isOn: $viewModel.configuration.lwtRetain)
                                .disabled(viewModel.isConnected)
                        }
                    }
                    
                    // User Properties (MQTT v5)
                    if viewModel.configuration.mqttVersion == .v5 {
                        DisclosureGroup("User Properties", isExpanded: $viewModel.showingUserProperties) {
                            ForEach(Array(viewModel.configuration.userProperties.keys), id: \.self) { key in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(key)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                        Text(viewModel.configuration.userProperties[key] ?? "")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Button(action: {
                                        viewModel.removeUserProperty(key: key)
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                    .disabled(viewModel.isConnected)
                                }
                            }
                            
                            HStack {
                                TextField("Key", text: $viewModel.newPropertyKey)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                TextField("Value", text: $viewModel.newPropertyValue)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                Button(action: viewModel.addUserProperty) {
                                    Image(systemName: "plus.circle.fill")
                                }
                                .disabled(viewModel.newPropertyKey.isEmpty || viewModel.newPropertyValue.isEmpty || viewModel.isConnected)
                            }
                        }
                    }
                }
                
                // Actions
                Section {
                    Button(action: viewModel.resetToDefaults) {
                        Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
                    }
                    .disabled(viewModel.isConnected)
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}
