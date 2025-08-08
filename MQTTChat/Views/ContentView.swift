//
//  ContentView.swift
//  MQTTChat
//
//  Created by Vincent Joy on 07/08/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var mqttService: MQTTService
    @EnvironmentObject var chatViewModel: ChatViewModel
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    
    var body: some View {
        TabView {
            ChatView()
                .tabItem {
                    Label("Chat", systemImage: "message")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

#Preview {
    ContentView()
}
