//
//  MQTTChatApp.swift
//  MQTTChat
//
//  Created by Vincent Joy on 07/08/25.
//

import SwiftUI

@main
struct MQTTChatApp: App {
    @StateObject private var mqttService = MQTTService()
    @StateObject private var chatViewModel: ChatViewModel
    @StateObject private var settingsViewModel: SettingsViewModel
    
    init() {
        let service = MQTTService()
        let chatVM = ChatViewModel(mqttService: service)
        let settingsVM = SettingsViewModel(mqttService: service)
        
        _mqttService = StateObject(wrappedValue: service)
        _chatViewModel = StateObject(wrappedValue: chatVM)
        _settingsViewModel = StateObject(wrappedValue: settingsVM)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(mqttService)
                .environmentObject(chatViewModel)
                .environmentObject(settingsViewModel)
                .onAppear {
                    Task {
                        await settingsViewModel.loadSavedSettings()
                    }
                }
        }
    }
}
