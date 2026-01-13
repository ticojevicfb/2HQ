//
//  ArticleCellView.swift
//  2HQ
//
//  Created by Nikola Ticojevic on 12. 1. 2026..
//

import SwiftUI

struct ArticleCellView: View {
    let article: Article
    let onBookmarkTapped: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Left side: Content
            VStack(alignment: .leading, spacing: 8) {
                // Title with gradient
                Text(article.title)
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Author with avatar icon
                HStack(spacing: 6) {
                    Image(systemName: "person.circle.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(article.author.name)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                // Preview text with fade
                Text(article.body)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .padding(.top, 2)
            }
            
            Spacer()
            
            // Right side: Bookmark button
            bookmarkButton
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(
                    color: Color.black.opacity(0.05),
                    radius: 8,
                    x: 0,
                    y: 2
                )
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .font(.body)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
    
    private var bookmarkButton: some View {
        Button(action: onBookmarkTapped) {
            Image(systemName: article.isBookmarked ? "bookmark.fill" : "bookmark")
                .font(.title3)
                .foregroundColor(article.isBookmarked ? .blue : .gray.opacity(0.7))
                .symbolEffect(.bounce, value: article.isBookmarked)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(article.isBookmarked ?
                             Color.blue.opacity(0.1) :
                             Color.gray.opacity(0.05))
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    List {
        ArticleCellView(
            article: Article(
                id: 1,
                title: "Getting Started with SwiftUI and Modern iOS Development",
                body: "Learn how to build beautiful, responsive applications using SwiftUI's declarative syntax and modern architecture patterns.",
                author: Article.User(
                    id: 1,
                    name: "Alex Johnson",
                    username: "alexj",
                    email: "alex@example.com"
                ),
                isBookmarked: true,
                comments: nil,
                lastUpdated: Date()
            ),
            onBookmarkTapped: {}
        )
        
        ArticleCellView(
            article: Article(
                id: 2,
                title: "Mastering Swift Concurrency",
                body: "Deep dive into async/await, actors, and structured concurrency for building responsive and efficient applications.",
                author: Article.User(
                    id: 2,
                    name: "Maria Chen",
                    username: "mariac",
                    email: "maria@example.com"
                ),
                isBookmarked: false,
                comments: nil,
                lastUpdated: Date()
            ),
            onBookmarkTapped: {}
        )
    }
    .listStyle(.plain)
}
