//
//  MockNetworkMonitor.swift
//  2HQTests
//
//  Created by Nikola Ticojevic on 12. 1. 2026..
//

import Foundation
import Combine
@testable import _HQ

class MockNetworkMonitor: NetworkMonitorProtocol {
    // Use CurrentValueSubject for reliable updates
    private let _isConnected = CurrentValueSubject<Bool, Never>(true)
    
    var isConnected: Bool {
        get { _isConnected.value }
        set {
            print("📡 MockNetworkMonitor: Setting isConnected to \(newValue)")
            _isConnected.send(newValue)
        }
    }
    
    var connectionPublisher: AnyPublisher<Bool, Never> {
        _isConnected.eraseToAnyPublisher()
    }
    
    func startMonitoring() {
        print("📡 MockNetworkMonitor: Started monitoring")
    }
}
