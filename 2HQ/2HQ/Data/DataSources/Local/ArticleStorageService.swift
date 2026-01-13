//
//  ArticleStorageService.swift
//  2HQ
//
//  Created by Nikola Ticojevic on 12. 1. 2026..
//

import Foundation
import SwiftData

protocol ArticleStorageServiceProtocol {
    // Save operations
    func saveArticles(_ articles: [Article]) async throws
    func saveArticle(_ article: Article) async throws
    func updateBookmarkStatus(articleId: Int, isBookmarked: Bool) async throws
    
    // Comment operations
    func saveComments(_ comments: [Article.Comment]) async throws
    func fetchComments(for postId: Int) async throws -> [Article.Comment]
    
    // Fetch operations
    func fetchArticles() async throws -> [Article]
    func fetchArticle(id: Int) async throws -> Article?
    func searchArticles(query: String) async throws -> [Article]
    func fetchBookmarkedArticles() async throws -> [Article]
    
    // Delete operations
    func deleteAllArticles() async throws
    func deleteArticle(id: Int) async throws
}

@MainActor
class ArticleStorageService: ArticleStorageServiceProtocol {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Save Operations
    func saveArticles(_ articles: [Article]) async throws {
        print("💾 Saving \(articles.count) articles to storage...")
        
        for article in articles {
            if let entity = ArticleMapper.toEntity(article: article, context: modelContext) {
                // Debug before inserting
             //   ArticleMapper.printEntityInfo(entity)
                modelContext.insert(entity)
            } else {
                print("❌ Failed to create entity for article: \(article.title)")
            }
        }
        
        try modelContext.save()
        print("✅ Saved \(articles.count) articles successfully")
    }
    
    func saveArticle(_ article: Article) async throws {
        if let entity = ArticleMapper.toEntity(article: article, context: modelContext) {
            modelContext.insert(entity)
            try modelContext.save()
        } else {
            throw AppError.mappingError
        }
    }
    
    func updateBookmarkStatus(articleId: Int, isBookmarked: Bool) async throws {
        let descriptor = FetchDescriptor<ArticleEntity>(
            predicate: #Predicate { $0.id == articleId }
        )
        
        let entities: [ArticleEntity] = try modelContext.fetch(descriptor)
        
        guard let entity = entities.first,
              entity.modelContext != nil, !entity.isDeleted else {
            throw AppError.notFound
        }
        
        entity.isBookmarked = isBookmarked
        entity.lastUpdated = Date()
        
        try modelContext.save()
    }
    
    // MARK: - Fetch Operations
    func fetchArticles() async throws -> [Article] {
        let descriptor = FetchDescriptor<ArticleEntity>(
            sortBy: [SortDescriptor(\.lastUpdated, order: .reverse)]
        )
        
        let entities: [ArticleEntity] = try modelContext.fetch(descriptor)
        
        // Filter out invalid entities
        let validEntities = entities.filter { entity in
            entity.modelContext != nil && !entity.isDeleted
        }
        
        print("📱 Fetched \(validEntities.count) valid articles from storage")
        return validEntities.compactMap { ArticleMapper.toDomain(entity: $0) }
    }
    
    func fetchArticle(id: Int) async throws -> Article? {
        let descriptor = FetchDescriptor<ArticleEntity>(
            predicate: #Predicate { $0.id == id }
        )
        
        let entities: [ArticleEntity] = try modelContext.fetch(descriptor)
        
        guard let entity = entities.first,
              entity.modelContext != nil, !entity.isDeleted else {
            return nil
        }
        
        return ArticleMapper.toDomain(entity: entity)
    }
    
    func searchArticles(query: String) async throws -> [Article] {
        guard !query.isEmpty else {
            return try await fetchArticles()
        }
        
        // Fetch ALL articles first (simpler approach)
        let allArticles = try await fetchArticles()
        
        // Filter in memory
        return allArticles.filter { article in
            article.title.localizedCaseInsensitiveContains(query) ||
            article.body.localizedCaseInsensitiveContains(query)
        }
    }
    
    func fetchBookmarkedArticles() async throws -> [Article] {
        let descriptor = FetchDescriptor<ArticleEntity>(
            predicate: #Predicate { $0.isBookmarked == true },
            sortBy: [SortDescriptor(\.lastUpdated, order: .reverse)]
        )
        
        let entities: [ArticleEntity] = try modelContext.fetch(descriptor)
        
        // Filter out invalid entities
        let validEntities = entities.filter { entity in
            entity.modelContext != nil && !entity.isDeleted
        }
        
        return validEntities.compactMap { ArticleMapper.toDomain(entity: $0) }
    }
    
    // MARK: - Delete Operations
    func deleteAllArticles() async throws {
        let descriptor = FetchDescriptor<ArticleEntity>()
        let entities: [ArticleEntity] = try modelContext.fetch(descriptor)
        
        for entity in entities {
            modelContext.delete(entity)
        }
        
        // Delete comments (no UserEntity anymore)
        let commentDescriptor = FetchDescriptor<CommentEntity>()
        let comments: [CommentEntity] = try modelContext.fetch(commentDescriptor)
        for comment in comments {
            modelContext.delete(comment)
        }
        
        try modelContext.save()
    }
    
    func deleteArticle(id: Int) async throws {
        let descriptor = FetchDescriptor<ArticleEntity>(
            predicate: #Predicate { $0.id == id }
        )
        
        let entities: [ArticleEntity] = try modelContext.fetch(descriptor)
        
        for entity in entities {
            modelContext.delete(entity)
        }
        
        try modelContext.save()
    }
    
    // MARK: - Comment Operations
    func saveComments(_ comments: [Article.Comment]) async throws {
        for comment in comments {
            let commentEntity = CommentEntity(
                id: comment.id,
                name: comment.name,
                email: comment.email,
                body: comment.body,
                postId: comment.postId
            )
            modelContext.insert(commentEntity)
        }
        try modelContext.save()
    }

    func fetchComments(for postId: Int) async throws -> [Article.Comment] {
        let descriptor = FetchDescriptor<CommentEntity>(
            predicate: #Predicate { $0.postId == postId }
        )
        
        let entities: [CommentEntity] = try modelContext.fetch(descriptor)
        
        // Filter out invalid entities
        let validEntities = entities.filter { entity in
            entity.modelContext != nil && !entity.isDeleted
        }
        
        return validEntities.map { entity in
            Article.Comment(
                id: entity.id,
                name: entity.name,
                email: entity.email,
                body: entity.body,
                postId: entity.postId
            )
        }
    }
}
