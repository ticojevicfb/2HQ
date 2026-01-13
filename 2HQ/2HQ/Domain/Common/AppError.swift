//
//  AppError.swift
//  2HQ
//
//  Created by Nikola Ticojevic on 12. 1. 2026..
//

import Foundation

enum AppError: Error, LocalizedError {
    case networkError(Error)
    case databaseError(Error)
    case mappingError
    case notFound
    case syncConflict
    case offline
    
    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .databaseError(let error):
            return "Database error: \(error.localizedDescription)"
        case .mappingError:
            return "Data conversion failed"
        case .notFound:
            return "Item not found"
        case .syncConflict:
            return "Sync conflict detected"
        case .offline:
            return "You are offline. Showing cached data."
        }
    }
    
    var isOfflineError: Bool {
        if case .offline = self { return true }
        return false
    }
}

// For better error handling
typealias ResultHandler<T> = (Result<T, AppError>) -> Void
