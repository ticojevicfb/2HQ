//
//  ArticleEntity.swift
//  2HQ
//
//  Created by Nikola Ticojevic on 12. 1. 2026..
//

import Foundation
import SwiftData

@Model
final class ArticleEntity {
    @Attribute(.unique) var id: Int
    var title: String
    var body: String
    var isBookmarked: Bool
    var lastUpdated: Date
    
    // Embedded author data (no relationship needed)
    var authorId: Int
    var authorName: String
    var authorUsername: String
    var authorEmail: String
    
    init(id: Int, title: String, body: String, isBookmarked: Bool = false,
         lastUpdated: Date = Date(), authorId: Int, authorName: String,
         authorUsername: String, authorEmail: String) {
        self.id = id
        self.title = title
        self.body = body
        self.isBookmarked = isBookmarked
        self.lastUpdated = lastUpdated
        self.authorId = authorId
        self.authorName = authorName
        self.authorUsername = authorUsername
        self.authorEmail = authorEmail
    }
}

@Model
final class CommentEntity {
    @Attribute(.unique) var id: Int
    var name: String
    var email: String
    var body: String
    var postId: Int  // Reference to article ID
    
    init(id: Int, name: String, email: String, body: String, postId: Int) {
        self.id = id
        self.name = name
        self.email = email
        self.body = body
        self.postId = postId
    }
}
