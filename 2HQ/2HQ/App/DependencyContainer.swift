//
//  DependencyContainer.swift
//  2HQ
//
//  Created by Nikola Ticojevic on 12. 1. 2026..
//

import Foundation
import SwiftData
import Combine

@MainActor
class DependencyContainer: ObservableObject {
    private let modelContainer: ModelContainer
    private let networkMonitor: NetworkMonitorProtocol
    
    // Lazy initialization for services
    private lazy var apiClient: APIClientProtocol = {
        APIClient()
    }()
    
    private lazy var apiService: ArticleAPIServiceProtocol = {
        ArticleAPIService(client: apiClient)
    }()
    
    private lazy var storageService: ArticleStorageServiceProtocol = {
        ArticleStorageService(modelContext: ModelContext(modelContainer))
    }()
    
    private lazy var articleRepository: ArticleRepositoryProtocol = {
        ArticleRepository(
            apiService: apiService,
            storageService: storageService,
            networkMonitor: networkMonitor
        )
    }()
    
    // Use Cases
    lazy var getArticlesUseCase: GetArticlesUseCase = {
        GetArticlesUseCase(repository: articleRepository)
    }()
    
    lazy var searchArticlesUseCase: SearchArticlesUseCase = {
        SearchArticlesUseCase(repository: articleRepository)
    }()
    
    lazy var toggleBookmarkUseCase: ToggleBookmarkUseCase = {
        ToggleBookmarkUseCase(repository: articleRepository)
    }()
    
    lazy var getArticleDetailsUseCase: GetArticleDetailsUseCase = {
        GetArticleDetailsUseCase(repository: articleRepository)
    }()
    
    init() {
        do {
            self.modelContainer = try ModelContainer(
                for: ArticleEntity.self, CommentEntity.self
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        
        // Initialize network monitor
        self.networkMonitor = NetworkMonitor()
        self.networkMonitor.startMonitoring()
    }
    
    // Factory methods for ViewModels
    func makeArticlesViewModel() -> ArticlesViewModel {
        ArticlesViewModel(
            getArticlesUseCase: getArticlesUseCase,
            searchArticlesUseCase: searchArticlesUseCase,
            toggleBookmarkUseCase: toggleBookmarkUseCase,
            networkMonitor: networkMonitor
        )
    }
    
    func makeArticleDetailsViewModel(articleId: Int) -> ArticleDetailsViewModel {
        ArticleDetailsViewModel(
            articleId: articleId,
            getArticleDetailsUseCase: getArticleDetailsUseCase,
            toggleBookmarkUseCase: toggleBookmarkUseCase,
            networkMonitor: networkMonitor
        )
    }
}
