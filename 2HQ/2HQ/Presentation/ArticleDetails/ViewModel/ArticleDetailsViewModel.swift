//
//  ArticleDetailsViewModel.swift
//  2HQ
//
//  Created by Nikola Ticojevic on 12. 1. 2026..
//

import Foundation
import Combine

@MainActor
final class ArticleDetailsViewModel: ObservableObject {
    @Published var article: Article?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isOffline = false
    
    private let articleId: Int
    private let getArticleDetailsUseCase: GetArticleDetailsUseCase
    private let toggleBookmarkUseCase: ToggleBookmarkUseCase
    private let networkMonitor: NetworkMonitorProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(
        articleId: Int,
        getArticleDetailsUseCase: GetArticleDetailsUseCase,
        toggleBookmarkUseCase: ToggleBookmarkUseCase,
        networkMonitor: NetworkMonitorProtocol
    ) {
        self.articleId = articleId
        self.getArticleDetailsUseCase = getArticleDetailsUseCase
        self.toggleBookmarkUseCase = toggleBookmarkUseCase
        self.networkMonitor = networkMonitor
        
        setupNetworkMonitoring()
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.connectionPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] isConnected in
                self?.isOffline = !isConnected
            }
            .store(in: &cancellables)
    }
    
    func loadArticle() async {
        isLoading = true
        errorMessage = nil
        
        do {
            article = try await getArticleDetailsUseCase.execute(articleId: articleId)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func toggleBookmark() async {
        guard let article = article else { return }
        
        do {
            let newStatus = try await toggleBookmarkUseCase.execute(articleId: article.id)
            self.article?.isBookmarked = newStatus
            
            // POST NOTIFICATION about bookmark change
            BookmarkNotification.postUpdate(
                articleId: article.id,
                isBookmarked: newStatus
            )
            
            print("📢 Posted bookmark update for article \(article.id): \(newStatus)")
            
        } catch {
            errorMessage = "Failed to update bookmark: \(error.localizedDescription)"
        }
    }
}
