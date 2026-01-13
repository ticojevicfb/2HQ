//
//  ArticlesViewModel.swift
//  2HQ
//
//  Created by Nikola Ticojevic on 12. 1. 2026..
//

import Foundation
import Combine

@MainActor
final class ArticlesViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var articles: [Article] = []
    @Published var filteredArticles: [Article] = []
    @Published var dataState: DataState<[Article]> = .loading
    @Published var searchText = ""
    @Published var showBookmarkedOnly = false
    @Published var isOffline = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let getArticlesUseCase: GetArticlesUseCase
    private let searchArticlesUseCase: SearchArticlesUseCase
    private let toggleBookmarkUseCase: ToggleBookmarkUseCase
    private let networkMonitor: NetworkMonitorProtocol
    var cancellables = Set<AnyCancellable>()
    var currentTask: Task<Void, Never>?
    
    // MARK: - Initialization
    init(
        getArticlesUseCase: GetArticlesUseCase,
        searchArticlesUseCase: SearchArticlesUseCase,
        toggleBookmarkUseCase: ToggleBookmarkUseCase,
        networkMonitor: NetworkMonitorProtocol
    ) {
        self.getArticlesUseCase = getArticlesUseCase
        self.searchArticlesUseCase = searchArticlesUseCase
        self.toggleBookmarkUseCase = toggleBookmarkUseCase
        self.networkMonitor = networkMonitor
        
        setupBindings()
        setupNetworkMonitoring()
        setupBookmarkNotifications()
    }
    
    private class CleanupHelper {
        var currentTask: Task<Void, Never>?
        var cancellables: Set<AnyCancellable>
        
        init(currentTask: Task<Void, Never>?, cancellables: Set<AnyCancellable>) {
            self.currentTask = currentTask
            self.cancellables = cancellables
        }
        
        func cleanup() {
            currentTask?.cancel()
            cancellables.removeAll()
        }
    }
    
    deinit {
        print("🧹 ArticlesViewModel deinitializing")
        
        // Create helper with current state
        let helper = CleanupHelper(
            currentTask: currentTask,
            cancellables: cancellables
        )
        
        Task { @MainActor in
            helper.cleanup()
        }
    }
    
    func cancelAllOperations() {
        Task { @MainActor in
            print("🧹 Manual cancellation")
            currentTask?.cancel()
            currentTask = nil
            cancellables.removeAll()
        }
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // Combine search text and bookmark filter
        $searchText
            .combineLatest($showBookmarkedOnly)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] searchText, showBookmarkedOnly in
                self?.applyFilters(searchText: searchText, showBookmarkedOnly: showBookmarkedOnly)
            }
            .store(in: &cancellables)
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.connectionPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] isConnected in
                self?.isOffline = !isConnected
                if isConnected {
                    // Auto-refresh when coming back online
                    Task { await self?.loadArticles(forceRefresh: true) }
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    func loadArticles(forceRefresh: Bool = false) async {
        // Cancel any existing task
        currentTask?.cancel()
        
        currentTask = Task { @MainActor in
            isLoading = true
            errorMessage = nil
            
            do {
                let articles = try await getArticlesUseCase.execute(forceRefresh: forceRefresh)
                
                if Task.isCancelled { return }
                
                self.articles = articles
                applyFilters(searchText: searchText, showBookmarkedOnly: showBookmarkedOnly)
                dataState = articles.isEmpty ? .empty : .loaded(articles)
                
                print("✅ Loaded \(articles.count) articles")
                
            } catch {
                if Task.isCancelled { return }
                
                handleError(error)
                
                // CRITICAL: If we have cached data, show it even with error
                if !articles.isEmpty {
                    print("⚠️ Error but showing cached data: \(error.localizedDescription)")
                    // Don't change dataState - keep showing cached data
                    // Just show the error message for information
                    if let appError = error as? AppError, appError.isOfflineError {
                        // Offline error is expected when offline
                        errorMessage = appError.errorDescription
                    }
                } else {
                    // Only show error state if we truly have no data
                    dataState = .error(error)
                }
            }
            
            isLoading = false
        }
        
        await currentTask?.value
    }
    
    func toggleBookmark(for articleId: Int) async {
        do {
            let newStatus = try await toggleBookmarkUseCase.execute(articleId: articleId)
            
            print("📌 Bookmark toggled for article \(articleId): \(newStatus)")
            
            // Update local array
            if let index = articles.firstIndex(where: { $0.id == articleId }) {
                articles[index].isBookmarked = newStatus
                print("📌 Updated local article at index \(index)")
            }
            
            // Post notification (so details view can also update if open)
            BookmarkNotification.postUpdate(
                articleId: articleId,
                isBookmarked: newStatus
            )
            
            // Re-apply filters
            applyFilters(searchText: searchText, showBookmarkedOnly: showBookmarkedOnly)
            
        } catch {
            print("❌ Failed to toggle bookmark: \(error)")
            errorMessage = error.localizedDescription
        }
    }
    
    func refresh() async {
        print("🔄 Manual refresh triggered")
        
        searchText = ""
        showBookmarkedOnly = false
        await loadArticles(forceRefresh: true)
    }
    
    // MARK: - Private Methods
    func applyFilters(searchText: String, showBookmarkedOnly: Bool) {
        var filtered = articles
        
        // 1. First apply bookmark filter if needed
        if showBookmarkedOnly {
            filtered = filtered.filter { $0.isBookmarked }
            print("✅ Applied bookmark filter: \(filtered.count) articles")
        }
        
        // 2. Then apply search filter if needed
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            filtered = filtered.filter { article in
                article.title.lowercased().contains(query) ||
                article.body.lowercased().contains(query) ||
                article.author.name.lowercased().contains(query)
            }
            print("✅ Applied search filter: \(filtered.count) articles match '\(query)'")
        }
        
        // 3. Update the published property
        filteredArticles = filtered
        
        // 4. Update data state
        updateDataState()
    }
    
    private func updateDataState() {
        if isLoading {
            dataState = .loading
        } else if let errorMessage = errorMessage, !errorMessage.isEmpty {
            dataState = .error(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
        } else if filteredArticles.isEmpty {
            if articles.isEmpty {
                dataState = .empty
            } else if showBookmarkedOnly {
                dataState = .empty
            } else if !searchText.isEmpty {
                dataState = .empty
            } else {
                dataState = .loaded(filteredArticles)
            }
        } else {
            dataState = .loaded(filteredArticles)
        }
    }
    
    private func setupBookmarkNotifications() {
        NotificationCenter.default.publisher(for: BookmarkNotification.bookmarkUpdated)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                guard let self = self,
                      let userInfo = notification.userInfo,
                      let articleId = userInfo[BookmarkNotification.Keys.articleId] as? Int,
                      let isBookmarked = userInfo[BookmarkNotification.Keys.isBookmarked] as? Bool,
                      let index = self.articles.firstIndex(where: { $0.id == articleId }) else {
                    return
                }
                
                print("📢 Received bookmark update: article \(articleId) -> \(isBookmarked)")
                
                // Only update if different
                if self.articles[index].isBookmarked != isBookmarked {
                    self.articles[index].isBookmarked = isBookmarked
                    print("✅ Updated local article at index \(index)")
                    
                    // Re-apply filters to update UI
                    self.applyFilters(
                        searchText: self.searchText,
                        showBookmarkedOnly: self.showBookmarkedOnly
                    )
                }
            }
            .store(in: &cancellables)
    }
    
    private func handleError(_ error: Error) {
        let appError = error as? AppError ?? AppError.networkError(error)
        
        switch appError {
        case .offline:
            // Offline is not an error for offline-first app
            // We should show cached data with offline indicator
            errorMessage = "You're offline. Showing cached data."
            print("📵 Offline mode: \(errorMessage ?? "Unknown error")")
        default:
            errorMessage = appError.errorDescription
            print("❌ Error: \(appError.errorDescription ?? "Unknown error")")
        }
    }
    
    // MARK: - Computed Properties
    var shouldShowOfflineIndicator: Bool {
        isOffline && !articles.isEmpty
    }
    
    var shouldShowEmptyState: Bool {
        if case .empty = dataState { return true }
        return false
    }
    
    var shouldShowError: Bool {
        errorMessage != nil && articles.isEmpty
    }
}
