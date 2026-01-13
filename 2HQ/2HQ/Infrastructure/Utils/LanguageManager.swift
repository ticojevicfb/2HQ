import SwiftUI
import Foundation

extension Notification.Name {
    static let languageChanged = Notification.Name("languageChanged")
}

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @AppStorage("selectedLanguage") var currentLanguage: String = "en"
    
    private var currentBundle: Bundle?
    
    init() {
        updateBundle(for: currentLanguage)
    }
    
    func setLanguage(_ languageCode: String) {
        currentLanguage = languageCode
        
        UserDefaults.standard.set([languageCode], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        
        updateBundle(for: languageCode)
        
        NotificationCenter.default.post(name: .languageChanged, object: nil)
    }
    
    private func updateBundle(for languageCode: String) {
        if let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            currentBundle = bundle
        } else {
            currentBundle = Bundle.main
        }
    }
    
    func localizedString(_ key: String, comment: String = "") -> String {
        if let bundle = currentBundle {
            return bundle.localizedString(forKey: key, value: nil, table: nil)
        }
        return NSLocalizedString(key, comment: comment)
    }
    
    func localizedStringWithFormat(_ key: String, _ arg: CVarArg) -> String {
        let format = localizedString(key)
        return String(format: format, arg)
    }
    
    func localizedStringWithFormat(_ key: String, _ args: CVarArg...) -> String {
        let format = localizedString(key)
        return withVaList(args) { vaList in
            return NSString(format: format, arguments: vaList) as String
        }
    }
}
