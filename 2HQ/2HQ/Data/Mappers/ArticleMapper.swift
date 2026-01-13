//
//  ArticleMapper.swift
//  2HQ
//
//  Created by Nikola Ticojevic on 12. 1. 2026..
//

import Foundation
import SwiftData

enum ArticleMapper {
    // MARK: - Debug Helper
    static func printEntityInfo(_ entity: ArticleEntity) {
        print("=== ArticleEntity Debug Info ===")
        print("Context: \(entity.modelContext != nil ? "Valid" : "Invalid")")
        print("IsDeleted: \(entity.isDeleted)")
        print("ID: \(entity.id)")
        print("Title: \(entity.title)")
        print("Body: \(entity.body)")
        print("Author: \(entity.authorName) (\(entity.authorEmail))")
        print("===============================")
    }
    
    // MARK: - DTO to Domain
    static func toDomain(post: PostDTO, user: UserDTO, comments: [CommentDTO], isBookmarked: Bool = false) -> Article? {
        // Validate required fields
        guard !post.title.isEmpty, !post.body.isEmpty,
              !user.name.isEmpty, !user.email.isEmpty else {
            print("❌ Validation failed: Missing required fields in DTO")
            return nil
        }
        
        return Article(
            id: post.id,
            title: post.title,
            body: post.body,
            author: Article.User(
                id: user.id,
                name: user.name,
                username: user.username,
                email: user.email
            ),
            isBookmarked: isBookmarked,
            comments: comments.map { comment in
                Article.Comment(
                    id: comment.id,
                    name: comment.name,
                    email: comment.email,
                    body: comment.body,
                    postId: comment.postId
                )
            },
            lastUpdated: Date()
        )
    }
    
    // MARK: - DTO to Entity (for sync)
    static func toEntity(post: PostDTO, user: UserDTO, context: ModelContext) -> ArticleEntity? {
        // Validate required fields
        guard !post.title.isEmpty, !post.body.isEmpty,
              !user.name.isEmpty, !user.email.isEmpty else {
            print("❌ Validation failed: Missing required fields for entity creation")
            return nil
        }
        
        // Create article entity with embedded author data
        return ArticleEntity(
            id: post.id,
            title: post.title,
            body: post.body,
            isBookmarked: false,
            lastUpdated: Date(),
            authorId: user.id,
            authorName: user.name,
            authorUsername: user.username,
            authorEmail: user.email
        )
    }
    
    // MARK: - Entity to Domain
    static func toDomain(entity: ArticleEntity) -> Article? {
        // Check if entity is still valid
        guard entity.modelContext != nil, !entity.isDeleted else {
            print("❌ Entity is invalidated or deleted")
            return nil
        }
        
        return Article(
            id: entity.id,
            title: entity.title,
            body: entity.body,
            author: Article.User(
                id: entity.authorId,
                name: entity.authorName,
                username: entity.authorUsername,
                email: entity.authorEmail
            ),
            isBookmarked: entity.isBookmarked,
            comments: nil, // Comments fetched separately
            lastUpdated: entity.lastUpdated
        )
    }
    
    // MARK: - Domain to Entity
    static func toEntity(article: Article, context: ModelContext) -> ArticleEntity? {
        // Validate required fields
        guard !article.title.isEmpty, !article.body.isEmpty,
              !article.author.name.isEmpty, !article.author.email.isEmpty else {
            print("❌ Validation failed: Missing required fields in domain model")
            return nil
        }
        
        // Create article entity with embedded author data
        return ArticleEntity(
            id: article.id,
            title: article.title,
            body: article.body,
            isBookmarked: article.isBookmarked,
            lastUpdated: article.lastUpdated,
            authorId: article.author.id,
            authorName: article.author.name,
            authorUsername: article.author.username,
            authorEmail: article.author.email
        )
    }
    
    // MARK: - Batch Conversions
    static func toDomain(entities: [ArticleEntity]) -> [Article] {
        entities.compactMap { toDomain(entity: $0) }
    }
    
    static func toEntities(articles: [Article], context: ModelContext) -> [ArticleEntity] {
        articles.compactMap { toEntity(article: $0, context: context) }
    }
    
    // MARK: - Update Existing Entity
    static func updateEntity(_ entity: ArticleEntity, with article: Article) {
        // Only update if entity is still valid
        guard entity.modelContext != nil, !entity.isDeleted else {
            print("❌ Cannot update invalidated entity")
            return
        }
        
        // Update basic properties
        entity.title = article.title
        entity.body = article.body
        entity.isBookmarked = article.isBookmarked
        entity.lastUpdated = article.lastUpdated
        
        // Update embedded author data
        entity.authorId = article.author.id
        entity.authorName = article.author.name
        entity.authorUsername = article.author.username
        entity.authorEmail = article.author.email
    }
    
    // MARK: - Create Article from DTOs
    static func createArticleFromDTOs(post: PostDTO, user: UserDTO, comments: [CommentDTO]) -> Article? {
        return toDomain(
            post: post,
            user: user,
            comments: comments,
            isBookmarked: false
        )
    }
}
