//
//  ArticleRepositoryProtocol.swift
//  2HQ
//
//  Created by Nikola Ticojevic on 12. 1. 2026..
//

import Foundation
import Combine

protocol ArticleRepositoryProtocol {
    // Fetch articles
    func fetchArticles() async throws -> [Article]
    func fetchArticleDetails(id: Int) async throws -> Article
    
    // Search and filter
    func searchArticles(query: String) async throws -> [Article]
    func filterBookmarkedArticles() async throws -> [Article]
    
    // Bookmarks
    func toggleBookmark(articleId: Int) async throws -> Bool
    func getBookmarkedArticles() async throws -> [Article]
    
    // Sync
    func syncWithRemote() async throws
    func clearCache() async throws
}

protocol SyncRepositoryProtocol {
    var isConnected: Bool { get }
    var connectionPublisher: AnyPublisher<Bool, Never> { get }
    func startMonitoring()
}
