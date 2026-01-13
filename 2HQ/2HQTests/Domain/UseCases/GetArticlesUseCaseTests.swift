//
//  GetArticlesUseCaseTests.swift
//  2HQTests
//
//  Created by Nikola Ticojevic on 12. 1. 2026..
//

import XCTest
@testable import _HQ

@MainActor
final class GetArticlesUseCaseTests: XCTestCase {
    private var mockRepository: MockArticleRepository!
    private var sut: GetArticlesUseCase!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockArticleRepository()
        sut = GetArticlesUseCase(repository: mockRepository)
    }
    
    override func tearDown() {
        mockRepository = nil
        sut = nil
        super.tearDown()
    }
    
    func test_execute_returnsArticlesFromRepository() async throws {
        // Given
        let expectedArticles = TestData.createSampleArticles(count: 3)
        mockRepository.articles = expectedArticles
        
        // When
        let articles = try await sut.execute()
        
        // Then
        XCTAssertEqual(articles.count, 3)
        XCTAssertEqual(articles.first?.id, 1)
        XCTAssertEqual(articles.last?.id, 3)
    }
    
    func test_execute_forceRefresh_callsSyncWithRemote() async throws {
        // Given
        mockRepository.articles = TestData.createSampleArticles(count: 2)
        
        // When
        _ = try await sut.execute(forceRefresh: true)
        
        // Then
        XCTAssertTrue(mockRepository.syncWasCalled)
    }
    
    func test_execute_whenRepositoryThrowsError_propagatesError() async {
        // Given
        mockRepository.shouldThrowError = true
        
        // When/Then
        do {
            _ = try await sut.execute()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    func test_execute_increasesFetchCallCount() async throws {
        // Given
        mockRepository.articles = TestData.createSampleArticles(count: 1)
        
        // When
        _ = try await sut.execute()
        _ = try await sut.execute()
        
        // Then
        XCTAssertEqual(mockRepository.fetchArticlesCallCount, 2)
    }
}
