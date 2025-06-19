import Foundation
import SwiftUI
import Combine

/// ViewModel for managing curriculum state and user interactions
/// Provides comprehensive access to all curriculum content and user progress
@MainActor
class CurriculumViewModel: ObservableObject {
    
    // MARK: - Published State
    @Published var selectedSection: CurriculumSection?
    @Published var selectedVocabulary: VocabularyItem?
    @Published var selectedDialogue: Dialogue?
    @Published var selectedAssessment: AssessmentQuestion?
    @Published var currentTab: CurriculumTab = .overview
    @Published var searchQuery = ""
    @Published var filterDifficulty: DifficultyLevel?
    @Published var filterSkill: SkillType?
    @Published var filterType: QuestionType?
    @Published var showCompletedOnly = false
    @Published var showFavoritesOnly = false
    @Published var isLoading = false
    @Published var currentLanguage: String = "en"
    
    // MARK: - Services
    private let curriculumService = CurriculumService()
    private let languageManager = LanguageManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    /// All sections from the curriculum
    var sections: [CurriculumSection] {
        curriculumService.sections
    }
    
    /// Main curriculum sections (excluding assessment-only sections)
    var mainSections: [CurriculumSection] {
        curriculumService.mainSections
    }
    
    /// All vocabulary items
    var allVocabulary: [VocabularyItem] {
        curriculumService.allVocabulary
    }
    
    /// All dialogues
    var allDialogues: [Dialogue] {
        curriculumService.allDialogues
    }
    
    /// All assessments
    var allAssessments: [AssessmentQuestion] {
        curriculumService.allAssessments
    }
    
    /// All tips
    var allTips: [String] {
        curriculumService.allTips
    }
    
    /// Curriculum statistics
    var stats: CurriculumStats {
        curriculumService.stats
    }
    
    /// Filtered sections based on current filters
    var filteredSections: [CurriculumSection] {
        var filtered = mainSections
        
        if filterDifficulty != nil {
            filtered = filtered.filter { $0.difficulty == filterDifficulty }
        }
        
        if showCompletedOnly {
            // TODO: Implement completion filtering
            // filtered = filtered.filter { isSectionCompleted($0.id) }
        }
        
        return filtered
    }
    
    /// Filtered vocabulary based on search and filters
    var filteredVocabulary: [VocabularyItem] {
        var filtered = allVocabulary
        
        if !searchQuery.isEmpty {
            filtered = filtered.filter { vocabulary in
                vocabulary.word.lowercased().contains(searchQuery.lowercased()) ||
                vocabulary.definition.lowercased().contains(searchQuery.lowercased()) ||
                vocabulary.translation.values.contains { $0.lowercased().contains(searchQuery.lowercased()) }
            }
        }
        
        if filterDifficulty != nil {
            // TODO: Implement difficulty filtering for vocabulary
            // filtered = filtered.filter { $0.difficulty == filterDifficulty }
        }
        
        return filtered
    }
    
    /// Filtered assessments based on current filters
    var filteredAssessments: [AssessmentQuestion] {
        var filtered = allAssessments
        
        if filterDifficulty != nil {
            filtered = filtered.filter { $0.difficulty == filterDifficulty }
        }
        
        if let skill = filterSkill {
            filtered = filtered.filter { $0.skillTested == skill }
        }
        
        if let type = filterType {
            filtered = filtered.filter { $0.type == type }
        }
        
        return filtered
    }
    
    /// Random vocabulary for practice
    var randomVocabulary: VocabularyItem? {
        curriculumService.randomVocabulary
    }
    
    /// Random dialogue for practice
    var randomDialogue: Dialogue? {
        curriculumService.randomDialogue
    }
    
    /// Random assessment for practice
    var randomAssessment: AssessmentQuestion? {
        curriculumService.randomAssessment
    }
    
    /// Random tip
    var randomTip: String? {
        curriculumService.randomTip
    }
    
    // MARK: - Initialization
    
    init() {
        setupObservers()
        
        // Load curriculum data
        Task {
            await curriculumService.loadCurriculum()
        }
    }
    
    // MARK: - Observers Setup
    
    private func setupObservers() {
        // Observe curriculum service loading state
        curriculumService.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: \.isLoading, on: self)
            .store(in: &cancellables)
        
        // Observe curriculum service language changes
        curriculumService.$currentLanguage
            .receive(on: DispatchQueue.main)
            .assign(to: \.currentLanguage, on: self)
            .store(in: &cancellables)
        
        // Observe curriculum changes and refresh UI
        curriculumService.$curriculum
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
                print("🔄 CurriculumViewModel updated with new curriculum data")
            }
            .store(in: &cancellables)
        
        // Observe language manager changes
        languageManager.$selectedLanguage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newLanguage in
                self?.currentLanguage = newLanguage.rawValue
                print("🌍 CurriculumViewModel detected language change to: \(newLanguage.rawValue)")
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Section Management
    
    /// Select a section for detailed view
    func selectSection(_ section: CurriculumSection) {
        selectedSection = section
        currentTab = .overview
    }
    
    /// Get assessment sections for a main section
    func getAssessmentSections(for mainSectionId: String) -> [CurriculumSection] {
        return curriculumService.getAssessmentSections(for: mainSectionId)
    }
    
    /// Get vocabulary for selected section
    var selectedSectionVocabulary: [VocabularyItem] {
        guard let section = selectedSection else { return [] }
        return curriculumService.getVocabulary(for: section.id)
    }
    
    /// Get dialogues for selected section
    var selectedSectionDialogues: [Dialogue] {
        guard let section = selectedSection else { return [] }
        return curriculumService.getDialogues(for: section.id)
    }
    
    /// Get assessments for selected section
    var selectedSectionAssessments: [AssessmentQuestion] {
        guard let section = selectedSection else { return [] }
        return curriculumService.getAssessments(for: section.id)
    }
    
    /// Get tips for selected section
    var selectedSectionTips: [String] {
        guard let section = selectedSection else { return [] }
        return curriculumService.getTips(for: section.id)
    }
    
    // MARK: - Vocabulary Management
    
    /// Select a vocabulary item for detailed view
    func selectVocabulary(_ vocabulary: VocabularyItem) {
        selectedVocabulary = vocabulary
    }
    
    /// Get translation for vocabulary in current language
    func getTranslation(for vocabulary: VocabularyItem) -> String {
        return curriculumService.getTranslation(for: vocabulary)
    }
    
    /// Get pronunciation for vocabulary
    func getPronunciation(for vocabulary: VocabularyItem) -> String {
        return curriculumService.getPronunciation(for: vocabulary)
    }
    
    /// Get example sentence for vocabulary
    func getExample(for vocabulary: VocabularyItem) -> String {
        return curriculumService.getExample(for: vocabulary)
    }
    
    /// Play audio for vocabulary
    func playVocabularyAudio(_ vocabulary: VocabularyItem) {
        curriculumService.playVocabularyAudio(vocabulary)
    }
    
    /// Check if vocabulary audio is playing
    func isVocabularyAudioPlaying(_ vocabulary: VocabularyItem) -> Bool {
        return curriculumService.isAudioPlaying(for: vocabulary.id.uuidString)
    }
    
    /// Toggle vocabulary audio playback
    func toggleVocabularyAudio(_ vocabulary: VocabularyItem) {
        curriculumService.toggleAudio(for: vocabulary.id.uuidString, fileName: vocabulary.audioFileName)
    }
    
    /// Mark vocabulary as mastered
    func markVocabularyMastered(_ vocabulary: VocabularyItem) {
        curriculumService.markVocabularyMastered(vocabulary.id.uuidString)
    }
    
    // MARK: - Dialogue Management
    
    /// Select a dialogue for detailed view
    func selectDialogue(_ dialogue: Dialogue) {
        selectedDialogue = dialogue
    }
    
    /// Play audio for dialogue exchange
    func playDialogueAudio(_ exchange: DialogueExchange) {
        curriculumService.playDialogueAudio(exchange)
    }
    
    /// Check if dialogue audio is playing
    func isDialogueAudioPlaying(_ exchange: DialogueExchange) -> Bool {
        return curriculumService.isAudioPlaying(for: exchange.id.uuidString)
    }
    
    /// Toggle dialogue audio playback
    func toggleDialogueAudio(_ exchange: DialogueExchange) {
        curriculumService.toggleAudio(for: exchange.id.uuidString, fileName: exchange.audioFileName)
    }
    
    /// Get dialogue exchanges for selected dialogue
    var selectedDialogueExchanges: [DialogueExchange] {
        return selectedDialogue?.exchanges ?? []
    }
    
    // MARK: - Assessment Management
    
    /// Select an assessment for detailed view
    func selectAssessment(_ assessment: AssessmentQuestion) {
        selectedAssessment = assessment
    }
    
    /// Play audio for assessment
    func playAssessmentAudio(_ assessment: AssessmentQuestion) {
        curriculumService.playAssessmentAudio(assessment)
    }
    
    /// Check if assessment audio is playing
    func isAssessmentAudioPlaying(_ assessment: AssessmentQuestion) -> Bool {
        return curriculumService.isAudioPlaying(for: assessment.id)
    }
    
    /// Toggle assessment audio playback
    func toggleAssessmentAudio(_ assessment: AssessmentQuestion) {
        curriculumService.toggleAudio(for: assessment.id, fileName: assessment.audioFileName)
    }
    
    /// Submit assessment answer
    func submitAssessmentAnswer(_ assessment: AssessmentQuestion, answer: String) -> Bool {
        let isCorrect = assessment.correctAnswer.lowercased() == answer.lowercased()
        
        if isCorrect {
            curriculumService.markAssessmentCompleted(assessment.id, score: 1.0)
        }
        
        return isCorrect
    }
    
    /// Get assessment options for multiple choice
    func getAssessmentOptions(_ assessment: AssessmentQuestion) -> [String] {
        return assessment.options ?? []
    }
    
    /// Check if assessment is multiple choice
    func isMultipleChoice(_ assessment: AssessmentQuestion) -> Bool {
        return assessment.type == .multipleChoice
    }
    
    /// Check if assessment is true/false
    func isTrueFalse(_ assessment: AssessmentQuestion) -> Bool {
        return assessment.type == .trueFalse
    }
    
    /// Check if assessment is fill in the blank
    func isFillInBlank(_ assessment: AssessmentQuestion) -> Bool {
        return assessment.type == .fillInBlank
    }
    
    /// Check if assessment is audio-based
    func isAudioBased(_ assessment: AssessmentQuestion) -> Bool {
        return assessment.type == .audioBased
    }
    
    /// Check if assessment is scenario response
    func isScenarioResponse(_ assessment: AssessmentQuestion) -> Bool {
        return assessment.type == .scenarioResponse
    }
    
    // MARK: - Progress Tracking
    
    /// Mark section as completed
    func markSectionCompleted(_ section: CurriculumSection) {
        curriculumService.markSectionCompleted(section.id)
    }
    
    /// Check if section is completed (placeholder)
    func isSectionCompleted(_ sectionId: String) -> Bool {
        // TODO: Implement actual progress tracking
        return false
    }
    
    /// Check if vocabulary is mastered (placeholder)
    func isVocabularyMastered(_ vocabularyId: String) -> Bool {
        // TODO: Implement actual progress tracking
        return false
    }
    
    /// Check if assessment is completed (placeholder)
    func isAssessmentCompleted(_ assessmentId: String) -> Bool {
        // TODO: Implement actual progress tracking
        return false
    }
    
    // MARK: - Search and Filtering
    
    /// Clear all filters
    func clearFilters() {
        filterDifficulty = nil
        filterSkill = nil
        filterType = nil
        showCompletedOnly = false
        showFavoritesOnly = false
    }
    
    /// Clear search query
    func clearSearch() {
        searchQuery = ""
    }
    
    // MARK: - Navigation
    
    /// Switch to a specific tab
    func switchToTab(_ tab: CurriculumTab) {
        currentTab = tab
    }
    
    /// Navigate to next section
    func nextSection() {
        guard let currentSection = selectedSection,
              let currentIndex = mainSections.firstIndex(where: { $0.id == currentSection.id }),
              currentIndex + 1 < mainSections.count else { return }
        
        selectedSection = mainSections[currentIndex + 1]
    }
    
    /// Navigate to previous section
    func previousSection() {
        guard let currentSection = selectedSection,
              let currentIndex = mainSections.firstIndex(where: { $0.id == currentSection.id }),
              currentIndex > 0 else { return }
        
        selectedSection = mainSections[currentIndex - 1]
    }
    
    // MARK: - Practice Mode
    
    /// Start practice mode with random content
    func startPracticeMode() {
        // Randomly select content for practice
        if let randomVocab = randomVocabulary {
            selectVocabulary(randomVocab)
            currentTab = .vocabulary
        } else if let randomDialogue = randomDialogue {
            selectDialogue(randomDialogue)
            currentTab = .dialogues
        } else if let randomAssessment = randomAssessment {
            selectAssessment(randomAssessment)
            currentTab = .assessments
        }
    }
    
    /// Get practice content based on type
    func getPracticeContent(type: PracticeType) -> Any {
        switch type {
        case .vocabulary:
            return randomVocabulary as Any
        case .dialogue:
            return randomDialogue as Any
        case .assessment:
            return randomAssessment as Any
        case .tip:
            return randomTip as Any
        }
    }
    
    // MARK: - Curriculum Loading
    @MainActor
    func reloadCurriculum() async {
        await curriculumService.reloadCurriculum()
    }
    @MainActor
    func loadCurriculum() async {
        await curriculumService.loadCurriculum()
    }
    
    // MARK: - Audio Manager Access
    
    /// Get audio manager for UI integration
    var audioManager: AudioManager {
        return curriculumService.audioManagerInstance
    }
    
    /// Stop all audio playback
    func stopAllAudio() {
        curriculumService.stopAudio()
    }
}

// MARK: - Supporting Types

enum CurriculumTab: String, CaseIterable {
    case overview = "Overview"
    case vocabulary = "Vocabulary"
    case dialogues = "Dialogues"
    case assessments = "Assessments"
    case tips = "Tips"
    case progress = "Progress"
    
    var icon: String {
        switch self {
        case .overview: return "book.fill"
        case .vocabulary: return "textformat"
        case .dialogues: return "bubble.left.and.bubble.right.fill"
        case .assessments: return "checkmark.circle.fill"
        case .tips: return "lightbulb.fill"
        case .progress: return "chart.bar.fill"
        }
    }
}

enum PracticeType: String, CaseIterable {
    case vocabulary = "Vocabulary"
    case dialogue = "Dialogue"
    case assessment = "Assessment"
    case tip = "Tip"
    
    var icon: String {
        switch self {
        case .vocabulary: return "textformat"
        case .dialogue: return "bubble.left.and.bubble.right.fill"
        case .assessment: return "checkmark.circle.fill"
        case .tip: return "lightbulb.fill"
        }
    }
}

// MARK: - Preview Helper
extension CurriculumViewModel {
    /// Create a mock instance for SwiftUI previews
    static var preview: CurriculumViewModel {
        let viewModel = CurriculumViewModel()
        
        // Set up some preview data
        if let firstSection = viewModel.sections.first {
            viewModel.selectSection(firstSection)
        }
        
        return viewModel
    }
} 