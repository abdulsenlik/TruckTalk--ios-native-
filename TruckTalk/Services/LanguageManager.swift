import Foundation
import SwiftUI

/// Manages language selection and localized content loading
@MainActor
class LanguageManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var selectedLanguage: SupportedLanguage {
        didSet {
            saveLanguagePreference()
            loadLocalizedContent()
        }
    }
    
    /// Computed property to expose current language (alias for selectedLanguage)
    var currentLanguage: SupportedLanguage {
        return selectedLanguage
    }
    
    @Published var isLoading = false
    @Published var availableLanguages: [SupportedLanguage] = SupportedLanguage.allCases
    @Published var contentVersion: String = "1.0.0"
    
    // MARK: - Singleton
    static let shared = LanguageManager()
    
    // MARK: - Storage Keys
    private let languageKey = "selectedLanguage"
    private let contentVersionKey = "contentVersion"
    
    // MARK: - Initialization
    init() {
        // Initialize with a default value first
        if let savedLanguageCode = UserDefaults.standard.string(forKey: languageKey),
           let savedLanguage = SupportedLanguage(rawValue: savedLanguageCode) {
            self.selectedLanguage = savedLanguage
        } else {
            // Use English as default during initialization
            self.selectedLanguage = .english
        }
        
        // Then detect and set the proper language if not saved
        if UserDefaults.standard.string(forKey: languageKey) == nil {
            self.selectedLanguage = detectDeviceLanguage()
        }
        
        loadLocalizedContent()
    }
    
    // MARK: - Language Detection
    private func detectDeviceLanguage() -> SupportedLanguage {
        let deviceLanguageCode = Locale.current.language.languageCode?.identifier ?? "en"
        
        // Map common device language codes to supported languages
        switch deviceLanguageCode {
        case "es": return .spanish
        case "tr": return .turkish
        case "ar": return .arabic
        case "pt": return .portuguese
        case "ru": return .russian
        default: return .english
        }
    }
    
    // MARK: - Language Management
    func changeLanguage(to language: SupportedLanguage) {
        guard language != selectedLanguage else { return }
        
        isLoading = true
        selectedLanguage = language
        
        // Add slight delay for UI feedback
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    private func saveLanguagePreference() {
        UserDefaults.standard.set(selectedLanguage.rawValue, forKey: languageKey)
    }
    
    // MARK: - Content Loading
    private func loadLocalizedContent() {
        // This will be called whenever language changes
        // Individual services will observe this and reload their content
        NotificationCenter.default.post(name: .languageChanged, object: selectedLanguage)
    }
    
    // MARK: - Localization Helpers
    
    /// Get localized text from a multilingual dictionary
    /// - Parameters:
    ///   - dictionary: Dictionary with language codes as keys
    ///   - fallbackToEnglish: Whether to fallback to English if selected language not found
    /// - Returns: Localized text or fallback
    func localizedText(from dictionary: [String: String], fallbackToEnglish: Bool = true) -> String {
        // Try selected language first
        if let localizedText = dictionary[selectedLanguage.rawValue] {
            return localizedText
        }
        
        // Fallback to English if available and requested
        if fallbackToEnglish, let englishText = dictionary["en"] {
            return englishText
        }
        
        // Return any available text or placeholder
        return dictionary.values.first ?? "Translation not available"
    }
    
    /// Get localized title from a BootcampDay
    func localizedTitle(for day: BootcampDay) -> String {
        return localizedText(from: day.title)
    }
    
    /// Get localized description from a BootcampDay
    func localizedDescription(for day: BootcampDay) -> String {
        return localizedText(from: day.description)
    }
    
    /// Get localized title from a LessonSection
    func localizedTitle(for section: LessonSection) -> String {
        return localizedText(from: section.title)
    }
    
    /// Get localized translation for lesson content
    func localizedTranslation(for content: LessonContent) -> String {
        return localizedText(from: content.translations)
    }
    
    /// Get localized translation for emergency phrase
    func localizedTranslation(for phrase: EmergencyPhrase) -> String {
        return localizedText(from: phrase.translations)
    }
    
    // MARK: - Audio File Helpers
    
    /// Get audio URL for content in selected language
    func audioUrl(for content: LessonContent) -> String? {
        // Try language-specific audio first
        if let audioUrls = content.audioUrls,
           let languageAudio = audioUrls[selectedLanguage.rawValue] {
            return languageAudio
        }
        
        // Fallback to default audio
        return content.audioFileName
    }
    
    /// Get audio URL for emergency phrase in selected language
    func audioUrl(for phrase: EmergencyPhrase) -> String? {
        // Try language-specific audio first
        if let audioUrls = phrase.audioUrls,
           let languageAudio = audioUrls[selectedLanguage.rawValue] {
            return languageAudio
        }
        
        // Fallback to default audio
        return phrase.audioFileName
    }
    
    // MARK: - Content Validation
    
    /// Check if content is available in selected language
    func isContentAvailable(for language: SupportedLanguage) -> Bool {
        return availableLanguages.contains(language)
    }
    
    /// Get completion percentage of translations for a language
    func translationCompleteness(for language: SupportedLanguage) -> Double {
        // This would be calculated based on actual content
        // For now, return full completion for supported languages
        return availableLanguages.contains(language) ? 1.0 : 0.0
    }
    
    // MARK: - Bundle Resource Loading
    
    /// Load JSON file for current language from app bundle
    /// - Parameter filename: Base filename without language suffix or extension
    /// - Returns: Data from the appropriate language file
    func loadLocalizedJSON(filename: String) -> Data? {
        // Try to load language-specific file first (e.g., "lessons_es.json")
        let languageSpecificFilename = "\(filename)_\(selectedLanguage.rawValue)"
        
        if let path = Bundle.main.path(forResource: languageSpecificFilename, ofType: "json"),
           let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
            return data
        }
        
        // Fallback to English file (e.g., "lessons_en.json")
        let englishFilename = "\(filename)_en"
        if let path = Bundle.main.path(forResource: englishFilename, ofType: "json"),
           let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
            return data
        }
        
        // Fallback to base filename (e.g., "lessons.json")
        if let path = Bundle.main.path(forResource: filename, ofType: "json"),
           let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
            return data
        }
        
        return nil
    }
    
    /// Decode localized JSON data to specified type
    /// - Parameters:
    ///   - type: Type to decode to
    ///   - filename: Base filename without language suffix
    /// - Returns: Decoded object or nil
    func loadLocalizedData<T: Codable>(_ type: T.Type, from filename: String) -> T? {
        guard let data = loadLocalizedJSON(filename: filename) else {
            print("⚠️ Could not load JSON file: \(filename)")
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(type, from: data)
        } catch {
            print("⚠️ Failed to decode \(filename): \(error)")
            return nil
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let languageChanged = Notification.Name("languageChanged")
}

// MARK: - SwiftUI Environment
@MainActor
struct LanguageManagerKey: EnvironmentKey {
    @preconcurrency
    static let defaultValue = LanguageManager.shared
}

extension EnvironmentValues {
    var languageManager: LanguageManager {
        get { self[LanguageManagerKey.self] }
        set { self[LanguageManagerKey.self] = newValue }
    }
}

// MARK: - View Modifier for Language Updates
struct LanguageChangeObserver: ViewModifier {
    let onLanguageChange: (SupportedLanguage) -> Void
    
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .languageChanged)) { notification in
                if let language = notification.object as? SupportedLanguage {
                    onLanguageChange(language)
                }
            }
    }
}

extension View {
    func onLanguageChange(_ action: @escaping (SupportedLanguage) -> Void) -> some View {
        modifier(LanguageChangeObserver(onLanguageChange: action))
    }
}

// MARK: - Model Extensions for Localization

extension BootcampDay {
    @MainActor 
    func localizedTitle(using languageManager: LanguageManager? = nil) -> String {
        let manager = languageManager ?? LanguageManager.shared
        return manager.localizedTitle(for: self)
    }
    
    @MainActor 
    func localizedDescription(using languageManager: LanguageManager? = nil) -> String {
        let manager = languageManager ?? LanguageManager.shared
        return manager.localizedDescription(for: self)
    }
}

extension LessonSection {
    @MainActor 
    func localizedTitle(using languageManager: LanguageManager? = nil) -> String {
        let manager = languageManager ?? LanguageManager.shared
        return manager.localizedTitle(for: self)
    }
}

extension LessonContent {
    @MainActor 
    func localizedTranslation(using languageManager: LanguageManager? = nil) -> String {
        let manager = languageManager ?? LanguageManager.shared
        return manager.localizedTranslation(for: self)
    }
    
    @MainActor 
    func audioUrl(using languageManager: LanguageManager? = nil) -> String? {
        let manager = languageManager ?? LanguageManager.shared
        return manager.audioUrl(for: self)
    }
}

extension EmergencyPhrase {
    @MainActor 
    func localizedTranslation(using languageManager: LanguageManager? = nil) -> String {
        let manager = languageManager ?? LanguageManager.shared
        return manager.localizedTranslation(for: self)
    }
    
    @MainActor 
    func audioUrl(using languageManager: LanguageManager? = nil) -> String? {
        let manager = languageManager ?? LanguageManager.shared
        return manager.audioUrl(for: self)
    }
} 