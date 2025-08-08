//
//  ChatView.swift
//  MQTTChat
//
//  Created by Vincent Joy on 08/08/25.
//

import SwiftUI

struct ChatView: View {
    @EnvironmentObject var viewModel: ChatViewModel
    @State private var scrollProxy: ScrollViewProxy?
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Connection Status Bar
                ConnectionStatusView(state: viewModel.connectionState)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                
                // Messages List
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                        }
                        .padding()
                    }
                    .onAppear {
                        scrollProxy = proxy
                        scrollToBottom()
                    }
                    .onChange(of: viewModel.messages.count) { _, _ in
                        scrollToBottom()
                    }
                }
                
                Divider()
                
                // Message Input
                MessageInputView(
                    text: $viewModel.messageText,
                    isRetainEnabled: $viewModel.isRetainEnabled,
                    isConnected: viewModel.isConnected,
                    onSend: {
                        Task {
                            await viewModel.sendMessage()
                        }
                    }
                )
                .focused($isInputFocused)
                .padding()
            }
            .navigationTitle(viewModel.currentTopic)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: viewModel.clearMessages) {
                        Image(systemName: "trash")
                    }
                    .disabled(viewModel.messages.isEmpty)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: viewModel.toggleDebugConsole) {
                        Image(systemName: "terminal")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingDebugConsole) {
                DebugConsoleView(events: viewModel.events) {
                    viewModel.clearEvents()
                }
            }
        }
    }
    
    private func scrollToBottom() {
        guard let lastMessage = viewModel.messages.last else { return }
        withAnimation(.easeOut(duration: 0.2)) {
            scrollProxy?.scrollTo(lastMessage.id, anchor: .bottom)
        }
    }
}
