//
//  ArticleRepository.swift
//  2HQ
//
//  Created by Nikola Ticojevic on 12. 1. 2026..
//
import Foundation
import SwiftData

class ArticleRepository: ArticleRepositoryProtocol {
    private let apiService: ArticleAPIServiceProtocol
    private let storageService: ArticleStorageServiceProtocol
    private let networkMonitor: NetworkMonitorProtocol
    
    // For debounced search (bonus)
    private let searchDebouncer = Debouncer(delay: 0.3)
    
    init(
        apiService: ArticleAPIServiceProtocol,
        storageService: ArticleStorageServiceProtocol,
        networkMonitor: NetworkMonitorProtocol
    ) {
        self.apiService = apiService
        self.storageService = storageService
        self.networkMonitor = networkMonitor
    }
    
    // MARK: - Fetch Articles (Offline-First)
    func fetchArticles() async throws -> [Article] {
        print("📱 Fetching articles (offline-first strategy)...")
        
        // 1. Always try to get cached data first
        let cachedArticles = try await storageService.fetchArticles()
        print("📱 Found \(cachedArticles.count) cached articles")
        
        // 2. Check network status
        if !networkMonitor.isConnected {
            print("📵 Device is offline")
            
            if cachedArticles.isEmpty {
                print("📵 Offline and no cached data available")
                throw AppError.offline  // Only throw if truly no data
            } else {
                print("📵 Offline but showing \(cachedArticles.count) cached articles")
                return cachedArticles  // Return cached data with offline indicator
            }
        }
        
        print("🌐 Device is online")
        
        // 3. If online, fetch fresh data in background
        Task {
            do {
                print("🔄 Starting background sync...")
                try await syncWithRemote()
                print("✅ Background sync completed")
            } catch {
                print("❌ Background sync failed: \(error)")
                // Don't throw - background sync failure shouldn't affect user
            }
        }
        
        // 4. Return cached data immediately (offline-first)
        // Even if cache is empty, return it (fresh data will come from background sync)
        return cachedArticles
    }
    
    // MARK: - Sync with Remote
    func syncWithRemote() async throws {
        guard networkMonitor.isConnected else {
            print("📵 Cannot sync - offline")
            throw AppError.offline
        }
        
        do {
            print("📡 Starting sync with remote API...")
            
            // Fetch all data concurrently
            async let posts = apiService.fetchPosts()
            async let users = apiService.fetchUsers()
            async let comments = apiService.fetchAllComments()
            
            let (postDTOs, userDTOs, commentDTOs) = try await (posts, users, comments)
            
            print("✅ Fetched: \(postDTOs.count) posts, \(userDTOs.count) users, \(commentDTOs.count) comments")
            
            if let firstPost = postDTOs.first {
                print("📝 Sample post: ID=\(firstPost.id), Title=\(firstPost.title.prefix(50))...")
            }
            if let firstUser = userDTOs.first {
                print("👤 Sample user: ID=\(firstUser.id), Name=\(firstUser.name)")
            }
            
            // Create lookup dictionaries
            let userDict = Dictionary(uniqueKeysWithValues: userDTOs.map { ($0.id, $0) })
            let commentsByPostId = Dictionary(grouping: commentDTOs, by: { $0.postId })
            
            // Convert to domain models
            var articles: [Article] = []
            
            for post in postDTOs {
                guard let user = userDict[post.userId] else {
                    print("⚠️ Skipping post \(post.id) - no user found with ID \(post.userId)")
                    continue
                }
                
                let articleComments = commentsByPostId[post.id] ?? []
                
                // Create article with embedded author data
                let article = Article(
                    id: post.id,
                    title: post.title,
                    body: post.body,
                    author: Article.User(
                        id: user.id,
                        name: user.name,
                        username: user.username,
                        email: user.email
                    ),
                    isBookmarked: false,
                    comments: articleComments.map { comment in
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
                articles.append(article)
            }
            
            print("✅ Created \(articles.count) domain articles")
            
            // Update bookmarks from existing cache
            let cachedArticles = try await storageService.fetchArticles()
            let bookmarkedIds = Set(cachedArticles.filter { $0.isBookmarked }.map { $0.id })
            
            for i in 0..<articles.count {
                articles[i].isBookmarked = bookmarkedIds.contains(articles[i].id)
            }
            
            // Save to local storage
            print("💾 Saving \(articles.count) articles to storage...")
            try await storageService.saveArticles(articles)
            
            // Save comments separately
            let allComments = commentDTOs.map { dto in
                Article.Comment(
                    id: dto.id,
                    name: dto.name,
                    email: dto.email,
                    body: dto.body,
                    postId: dto.postId
                )
            }
            print("💾 Saving \(allComments.count) comments to storage...")
            try await storageService.saveComments(allComments)
            
            print("🎉 Sync completed successfully. Total: \(articles.count) articles")
            
        } catch {
            print("❌ Sync failed: \(error)")
            throw AppError.networkError(error)
        }
    }
    
    // MARK: - Fetch Article Details
    func fetchArticleDetails(id: Int) async throws -> Article {
        print("📖 Fetching article details for ID: \(id)")
        
        // 1. Try to get article from cache
        if let cachedArticle = try await storageService.fetchArticle(id: id) {
            print("📱 Found article in cache")
            
            // Fetch comments for this article
            let comments = try await storageService.fetchComments(for: id)
            print("📱 Found \(comments.count) comments for article \(id)")
            
            // Create article with comments
            var articleWithComments = cachedArticle
            articleWithComments.comments = comments
            
            return articleWithComments
        }
        
        print("📱 Article not found in cache")
        
        // 2. If not in cache and offline, throw
        guard networkMonitor.isConnected else {
            print("📵 Offline and article not in cache")
            throw AppError.offline
        }
        
        print("🌐 Online - syncing to get article...")
        
        // 3. Sync all data to ensure we have the article
        try await syncWithRemote()
        
        // 4. Try to get article again after sync
        guard let article = try await storageService.fetchArticle(id: id) else {
            print("❌ Article \(id) not found even after sync")
            throw AppError.notFound
        }
        
        // 5. Fetch comments for this article
        let comments = try await storageService.fetchComments(for: id)
        
        // 6. Create article with comments
        var articleWithComments = article
        articleWithComments.comments = comments
        
        print("✅ Successfully fetched article \(id) with \(comments.count) comments")
        
        return articleWithComments
    }
    
    // MARK: - Search Articles
    func searchArticles(query: String) async throws -> [Article] {
        print("🔍 Searching articles for: '\(query)'")
        
        if query.isEmpty {
            return try await fetchArticles()
        }
        
        // Use debouncer for bonus requirement
        return try await withCheckedThrowingContinuation { continuation in
            searchDebouncer.run {
                Task {
                    do {
                        let results = try await self.storageService.searchArticles(query: query)
                        print("🔍 Found \(results.count) articles matching '\(query)'")
                        continuation.resume(returning: results)
                    } catch {
                        print("❌ Search failed: \(error)")
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
    
    // MARK: - Filter Bookmarked Articles
    func filterBookmarkedArticles() async throws -> [Article] {
        print("⭐ Filtering bookmarked articles")
        let bookmarked = try await storageService.fetchBookmarkedArticles()
        print("⭐ Found \(bookmarked.count) bookmarked articles")
        return bookmarked
    }
    
    // MARK: - Toggle Bookmark
    func toggleBookmark(articleId: Int) async throws -> Bool {
        print("📌 Toggling bookmark for article \(articleId)")
        
        // Get current article
        guard let article = try await storageService.fetchArticle(id: articleId) else {
            print("❌ Article \(articleId) not found")
            throw AppError.notFound
        }
        
        let newBookmarkStatus = !article.isBookmarked
        
        // Update in storage
        try await storageService.updateBookmarkStatus(
            articleId: articleId,
            isBookmarked: newBookmarkStatus
        )
        
        print("📌 Bookmark status for article \(articleId): \(newBookmarkStatus ? "bookmarked" : "unbookmarked")")
        
        return newBookmarkStatus
    }
    
    // MARK: - Get Bookmarked Articles
    func getBookmarkedArticles() async throws -> [Article] {
        return try await filterBookmarkedArticles()
    }
    
    // MARK: - Clear Cache
    func clearCache() async throws {
        print("🗑️ Clearing cache")
        try await storageService.deleteAllArticles()
        print("✅ Cache cleared")
    }
}
