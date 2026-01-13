//
//  BookmarkNotification.swift
//  2HQ
//
//  Created by Nikola Ticojevic on 12. 1. 2026..
//

import Foundation

enum BookmarkNotification {
    static let bookmarkUpdated = Notification.Name("bookmarkUpdated")
    
    struct Keys {
        static let articleId = "articleId"
        static let isBookmarked = "isBookmarked"
    }
    
    static func postUpdate(articleId: Int, isBookmarked: Bool) {
        NotificationCenter.default.post(
            name: bookmarkUpdated,
            object: nil,
            userInfo: [
                Keys.articleId: articleId,
                Keys.isBookmarked: isBookmarked
            ]
        )
    }
}
