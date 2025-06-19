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
    
    // MARK: - Private Properties
    private let languageManager = LanguageManager.shared
    
    // MARK: - Initialization
    init() {
        Task {
            await loadCurriculum()
        }
    }
    
    // MARK: - Public API
    
    /// Load the complete curriculum from JSON
    func loadCurriculum() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            guard let url = Bundle.main.url(forResource: "curriculum_complete", withExtension: "json") else {
                throw CurriculumError.fileNotFound
            }
            
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            curriculum = try decoder.decode(TrafficStopCourse.self, from: data)
            
            print("✅ Successfully loaded curriculum with \(curriculum?.sections.count ?? 0) sections")
            
        } catch {
            print("❌ Failed to load curriculum: \(error)")
            lastError = error
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
    
    // MARK: - Audio Management (Placeholder for future implementation)
    
    /// Play audio for vocabulary item
    func playVocabularyAudio(_ vocabulary: VocabularyItem) {
        // TODO: Implement audio playback
        print("🔊 Playing audio for vocabulary: \(vocabulary.word)")
    }
    
    /// Play audio for dialogue exchange
    func playDialogueAudio(_ exchange: DialogueExchange) {
        // TODO: Implement audio playback
        print("🔊 Playing audio for dialogue exchange")
    }
    
    /// Play audio for assessment question
    func playAssessmentAudio(_ assessment: AssessmentQuestion) {
        // TODO: Implement audio playback
        print("🔊 Playing audio for assessment: \(assessment.id)")
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