//
//  Article.swift
//  2HQ
//
//  Created by Nikola Ticojevic on 12. 1. 2026..
//

import Foundation

struct Article: Identifiable, Equatable, Hashable {
    let id: Int
    let title: String
    let body: String
    let author: User
    var isBookmarked: Bool
    var comments: [Comment]?
    let lastUpdated: Date
    
    struct User: Identifiable, Equatable, Hashable {
        let id: Int
        let name: String
        let username: String
        let email: String
    }
    
    struct Comment: Identifiable, Equatable, Hashable {
        let id: Int
        let name: String
        let email: String
        let body: String
        let postId: Int
    }
}

// For handling different states
enum DataState<T> {
    case loading
    case loaded(T)
    case error(Error)
    case empty
}

// For search and filter
struct ArticleFilter {
    var searchText: String = ""
    var showBookmarkedOnly: Bool = false
}
