import SwiftUI

struct ArticlesListView: View {
    @StateObject private var viewModel: ArticlesViewModel
    @EnvironmentObject private var dependencies: DependencyContainer
    @EnvironmentObject private var languageManager: LanguageManager
    
    @State private var showingErrorAlert = false
    @State private var refreshID = UUID()
    
    init(viewModel: ArticlesViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Offline Banner
                if viewModel.shouldShowOfflineIndicator {
                    offlineBanner
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(offlineBannerAccessibilityLabel)
                        .accessibilityHint(offlineBannerAccessibilityHint)
                }
                
                // Main Content Area
                mainContent
            }
            .navigationTitle("navigationTitle".localized(using: languageManager))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                // Leading: Loading indicator
                ToolbarItem(placement: .navigationBarLeading) {
                    if viewModel.isLoading && !viewModel.shouldShowOfflineIndicator {
                        ProgressView()
                            .scaleEffect(0.8)
                            .accessibilityLabel("loading_articles".localized(using: languageManager))
                    }
                }
                
                // Center: Language switcher buttons
                ToolbarItem(placement: .principal) {
                    languageSwitcherButtons
                        .accessibilityElement(children: .contain)
                        .accessibilityLabel("language_switcher".localized(using: languageManager))
                }
                
                // Trailing: Filter button
                ToolbarItem(placement: .navigationBarTrailing) {
                    filterButton
                }
            }
            .searchable(
                text: $viewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "search_prompt".localized(using: languageManager)
            )
            .searchPresentationToolbarBehavior(.avoidHidingContent)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("search_articles".localized(using: languageManager))
            .refreshable {
                await viewModel.refresh()
            }
            .accessibilityAction(named: "refresh_articles".localized(using: languageManager)) {
                Task { await viewModel.refresh() }
            }
            .alert("error_title".localized(using: languageManager),
                   isPresented: $showingErrorAlert) {
                Button("ok_button".localized(using: languageManager), role: .cancel) { }
                Button("retry_button".localized(using: languageManager)) {
                    Task { await viewModel.refresh() }
                }
            } message: {
                Text(viewModel.errorMessage ?? "generic_error".localized(using: languageManager))
            }
            .onChange(of: viewModel.errorMessage) { _, newValue in
                if let errorMessage = newValue,
                   !errorMessage.lowercased().contains("offline") &&
                   !errorMessage.lowercased().contains("cached") {
                    showingErrorAlert = true
                }
            }
        }
        .id(refreshID)
        .tint(.blue)
        .task {
            await viewModel.loadArticles()
        }
        .onAppear {
            Task {
                await viewModel.loadArticles()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .languageChanged)) { _ in
            refreshID = UUID()
        }
    }
    
    // MARK: - Accessibility Labels
    private var offlineBannerAccessibilityLabel: String {
        return "\("offline_title".localized(using: languageManager)). \("offline_message".localized(using: languageManager))"
    }
    
    private var offlineBannerAccessibilityHint: String {
        return "retry_button".localized(using: languageManager)
    }
    
    private var filterButtonAccessibilityLabel: String {
        return viewModel.showBookmarkedOnly ?
            "show_all_articles".localized(using: languageManager) :
            "show_bookmarks_only".localized(using: languageManager)
    }
    
    private var filterButtonAccessibilityHint: String {
        return "double_tap_to_filter".localized(using: languageManager)
    }
    
    // MARK: - Main Content
    private var mainContent: some View {
        Group {
            switch viewModel.dataState {
            case .loading:
                LoadingView()
                    .frame(maxHeight: .infinity)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("loading_articles".localized(using: languageManager))
                
            case .loaded(let articles):
                if articles.isEmpty && !viewModel.searchText.isEmpty {
                    EmptyStateView(
                        title: "no_results_title".localized(using: languageManager),
                        message: "no_results_message".localized(using: languageManager),
                        systemImage: "magnifyingglass"
                    )
                    .frame(maxHeight: .infinity)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(emptySearchResultsAccessibilityLabel)
                } else {
                    articleList(articles: articles)
                }
                
            case .empty:
                EmptyStateView(
                    title: viewModel.showBookmarkedOnly ?
                        "no_bookmarks_title".localized(using: languageManager) :
                        "no_articles_title".localized(using: languageManager),
                    message: viewModel.showBookmarkedOnly ?
                        "bookmark_hint".localized(using: languageManager) :
                        "refresh_hint".localized(using: languageManager),
                    systemImage: viewModel.showBookmarkedOnly ? "bookmark" : "doc.text"
                )
                .frame(maxHeight: .infinity)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(emptyStateAccessibilityLabel)
                
            case .error(let error):
                ErrorView(
                    error: error,
                    retryAction: {
                        Task { await viewModel.refresh() }
                    }
                )
                .frame(maxHeight: .infinity)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("error_loading_articles".localized(using: languageManager))
                .accessibilityHint("double_tap_to_retry".localized(using: languageManager))
                .accessibilityAction(named: "retry".localized(using: languageManager)) {
                    Task { await viewModel.refresh() }
                }
            }
        }
    }
    
    private var emptySearchResultsAccessibilityLabel: String {
        return "\("no_results_title".localized(using: languageManager)). \("no_results_message".localized(using: languageManager))"
    }
    
    private var emptyStateAccessibilityLabel: String {
        let title = viewModel.showBookmarkedOnly ?
            "no_bookmarks_title".localized(using: languageManager) :
            "no_articles_title".localized(using: languageManager)
        let message = viewModel.showBookmarkedOnly ?
            "bookmark_hint".localized(using: languageManager) :
            "refresh_hint".localized(using: languageManager)
        return "\(title). \(message)"
    }
    
    private func articleList(articles: [Article]) -> some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(articles) { article in
                    NavigationLink {
                        ArticleDetailsView(
                            viewModel: dependencies.makeArticleDetailsViewModel(
                                articleId: article.id
                            )
                        )
                    } label: {
                        ArticleCellView(
                            article: article,
                            onBookmarkTapped: {
                                Task { await viewModel.toggleBookmark(for: article.id) }
                            }
                        )
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(articleCellAccessibilityLabel(for: article))
                        .accessibilityHint("double_tap_to_view_details".localized(using: languageManager))
                        .accessibilityAddTraits(.isButton)
                        .accessibilityAction(named: "toggle_bookmark".localized(using: languageManager)) {
                            Task { await viewModel.toggleBookmark(for: article.id) }
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityRemoveTraits(.isButton) // Remove from NavigationLink
                }
            }
            .padding(.vertical, 8)
        }
        .background(Color(.systemGroupedBackground))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("articles_list".localized(using: languageManager))
        .accessibilityHint("\(articles.count) " + (articles.count == 1 ?
            "article_available".localized(using: languageManager) :
            "articles_available".localized(using: languageManager)))
    }
    
    private func articleCellAccessibilityLabel(for article: Article) -> String {
        var label = "\(article.title). "
        label += "by \(article.author.name). "
        label += "last updated \(formatDateForAccessibility(article.lastUpdated)). "
        
        if article.comments?.isEmpty == false {
            let commentCount = article.comments?.count ?? 0
            label += "\(commentCount) " + (commentCount == 1 ?
                "comment".localized(using: languageManager) :
                "comments".localized(using: languageManager)) + ". "
        }
        
        if article.isBookmarked {
            label += "bookmarked".localized(using: languageManager) + ". "
        }
        
        return label
    }
    
    private func formatDateForAccessibility(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: languageManager.currentLanguage)
        return formatter.string(from: date)
    }
    
    // MARK: - Language Switcher Buttons
    private var languageSwitcherButtons: some View {
        HStack(spacing: 8) {
            // English Button
            Button(action: {
                languageManager.setLanguage("en")
                UIAccessibility.post(notification: .announcement,
                                   argument: "language_changed_to_english".localized(using: languageManager))
            }) {
                languageButtonView(
                    code: "EN",
                    isSelected: languageManager.currentLanguage == "en"
                )
                .accessibilityLabel("switch_to_english".localized(using: languageManager))
                .accessibilityHint("current_language".localized(using: languageManager))
                .accessibilityAddTraits(languageManager.currentLanguage == "en" ? [.isSelected, .isButton] : .isButton)
            }
            
            // Serbian Button
            Button(action: {
                languageManager.setLanguage("sr")
                UIAccessibility.post(notification: .announcement,
                                   argument: "language_changed_to_serbian".localized(using: languageManager))
            }) {
                languageButtonView(
                    code: "SR",
                    isSelected: languageManager.currentLanguage == "sr"
                )
                .accessibilityLabel("switch_to_serbian".localized(using: languageManager))
                .accessibilityHint("current_language".localized(using: languageManager))
                .accessibilityAddTraits(languageManager.currentLanguage == "sr" ? [.isSelected, .isButton] : .isButton)
            }
        }
        .buttonStyle(.plain)
    }
    
    private func languageButtonView(code: String, isSelected: Bool) -> some View {
        Text(code)
            .font(.system(size: 14, weight: isSelected ? .bold : .medium))
            .foregroundColor(isSelected ? .white : .primary)
            .frame(width: 32, height: 32)
            .background(
                Circle()
                    .fill(isSelected ? Color.blue : Color.gray.opacity(0.15))
            )
            .overlay(
                Circle()
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1)
            )
    }
    
    // MARK: - Filter Button
    private var filterButton: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.showBookmarkedOnly.toggle()
            }
            // Announce filter change to VoiceOver
            let announcement = viewModel.showBookmarkedOnly ?
                "showing_bookmarks_only".localized(using: languageManager) :
                "showing_all_articles".localized(using: languageManager)
            UIAccessibility.post(notification: .announcement, argument: announcement)
        } label: {
            Label(
                viewModel.showBookmarkedOnly ?
                    "show_all_button".localized(using: languageManager) :
                    "bookmarks_button".localized(using: languageManager),
                systemImage: viewModel.showBookmarkedOnly ?
                    "bookmark.fill" : "bookmark"
            )
            .font(.subheadline)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(viewModel.showBookmarkedOnly ?
                         Color.blue.opacity(0.15) :
                         Color.gray.opacity(0.1))
            )
            .foregroundColor(viewModel.showBookmarkedOnly ? .blue : .primary)
        }
        .accessibilityLabel(filterButtonAccessibilityLabel)
        .accessibilityHint(filterButtonAccessibilityHint)
        .accessibilityAddTraits(.isButton)
    }
    
    // MARK: - Offline Banner
    private var offlineBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "wifi.slash")
                .font(.caption)
                .foregroundColor(.orange)
                .accessibilityHidden(true) // Hidden because label includes this info
            
            VStack(alignment: .leading, spacing: 2) {
                Text("offline_title".localized(using: languageManager))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
                    .accessibilityHidden(true)
                
                Text("offline_message".localized(using: languageManager))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)
            }
            
            Spacer()
            
            Button("retry_button".localized(using: languageManager)) {
                Task { await viewModel.refresh() }
            }
            .font(.caption)
            .fontWeight(.medium)
            .buttonStyle(.bordered)
            .controlSize(.mini)
            .tint(.orange)
            .accessibilityLabel("retry_connection".localized(using: languageManager))
            .accessibilityHint("double_tap_to_retry_connection".localized(using: languageManager))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Color.orange.opacity(0.08)
                .overlay(
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundColor(Color.orange.opacity(0.2)),
                    alignment: .bottom
                )
        )
        .transition(.move(edge: .top))
    }
}
