//
//  APIClient.swift
//  2HQ
//
//  Created by Nikola Ticojevic on 12. 1. 2026..
//

import Foundation

protocol APIClientProtocol {
    func fetch<T: Decodable>(_ endpoint: Endpoint, expecting type: T.Type) async throws -> T
}

class APIClient: APIClientProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder
    
    init(session: URLSession = .shared, decoder: JSONDecoder = JSONDecoder()) {
        self.session = session
        self.decoder = decoder
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
    }
    
    func fetch<T: Decodable>(_ endpoint: Endpoint, expecting type: T.Type) async throws -> T {
        let request = try endpoint.urlRequest()
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.init(rawValue: httpResponse.statusCode))
        }
        
        return try decoder.decode(type, from: data)
    }
}

// For request cancellation
actor RequestManager {
    private var tasks: [String: AnyCancellableTask] = [:]
    
    func perform<T>(key: String, operation: @escaping () async throws -> T) async throws -> T {
        // Cancel existing task with same key
        tasks[key]?.cancel()
        tasks.removeValue(forKey: key)
        
        // Create and store the task
        let task = Task {
            try await operation()
        }
        
        // Store with type erasure
        tasks[key] = AnyCancellableTask(task)
        
        do {
            let result = try await task.value
            tasks.removeValue(forKey: key)
            return result
        } catch {
            tasks.removeValue(forKey: key)
            throw error
        }
    }
    
    func cancel(key: String) {
        tasks[key]?.cancel()
        tasks.removeValue(forKey: key)
    }
    
    func cancelAll() {
        for task in tasks.values {
            task.cancel()
        }
        tasks.removeAll()
    }
}

// Helper for type erasure
private class AnyCancellableTask {
    private let _cancel: () -> Void
    
    init<T>(_ task: Task<T, Error>) {
        _cancel = { task.cancel() }
    }
    
    func cancel() {
        _cancel()
    }
}
