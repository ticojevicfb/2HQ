//
//  _HQApp.swift
//  2HQ
//
//  Created by Nikola Ticojevic on 11. 1. 2026..
//

import SwiftUI
import SwiftData

@main
struct TwoHQApp: App {
    @StateObject private var dependencies = DependencyContainer()
    @StateObject private var languageManager = LanguageManager.shared
    
    var body: some Scene {
        WindowGroup {
            ArticlesListView(viewModel: dependencies.makeArticlesViewModel())
                .environmentObject(dependencies)
                .environmentObject(languageManager)
        }
        .modelContainer(for: [ArticleEntity.self, CommentEntity.self])
    }
}
