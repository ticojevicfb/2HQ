//
//  GetArticlesUseCase.swift
//  2HQ
//
//  Created by Nikola Ticojevic on 12. 1. 2026..
//

import Foundation

class GetArticlesUseCase {
    private let repository: ArticleRepositoryProtocol
    
    init(repository: ArticleRepositoryProtocol) {
        self.repository = repository
    }
    
    func execute(forceRefresh: Bool = false) async throws -> [Article] {
        if forceRefresh {
            print("🔄 Force refresh requested")
            // Try to sync, but if offline, still return cached data
            do {
                try await repository.syncWithRemote()
            } catch {
                print("⚠️ Force refresh failed: \(error)")
                // Don't throw - fall back to cached data
            }
        }
        
        return try await repository.fetchArticles()
    }
}

class SearchArticlesUseCase {
    private let repository: ArticleRepositoryProtocol
    
    init(repository: ArticleRepositoryProtocol) {
        self.repository = repository
    }
    
    func execute(query: String) async throws -> [Article] {
        return try await repository.searchArticles(query: query)
    }
}

class ToggleBookmarkUseCase {
    private let repository: ArticleRepositoryProtocol
    
    init(repository: ArticleRepositoryProtocol) {
        self.repository = repository
    }
    
    func execute(articleId: Int) async throws -> Bool {
        return try await repository.toggleBookmark(articleId: articleId)
    }
}
