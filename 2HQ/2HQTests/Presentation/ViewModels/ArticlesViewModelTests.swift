//
//  ArticlesViewModelTests.swift
//  2HQTests
//
//  Created by Nikola Ticojevic on 12. 1. 2026..
//

import XCTest
import Combine
@testable import _HQ

@MainActor
final class ArticlesViewModelTests: XCTestCase {
    private var mockGetArticlesUseCase: GetArticlesUseCase!
    private var mockSearchArticlesUseCase: SearchArticlesUseCase!
    private var mockToggleBookmarkUseCase: ToggleBookmarkUseCase!
    private var mockNetworkMonitor: MockNetworkMonitor!
    private var mockRepository: MockArticleRepository!
    private var sut: ArticlesViewModel!
    private var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        cancellables = []
        mockRepository = MockArticleRepository()
        mockGetArticlesUseCase = GetArticlesUseCase(repository: mockRepository)
        mockSearchArticlesUseCase = SearchArticlesUseCase(repository: mockRepository)
        mockToggleBookmarkUseCase = ToggleBookmarkUseCase(repository: mockRepository)
        mockNetworkMonitor = MockNetworkMonitor()
        
        sut = ArticlesViewModel(
            getArticlesUseCase: mockGetArticlesUseCase,
            searchArticlesUseCase: mockSearchArticlesUseCase,
            toggleBookmarkUseCase: mockToggleBookmarkUseCase,
            networkMonitor: mockNetworkMonitor
        )
    }
    
    override func tearDown() async throws {
        // Cancel any ongoing tasks
        sut.cancellables.removeAll()
        mockRepository = nil
        mockGetArticlesUseCase = nil
        mockSearchArticlesUseCase = nil
        mockToggleBookmarkUseCase = nil
        mockNetworkMonitor = nil
        sut = nil
        cancellables = nil
        try await super.tearDown()
    }
    
    func test_loadArticles_success_updatesArticlesAndState() async {
        // Given
        let expectedArticles = TestData.createSampleArticles(count: 3)
        mockRepository.articles = expectedArticles
        
        // When
        await sut.loadArticles()
        
        // Then
        XCTAssertEqual(sut.articles.count, 3)
        XCTAssertEqual(sut.filteredArticles.count, 3)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }
    
    func test_loadArticles_networkError_showsErrorMessage() async {
        // Given
        print("🧪 Setting up test: shouldThrowError = true")
        mockRepository.shouldThrowError = true
        mockRepository.articles = []  // Empty cache
        
        // When
        print("🧪 Calling loadArticles()")
        await sut.loadArticles()
        
        // Wait for async operations
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        // Debug
        print("🧪 DEBUG:")
        print("  - errorMessage: \(sut.errorMessage ?? "nil")")
        print("  - isLoading: \(sut.isLoading)")
        print("  - articles count: \(sut.articles.count)")
        print("  - dataState: \(sut.dataState)")
        
        // Then
        XCTAssertNotNil(sut.errorMessage, "Should show error message. Current: \(sut.errorMessage ?? "nil")")
        XCTAssertTrue(sut.articles.isEmpty, "Should have no articles")
    }
    
    func test_toggleBookmark_updatesArticleBookmarkStatus() async {
        // Given
        let article = TestData.createSampleArticle(id: 1, isBookmarked: false)
        mockRepository.articles = [article]
        await sut.loadArticles()
        
        // When
        await sut.toggleBookmark(for: 1)
        
        // Wait a bit for async operations
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        
        // Then
        XCTAssertTrue(sut.articles.first?.isBookmarked ?? false)
    }
    
    func test_searchTextChange_filtersArticles() async {
        // Given
        let articles = [
            TestData.createSampleArticle(id: 1, title: "Swift Programming"),
            TestData.createSampleArticle(id: 2, title: "iOS Development"),
            TestData.createSampleArticle(id: 3, title: "Android Kotlin")
        ]
        mockRepository.articles = articles
        await sut.loadArticles()
        
        // When
        sut.searchText = "swift"  // Lowercase
        // Wait longer for debounce
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Then
        XCTAssertEqual(sut.filteredArticles.count, 1)
        XCTAssertEqual(sut.filteredArticles.first?.title, "Swift Programming")
    }
    
    func test_showBookmarkedOnly_filtersToBookmarkedArticles() async {
        // Given
        let articles = [
            TestData.createSampleArticle(id: 1, isBookmarked: true),
            TestData.createSampleArticle(id: 2, isBookmarked: false),
            TestData.createSampleArticle(id: 3, isBookmarked: true)
        ]
        mockRepository.articles = articles
        await sut.loadArticles()
        
        // When
        sut.showBookmarkedOnly = true
        // Wait for debounce
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Then
        XCTAssertEqual(sut.filteredArticles.count, 2)
        XCTAssertTrue(sut.filteredArticles.allSatisfy { $0.isBookmarked })
    }
    
    func test_offlineIndicator_whenOfflineAndHasArticles() async {
        // Given
        let articles = TestData.createSampleArticles(count: 2)
        mockRepository.articles = articles
        
        // Important: Set offline BEFORE creating ViewModel
        mockNetworkMonitor.isConnected = false
        
        // Recreate ViewModel with the updated network monitor
        sut = ArticlesViewModel(
            getArticlesUseCase: mockGetArticlesUseCase,
            searchArticlesUseCase: mockSearchArticlesUseCase,
            toggleBookmarkUseCase: mockToggleBookmarkUseCase,
            networkMonitor: mockNetworkMonitor
        )
        
        // Wait for network status to propagate
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        
        // When
        await sut.loadArticles()
        
        // Wait for async operations
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Debug prints
        print("=== DEBUG ===")
        print("NetworkMonitor.isConnected: \(mockNetworkMonitor.isConnected)")
        print("ViewModel.isOffline: \(sut.isOffline)")
        print("ViewModel.articles.count: \(sut.articles.count)")
        print("ViewModel.shouldShowOfflineIndicator: \(sut.shouldShowOfflineIndicator)")
        print("ViewModel.errorMessage: \(sut.errorMessage ?? "nil")")
        print("=============")
        
        // Then
        XCTAssertTrue(sut.isOffline, "ViewModel should be offline")
        XCTAssertEqual(sut.articles.count, 2, "Should have 2 articles")
        XCTAssertTrue(sut.shouldShowOfflineIndicator, "Should show offline indicator")
    }
    
    func test_refresh_resetsSearchAndBookmarkFilters() async {
        // Given
        sut.searchText = "test"
        sut.showBookmarkedOnly = true
        
        // When
        await sut.refresh()
        
        // Then - Filters should be reset
        XCTAssertEqual(sut.searchText, "")  // Changed from XCTAssertTrue
        XCTAssertFalse(sut.showBookmarkedOnly)
    }
}
