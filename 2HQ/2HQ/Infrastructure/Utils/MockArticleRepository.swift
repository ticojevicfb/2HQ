//
//  MockArticleRepository.swift
//  2HQ
//
//  Created by Nikola Ticojevic on 12. 1. 2026..
//

import Foundation

class MockArticleRepository: ArticleRepositoryProtocol {
    var articles: [Article] = SampleData.createSampleArticles()
    var shouldThrowError = false
    
    func fetchArticles() async throws -> [Article] {
        if shouldThrowError {
            throw AppError.offline
        }
        return articles
    }
    
    func fetchArticleDetails(id: Int) async throws -> Article {
        guard let article = articles.first(where: { $0.id == id }) else {
            throw AppError.notFound
        }
        return article
    }
    
    func searchArticles(query: String) async throws -> [Article] {
        if query.isEmpty {
            return articles
        }
        return articles.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.body.localizedCaseInsensitiveContains(query)
        }
    }
    
    func filterBookmarkedArticles() async throws -> [Article] {
        return articles.filter { $0.isBookmarked }
    }
    
    func toggleBookmark(articleId: Int) async throws -> Bool {
        guard let index = articles.firstIndex(where: { $0.id == articleId }) else {
            throw AppError.notFound
        }
        articles[index].isBookmarked.toggle()
        return articles[index].isBookmarked
    }
    
    func getBookmarkedArticles() async throws -> [Article] {
        return articles.filter { $0.isBookmarked }
    }
    
    func syncWithRemote() async throws {
        // Mock sync - add some new articles
        let newArticle = Article(
            id: 4,
            title: "New Synced Article",
            body: "This article was synced from the server.",
            author: Article.User(
                id: 2,
                name: "Alice Johnson",
                username: "alicej",
                email: "alice@example.com"
            ),
            isBookmarked: false,
            comments: [],
            lastUpdated: Date()
        )
        articles.append(newArticle)
    }
    
    func clearCache() async throws {
        articles.removeAll()
    }
}
