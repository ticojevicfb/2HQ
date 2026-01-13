//
//  NetworkMonitor.swift
//  2HQ
//
//  Created by Nikola Ticojevic on 12. 1. 2026..
//

import Foundation
import Network
import Combine

protocol NetworkMonitorProtocol {
    var isConnected: Bool { get }
    var connectionPublisher: AnyPublisher<Bool, Never> { get }
    func startMonitoring()
}

class NetworkMonitor: NetworkMonitorProtocol {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    @Published private var _isConnected: Bool = true
    var isConnected: Bool { _isConnected }
    
    var connectionPublisher: AnyPublisher<Bool, Never> {
        $_isConnected.eraseToAnyPublisher()
    }
    
    init() {
        startMonitoring()
    }
    
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?._isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
}
