//
//  ArticleDetailsView.swift
//  2HQ
//
//  Created by Nikola Ticojevic on 12. 1. 2026..
//

import SwiftUI

struct ArticleDetailsView: View {
    @StateObject private var viewModel: ArticleDetailsViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var showingComments = false
    
    init(viewModel: ArticleDetailsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if viewModel.isLoading {
                    LoadingView()
                        .frame(height: 300)
                } else if let article = viewModel.article {
                    articleContent(article)
                } else if let error = viewModel.errorMessage {
                    errorContent(error)
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if let article = viewModel.article {
                    bookmarkButton(article: article)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .task {
            await viewModel.loadArticle()
        }
    }
    
    // MARK: - Content Sections
    private func articleContent(_ article: Article) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            // Title Section
            VStack(alignment: .leading, spacing: 12) {
                Text(article.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                // Meta info
                HStack(spacing: 16) {
                    Label(article.author.name, systemImage: "person.fill")
                    Label(formatDate(article.lastUpdated), systemImage: "calendar")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            // Author Card
            authorCard(article.author)
            
            // Body Content
            VStack(alignment: .leading, spacing: 16) {
                Text("article_content_title".localized(using: languageManager))
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(article.body)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineSpacing(6)
            }
            
            // Comments Section
            if let comments = article.comments, !comments.isEmpty {
                commentsSection(comments)
            }
        }
    }
    
    private func authorCard(_ author: Article.User) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(author.name)
                        .font(.headline)
                    Text("@\(author.username)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 4) {
                Label(author.email, systemImage: "envelope.fill")
                Label("author_id_label".localized(using: languageManager, String(author.id)), systemImage: "number")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
    
    private func commentsSection(_ comments: [Article.Comment]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("comments_title".localized(using: languageManager))
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("comments_count".localized(using: languageManager, comments.count))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.1))
                    )
                    .foregroundColor(.blue)
            }
            
            LazyVStack(spacing: 12) {
                ForEach(comments) { comment in
                    commentCard(comment)
                }
            }
        }
    }
    
    private func commentCard(_ comment: Article.Comment) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "person.crop.circle.fill")
                    .foregroundColor(.gray)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(comment.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(comment.email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Text(comment.body)
                .font(.body)
                .foregroundColor(.primary)
                .lineSpacing(4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
    
    private func errorContent(_ error: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("error_loading_article".localized(using: languageManager))
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(error)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("retry_button".localized(using: languageManager)) {
                Task { await viewModel.loadArticle() }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
    
    private func bookmarkButton(article: Article) -> some View {
        Button {
            Task {
                await viewModel.toggleBookmark()
            }
        } label: {
            Image(systemName: article.isBookmarked ? "bookmark.fill" : "bookmark")
                .font(.title3)
                .foregroundColor(article.isBookmarked ? .blue : .gray)
                .symbolEffect(.bounce, value: article.isBookmarked)
        }
        .accessibilityLabel(
            article.isBookmarked ?
                "remove_bookmark".localized(using: languageManager) :
                "add_bookmark".localized(using: languageManager)
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
