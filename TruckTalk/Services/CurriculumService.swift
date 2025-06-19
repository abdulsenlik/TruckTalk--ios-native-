import Foundation
import SwiftUI

/// Service for loading and managing the complete curriculum data
/// Provides access to all sections, vocabulary, dialogues, assessments, and tips
@MainActor
class CurriculumService: ObservableObject {
    
    // MARK: - Published State
    @Published var isLoading = false
    @Published var curriculum: TrafficStopCourse?
    @Published var lastError: Error?
    @Published var currentLanguage: String = "en"
    @Published var error: CurriculumError?
    
    // MARK: - Private Properties
    private let languageManager = LanguageManager.shared
    private var languageChangeObserver: NSObjectProtocol?
    private let audioManager = AudioManager()
    
    // MARK: - Initialization
    init() {
        setupLanguageChangeObserver()
        Task {
            await loadCurriculum()
        }
    }
    
    deinit {
        if let observer = languageChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Language Change Handling
    
    private func setupLanguageChangeObserver() {
        languageChangeObserver = NotificationCenter.default.addObserver(
            forName: .languageChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let newLanguage = notification.object as? SupportedLanguage else { return }
            
            print("🔄 Language changed to: \(newLanguage.rawValue)")
            
            Task { @MainActor in
                self.currentLanguage = newLanguage.rawValue
                await self.loadCurriculum()
            }
        }
    }
    
    // MARK: - Public API
    
    /// Load the complete curriculum from JSON with language-specific files and fallback
    func loadCurriculum() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let curriculum = try await loadCurriculumWithFallback()
            self.curriculum = curriculum
            
            print("✅ Successfully loaded curriculum for language '\(currentLanguage)'")
            print("📊 Found \(curriculum.sections.count) sections")
            print("📚 Total vocabulary: \(curriculum.sections.flatMap { $0.vocabulary }.count)")
            print("💬 Total dialogues: \(curriculum.sections.flatMap { $0.dialogues }.count)")
            print("📝 Total assessments: \(curriculum.sections.flatMap { $0.assessments }.count)")
            
        } catch {
            print("❌ Failed to load curriculum: \(error)")
            lastError = error
        }
    }
    
    /// Manually reload curriculum (useful for testing)
    func reloadCurriculum() async {
        print("🔄 Manually reloading curriculum...")
        await loadCurriculum()
    }
    
    /// Load curriculum with language-specific files and fallback to English
    private func loadCurriculumWithFallback() async throws -> TrafficStopCourse {
        let currentLang = languageManager.currentLanguage.rawValue
        
        // Try language-specific curriculum file first
        if let curriculum = try await loadCurriculumForLanguage(currentLang) {
            print("🌍 Loaded curriculum for language: \(currentLang)")
            return curriculum
        }
        
        // Fallback to English if current language is not English
        if currentLang != "en" {
            print("⚠️ No curriculum found for language '\(currentLang)', falling back to English")
            if let englishCurriculum = try await loadCurriculumForLanguage("en") {
                print("🇺🇸 Loaded English fallback curriculum")
                return englishCurriculum
            }
        }
        
        // Final fallback to the complete curriculum file
        print("⚠️ No language-specific curriculum found, using complete curriculum file")
        return try await loadCompleteCurriculum()
    }
    
    /// Load curriculum for a specific language
    private func loadCurriculumForLanguage(_ language: String) async throws -> TrafficStopCourse? {
        let filename = "curriculum_\(language)"
        
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            print("📁 No curriculum file found: \(filename).json")
            return nil
        }
        
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        do {
            let curriculum = try decoder.decode(TrafficStopCourse.self, from: data)
            print("📖 Loaded curriculum file: \(filename).json")
            return curriculum
        } catch {
            print("❌ Failed to decode curriculum file \(filename).json: \(error)")
            return nil
        }
    }
    
    /// Load the complete curriculum file as final fallback
    private func loadCompleteCurriculum() async throws -> TrafficStopCourse {
        guard let url = Bundle.main.url(forResource: "curriculum_complete", withExtension: "json") else {
            throw CurriculumError.fileNotFound
        }
        
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        do {
            let curriculum = try decoder.decode(TrafficStopCourse.self, from: data)
            print("📖 Loaded complete curriculum file: curriculum_complete.json")
            return curriculum
        } catch {
            print("❌ Failed to decode curriculum_complete.json: \(error)")
            throw error
        }
    }
    
    /// Get all sections
    var sections: [CurriculumSection] {
        curriculum?.sections ?? []
    }
    
    /// Get a specific section by ID
    func getSection(by id: String) -> CurriculumSection? {
        return sections.first { $0.id == id }
    }
    
    /// Get main curriculum sections (excluding assessment-only sections)
    var mainSections: [CurriculumSection] {
        return sections.filter { !$0.id.contains("-q") }
    }
    
    /// Get assessment sections for a specific main section
    func getAssessmentSections(for mainSectionId: String) -> [CurriculumSection] {
        return sections.filter { $0.id.starts(with: "\(mainSectionId)-q") }
    }
    
    /// Get all vocabulary items across all sections
    var allVocabulary: [VocabularyItem] {
        return sections.flatMap { $0.vocabulary }
    }
    
    /// Get vocabulary items for a specific section
    func getVocabulary(for sectionId: String) -> [VocabularyItem] {
        return getSection(by: sectionId)?.vocabulary ?? []
    }
    
    /// Get all dialogues across all sections
    var allDialogues: [Dialogue] {
        return sections.flatMap { $0.dialogues }
    }
    
    /// Get dialogues for a specific section
    func getDialogues(for sectionId: String) -> [Dialogue] {
        return getSection(by: sectionId)?.dialogues ?? []
    }
    
    /// Get all assessments across all sections
    var allAssessments: [AssessmentQuestion] {
        return sections.flatMap { $0.assessments }
    }
    
    /// Get assessments for a specific section
    func getAssessments(for sectionId: String) -> [AssessmentQuestion] {
        return getSection(by: sectionId)?.assessments ?? []
    }
    
    /// Get all tips across all sections
    var allTips: [String] {
        return sections.flatMap { $0.tips }
    }
    
    /// Get tips for a specific section
    func getTips(for sectionId: String) -> [String] {
        return getSection(by: sectionId)?.tips ?? []
    }
    
    /// Get curriculum statistics
    var stats: CurriculumStats {
        let totalSections = sections.count
        let totalVocabulary = allVocabulary.count
        let totalDialogues = allDialogues.count
        let totalAssessments = allAssessments.count
        let totalTips = allTips.count
        let estimatedTotalMinutes = sections.reduce(0) { $0 + $1.estimatedMinutes }
        
        return CurriculumStats(
            totalSections: totalSections,
            totalVocabulary: totalVocabulary,
            totalDialogues: totalDialogues,
            totalAssessments: totalAssessments,
            totalTips: totalTips,
            estimatedTotalMinutes: estimatedTotalMinutes
        )
    }
    
    /// Search vocabulary by word or translation
    func searchVocabulary(query: String) -> [VocabularyItem] {
        let lowercasedQuery = query.lowercased()
        
        return allVocabulary.filter { vocabulary in
            vocabulary.word.lowercased().contains(lowercasedQuery) ||
            vocabulary.definition.lowercased().contains(lowercasedQuery) ||
            vocabulary.translation.values.contains { $0.lowercased().contains(lowercasedQuery) }
        }
    }
    
    /// Get vocabulary by difficulty level
    func getVocabularyByDifficulty(_ difficulty: DifficultyLevel) -> [VocabularyItem] {
        // For now, return all vocabulary since difficulty is not specified per vocabulary item
        // In a future enhancement, we could add difficulty to vocabulary items
        return allVocabulary
    }
    
    /// Get assessments by type
    func getAssessmentsByType(_ type: QuestionType) -> [AssessmentQuestion] {
        return allAssessments.filter { $0.type == type }
    }
    
    /// Get assessments by skill tested
    func getAssessmentsBySkill(_ skill: SkillType) -> [AssessmentQuestion] {
        return allAssessments.filter { $0.skillTested == skill }
    }
    
    /// Get assessments by difficulty
    func getAssessmentsByDifficulty(_ difficulty: DifficultyLevel) -> [AssessmentQuestion] {
        return allAssessments.filter { $0.difficulty == difficulty }
    }
    
    /// Get sections by difficulty
    func getSectionsByDifficulty(_ difficulty: DifficultyLevel) -> [CurriculumSection] {
        return sections.filter { $0.difficulty == difficulty }
    }
    
    /// Get translation for current language
    func getTranslation(for vocabulary: VocabularyItem) -> String {
        let currentLanguage = languageManager.currentLanguage.rawValue
        return vocabulary.translation[currentLanguage] ?? vocabulary.word
    }
    
    /// Get pronunciation guide for vocabulary
    func getPronunciation(for vocabulary: VocabularyItem) -> String {
        return vocabulary.pronunciation
    }
    
    /// Get example sentence for vocabulary
    func getExample(for vocabulary: VocabularyItem) -> String {
        return vocabulary.example
    }
    
    // MARK: - Progress Tracking (Placeholder for future implementation)
    
    /// Mark a section as completed
    func markSectionCompleted(_ sectionId: String) {
        // TODO: Implement progress tracking with UserDefaults or Core Data
        print("📝 Marked section \(sectionId) as completed")
    }
    
    /// Mark vocabulary as mastered
    func markVocabularyMastered(_ vocabularyId: String) {
        // TODO: Implement progress tracking
        print("📝 Marked vocabulary \(vocabularyId) as mastered")
    }
    
    /// Mark assessment as completed
    func markAssessmentCompleted(_ assessmentId: String, score: Double) {
        // TODO: Implement progress tracking
        print("📝 Marked assessment \(assessmentId) as completed with score \(score)")
    }
    
    // MARK: - Audio Management
    
    /// Play audio for vocabulary item
    func playVocabularyAudio(_ vocabulary: VocabularyItem) {
        if let audioFileName = vocabulary.audioFileName {
            audioManager.playAudio(fileName: audioFileName, audioId: vocabulary.id.uuidString)
        } else {
            // Fallback to mock audio for testing
            audioManager.playAudio(fileName: vocabulary.word.lowercased().replacingOccurrences(of: " ", with: "_"), audioId: vocabulary.id.uuidString)
        }
    }
    
    /// Play audio for dialogue exchange
    func playDialogueAudio(_ exchange: DialogueExchange) {
        if let audioFileName = exchange.audioFileName {
            audioManager.playAudio(fileName: audioFileName, audioId: exchange.id.uuidString)
        } else {
            // Fallback to mock audio for testing
            audioManager.playAudio(fileName: "dialogue_\(exchange.id.uuidString.prefix(8))", audioId: exchange.id.uuidString)
        }
    }
    
    /// Play audio for assessment question
    func playAssessmentAudio(_ assessment: AssessmentQuestion) {
        if let audioFileName = assessment.audioFileName {
            audioManager.playAudio(fileName: audioFileName, audioId: assessment.id)
        } else {
            // Fallback to mock audio for testing
            audioManager.playAudio(fileName: "assessment_\(assessment.id.prefix(8))", audioId: assessment.id)
        }
    }
    
    /// Get audio manager for UI integration
    var audioManagerInstance: AudioManager {
        return audioManager
    }
    
    /// Check if audio is currently playing for a specific item
    func isAudioPlaying(for audioId: String) -> Bool {
        return audioManager.currentAudioId == audioId && audioManager.isPlaying
    }
    
    /// Stop current audio playback
    func stopAudio() {
        audioManager.stopAudio()
    }
    
    /// Toggle audio playback for a specific item
    func toggleAudio(for audioId: String, fileName: String?) {
        if audioManager.currentAudioId == audioId && audioManager.isPlaying {
            audioManager.pauseAudio()
        } else if audioManager.currentAudioId == audioId && !audioManager.isPlaying {
            audioManager.resumeAudio()
        } else {
            if let fileName = fileName {
                audioManager.playAudio(fileName: fileName, audioId: audioId)
            } else {
                audioManager.playAudio(fileName: audioId, audioId: audioId)
            }
        }
    }
}

// MARK: - Curriculum Errors

enum CurriculumError: LocalizedError {
    case fileNotFound
    case invalidData
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Curriculum file not found"
        case .invalidData:
            return "Invalid curriculum data"
        case .decodingError:
            return "Failed to decode curriculum data"
        }
    }
}

// MARK: - Extensions for Convenience

extension CurriculumService {
    /// Get a random vocabulary item for practice
    var randomVocabulary: VocabularyItem? {
        return allVocabulary.randomElement()
    }
    
    /// Get a random dialogue for practice
    var randomDialogue: Dialogue? {
        return allDialogues.randomElement()
    }
    
    /// Get a random assessment for practice
    var randomAssessment: AssessmentQuestion? {
        return allAssessments.randomElement()
    }
    
    /// Get a random tip
    var randomTip: String? {
        return allTips.randomElement()
    }
}

// MARK: - Preview Helper
extension CurriculumService {
    /// Create a mock instance for SwiftUI previews
    static var preview: CurriculumService {
        let service = CurriculumService()
        
        // Create mock traffic stop course
        let mockSection = CurriculumSection(
            id: "preview-section",
            title: "Preview Section",
            description: "A preview section for testing",
            vocabulary: [
                VocabularyItem(
                    word: "test",
                    translation: ["en": "test"],
                    definition: "A test word",
                    pronunciation: "TEST",
                    example: "This is a test.",
                    audioFileName: nil
                )
            ],
            dialogues: [],
            tips: ["This is a preview tip"],
            assessments: [],
            estimatedMinutes: 15,
            difficulty: .beginner
        )
        
        let mockCourse = TrafficStopCourse(
            version: "1.0.0",
            lastUpdated: "2024-01-15",
            sections: [mockSection]
        )
        
        service.curriculum = mockCourse
        return service
    }
} 