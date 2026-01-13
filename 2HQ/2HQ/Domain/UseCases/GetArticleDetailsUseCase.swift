//
//  GetArticleDetailsUseCase.swift
//  2HQ
//
//  Created by Nikola Ticojevic on 12. 1. 2026..
//

import Foundation

class GetArticleDetailsUseCase {
    private let repository: ArticleRepositoryProtocol
    
    init(repository: ArticleRepositoryProtocol) {
        self.repository = repository
    }
    
    func execute(articleId: Int) async throws -> Article {
        return try await repository.fetchArticleDetails(id: articleId)
    }
}
