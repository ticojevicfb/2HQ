//
//  TestData.swift
//  2HQTests
//
//  Created by Nikola Ticojevic on 12. 1. 2026..
//

import Foundation
@testable import _HQ

enum TestData {
    static func createSampleArticle(id: Int = 1, title: String? = nil, isBookmarked: Bool = false) -> Article {
        let defaultTitle = "Test Article \(id)"
        return Article(
            id: id,
            title: title ?? defaultTitle,
            body: "This is a test article body for article \(id) about programming and development.",
            author: Article.User(
                id: id,
                name: "Author \(id)",
                username: "author\(id)",
                email: "author\(id)@test.com"
            ),
            isBookmarked: isBookmarked,
            comments: [
                Article.Comment(
                    id: id * 100,
                    name: "Commenter \(id)",
                    email: "commenter\(id)@test.com",
                    body: "Great article!",
                    postId: id
                )
            ],
            lastUpdated: Date()
        )
    }
    
    static func createSampleArticles(count: Int = 3) -> [Article] {
        (1...count).map { id in
            createSampleArticle(id: id, isBookmarked: id % 2 == 0)
        }
    }
}
