//
//  UserEndpoint.swift
//  2HQ
//
//  Created by Nikola Ticojevic on 13. 1. 2026..
//

import Foundation

enum UserEndpoint: Endpoint {
    case getAllUsers
    case getUser(id: Int)
    
    var path: String {
        switch self {
        case .getAllUsers:
            return "/users"
        case .getUser(let id):
            return "/users/\(id)"
        }
    }
    
    var method: HTTPMethod { .get }
}
