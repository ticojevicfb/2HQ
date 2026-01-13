//
//  MockNetworkMonitor.swift
//  2HQ
//
//  Created by Nikola Ticojevic on 12. 1. 2026..
//

import Foundation
import Combine

class MockNetworkMonitor: NetworkMonitorProtocol {
    @Published private var _isConnected: Bool = true
    
    var isConnected: Bool { _isConnected }
    var connectionPublisher: AnyPublisher<Bool, Never> {
        $_isConnected.eraseToAnyPublisher()
    }
    
    func startMonitoring() { }
    
    // Helper method for testing
    func setConnected(_ connected: Bool) {
        _isConnected = connected
    }
}
