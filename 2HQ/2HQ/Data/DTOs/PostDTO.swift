//
//  PostDTO.swift
//  2HQ
//
//  Created by Nikola Ticojevic on 12. 1. 2026..
//

import Foundation

struct PostDTO: Codable {
    let id: Int
    let title: String
    let body: String
    let userId: Int
    
    enum CodingKeys: String, CodingKey {
        case id, title, body, userId
    }
}

struct UserDTO: Codable {
    let id: Int
    let name: String
    let username: String
    let email: String
    let address: AddressDTO?
    let phone: String?
    let website: String?
    let company: CompanyDTO?
    
    struct AddressDTO: Codable {
        let street: String
        let suite: String
        let city: String
        let zipcode: String
        let geo: GeoDTO?
        
        struct GeoDTO: Codable {
            let lat: String
            let lng: String
        }
    }
    
    struct CompanyDTO: Codable {
        let name: String
        let catchPhrase: String
        let bs: String
    }
}

struct CommentDTO: Codable {
    let id: Int
    let postId: Int
    let name: String
    let email: String
    let body: String
}
