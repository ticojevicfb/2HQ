//
//  PostEndpoint.swift
//  2HQ
//
//  Created by Nikola Ticojevic on 13. 1. 2026..
//

import Foundation

enum PostEndpoint: Endpoint {
    case getAllPosts
    case getPost(id: Int)
    
    var path: String {
        switch self {
        case .getAllPosts:
            return "/posts"
        case .getPost(let id):
            return "/posts/\(id)"
        }
    }
    
    var method: HTTPMethod { .get }
    var parameters: [String: Any]? { nil }
}

