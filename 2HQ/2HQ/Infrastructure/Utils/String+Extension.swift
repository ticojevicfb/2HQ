//
//  String+Extension.swift
//  2HQ
//
//  Created by Nikola Ticojevic on 13. 1. 2026..
//

import Foundation

extension String {
    func localized(using languageManager: LanguageManager? = nil) -> String {
        if let manager = languageManager {
            return manager.localizedString(self)
        }
        return NSLocalizedString(self, comment: "")
    }
    
    // For single argument
    func localized(using languageManager: LanguageManager? = nil, _ arg: CVarArg) -> String {
        let format = localized(using: languageManager)
        return String(format: format, arg)
    }
    
    // For multiple arguments
    func localized(using languageManager: LanguageManager? = nil, _ args: CVarArg...) -> String {
        let format = localized(using: languageManager)
        return String(format: format, arguments: args)
    }
}
