//
//  SampleData.swift
//  2HQ
//
//  Created by Nikola Ticojevic on 12. 1. 2026..
//

import Foundation

enum SampleData {
    static func createSampleArticles() -> [Article] {
        let user = Article.User(
            id: 1,
            name: "John Doe",
            username: "johndoe",
            email: "john@example.com"
        )
        
        let comment = Article.Comment(
            id: 1,
            name: "Jane Smith",
            email: "jane@example.com",
            body: "Great article!",
            postId: 1
        )
        
        return [
            Article(
                id: 1,
                title: "Getting Started with SwiftUI",
                body: "SwiftUI is a modern way to build user interfaces across all Apple platforms.",
                author: user,
                isBookmarked: true,
                comments: [comment],
                lastUpdated: Date()
            ),
            Article(
                id: 2,
                title: "Mastering Swift Concurrency",
                body: "Learn how to use async/await and actors in your Swift applications.",
                author: user,
                isBookmarked: false,
                comments: [],
                lastUpdated: Date().addingTimeInterval(-3600)
            ),
            Article(
                id: 3,
                title: "Building Offline-First Apps",
                body: "Create resilient applications that work even without internet connection.",
                author: user,
                isBookmarked: false,
                comments: [],
                lastUpdated: Date().addingTimeInterval(-7200)
            )
        ]
    }
}
