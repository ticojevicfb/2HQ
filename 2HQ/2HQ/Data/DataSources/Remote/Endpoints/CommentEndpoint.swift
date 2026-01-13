//
//  CommentEndpoint.swift
//  2HQ
//
//  Created by Nikola Ticojevic on 13. 1. 2026..
//

import Foundation

enum CommentEndpoint: Endpoint {
    case getComments(postId: Int)
    case getAllComments
    
    var path: String {
        switch self {
        case .getComments:
            return "/comments"
        case .getAllComments:
            return "/comments"
        }
    }
    
    var method: HTTPMethod { .get }
    
    var parameters: [String: Any]? {
        switch self {
        case .getComments(let postId):
            return ["postId": postId]
        case .getAllComments:
            return nil
        }
    }
}
