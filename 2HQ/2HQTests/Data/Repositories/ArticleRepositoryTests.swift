//
//  ArticleRepositoryTests.swift
//  2HQTests
//
//  Created by Nikola Ticojevic on 12. 1. 2026..
//

import XCTest
import SwiftData
@testable import _HQ

@MainActor
final class ArticleRepositoryTests: XCTestCase {
    private var sut: ArticleRepository!
    private var mockAPIService: MockArticleAPIService!
    private var mockStorageService: MockArticleStorageService!
    private var mockNetworkMonitor: MockNetworkMonitor!
    
    override func setUp() {
        super.setUp()
        mockAPIService = MockArticleAPIService()
        mockStorageService = MockArticleStorageService()
        mockNetworkMonitor = MockNetworkMonitor()
        
        sut = ArticleRepository(
            apiService: mockAPIService,
            storageService: mockStorageService,
            networkMonitor: mockNetworkMonitor
        )
    }
    
    override func tearDown() {
        sut = nil
        mockAPIService = nil
        mockStorageService = nil
        mockNetworkMonitor = nil
        super.tearDown()
    }
    
    func test_fetchArticles_offline_returnsCachedData() async throws {
        // Given
        let cachedArticles = TestData.createSampleArticles(count: 2)
        mockStorageService.articles = cachedArticles
        mockNetworkMonitor.isConnected = false
        
        // When
        let articles = try await sut.fetchArticles()
        
        // Then
        XCTAssertEqual(articles.count, 2)
        XCTAssertFalse(mockAPIService.fetchPostsWasCalled)
    }
    
    func test_fetchArticles_online_returnsCachedDataAndSyncs() async throws {
        // Given
        let cachedArticles = TestData.createSampleArticles(count: 1)
        mockStorageService.articles = cachedArticles
        mockNetworkMonitor.isConnected = true
        
        // When
        let articles = try await sut.fetchArticles()
        
        // Then
        XCTAssertEqual(articles.count, 1)
        // Background sync should have been triggered
        await waitForAsyncOperation(timeout: 0.1)
        XCTAssertTrue(mockAPIService.fetchPostsWasCalled)
    }
    
    func test_toggleBookmark_updatesStorageService() async throws {
        // Given
        let article = TestData.createSampleArticle(id: 1, isBookmarked: false)
        mockStorageService.articles = [article]
        
        // When
        let newStatus = try await sut.toggleBookmark(articleId: 1)
        
        // Then
        XCTAssertTrue(newStatus)
        XCTAssertTrue(mockStorageService.updateBookmarkStatusWasCalled)
    }
}

// MARK: - Mock Services
class MockArticleAPIService: ArticleAPIServiceProtocol {
    var fetchPostsWasCalled = false
    var fetchUsersWasCalled = false
    var fetchCommentsWasCalled = false
    
    func fetchPosts() async throws -> [PostDTO] {
        fetchPostsWasCalled = true
        return []
    }
    
    func fetchUsers() async throws -> [UserDTO] {
        fetchUsersWasCalled = true
        return []
    }
    
    func fetchComments(for postId: Int) async throws -> [CommentDTO] {
        fetchCommentsWasCalled = true
        return []
    }
    
    func fetchAllComments() async throws -> [CommentDTO] {
        fetchCommentsWasCalled = true
        return []
    }
}

class MockArticleStorageService: ArticleStorageServiceProtocol {
    var articles: [Article] = []
    var updateBookmarkStatusWasCalled = false
    
    func saveArticles(_ articles: [Article]) async throws { }
    func saveArticle(_ article: Article) async throws { }
    func updateBookmarkStatus(articleId: Int, isBookmarked: Bool) async throws {
        updateBookmarkStatusWasCalled = true
    }
    func fetchArticles() async throws -> [Article] { articles }
    func fetchArticle(id: Int) async throws -> Article? { articles.first }
    func searchArticles(query: String) async throws -> [Article] {
        if query.isEmpty { return articles }
        return articles.filter { $0.title.contains(query) }
    }
    func fetchBookmarkedArticles() async throws -> [Article] {
        articles.filter { $0.isBookmarked }
    }
    func saveComments(_ comments: [Article.Comment]) async throws { }
    func fetchComments(for postId: Int) async throws -> [Article.Comment] { [] }
    func deleteAllArticles() async throws { }
    func deleteArticle(id: Int) async throws { }
}
