//
//  NetworkMonitor.swift
//  MQTTChat
//
//  Created by Vincent Joy on 07/08/25.
//

import Foundation
import Network
import Combine

@MainActor
final class NetworkMonitor: ObservableObject {
    @Published private(set) var isConnected = CurrentValueSubject<Bool, Never>(true)
    @Published private(set) var connectionType: ConnectionType = .unknown
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    enum ConnectionType: String {
        case wifi = "WiFi"
        case cellular = "Cellular"
        case ethernet = "Ethernet"
        case unknown = "Unknown"
        case none = "None"
    }
    
    init() {
        startMonitoring()
    }
    
    deinit {
        monitor.cancel()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                let wasConnected = self.isConnected.value
                let isNowConnected = path.status == .satisfied
                
                self.isConnected.send(isNowConnected)
                
                // Update connection type
                if path.usesInterfaceType(.wifi) {
                    self.connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self.connectionType = .cellular
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self.connectionType = .ethernet
                } else if path.status == .satisfied {
                    self.connectionType = .unknown
                } else {
                    self.connectionType = .none
                }
                
                // Log significant changes
                if wasConnected != isNowConnected {
                    print("Network status changed: \(isNowConnected ? "Connected" : "Disconnected") via \(self.connectionType.rawValue)")
                }
            }
        }
        
        monitor.start(queue: queue)
    }
}
