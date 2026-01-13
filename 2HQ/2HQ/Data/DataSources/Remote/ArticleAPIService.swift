//
//  ArticleAPIService.swift
//  2HQ
//
//  Created by Nikola Ticojevic on 12. 1. 2026..
//

import Foundation

protocol ArticleAPIServiceProtocol {
    func fetchPosts() async throws -> [PostDTO]
    func fetchUsers() async throws -> [UserDTO]
    func fetchComments(for postId: Int) async throws -> [CommentDTO]
    func fetchAllComments() async throws -> [CommentDTO]
}

class ArticleAPIService: ArticleAPIServiceProtocol {
    private let client: APIClientProtocol
    
    init(client: APIClientProtocol = APIClient()) {
        self.client = client
    }
    
    func fetchPosts() async throws -> [PostDTO] {
        return try await client.fetch(PostEndpoint.getAllPosts, expecting: [PostDTO].self)
    }
    
    func fetchUsers() async throws -> [UserDTO] {
        return try await client.fetch(UserEndpoint.getAllUsers, expecting: [UserDTO].self)
    }
    
    func fetchComments(for postId: Int) async throws -> [CommentDTO] {
        return try await client.fetch(
            CommentEndpoint.getComments(postId: postId),
            expecting: [CommentDTO].self
        )
    }
    
    func fetchAllComments() async throws -> [CommentDTO] {
        return try await client.fetch(CommentEndpoint.getAllComments, expecting: [CommentDTO].self)
    }
}
