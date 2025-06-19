import Foundation

// MARK: - Language Management
enum SupportedLanguage: String, CaseIterable, Codable {
    case english = "en"
    case spanish = "es"
    case turkish = "tr"
    case arabic = "ar"
    case portuguese = "pt"
    case russian = "ru"
    case kyrgyz = "ky"
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Español"
        case .turkish: return "Türkçe"
        case .arabic: return "العربية"
        case .portuguese: return "Português"
        case .russian: return "Русский"
        case .kyrgyz: return "Кыргызча"
        }
    }
    
    var flag: String {
        switch self {
        case .english: return "🇺🇸"
        case .spanish: return "🇪🇸"
        case .turkish: return "🇹🇷"
        case .arabic: return "🇸🇦"
        case .portuguese: return "🇧🇷"
        case .russian: return "🇷🇺"
        case .kyrgyz: return "🇰🇬"
        }
    }
}

// MARK: - Core Educational Models

struct TruckTalkBootcamp: Codable {
    let id: String
    let title: [String: String] // Language code to title
    let description: [String: String]
    let totalDays: Int
    let estimatedHours: Int
    let difficulty: DifficultyLevel
    let days: [BootcampDay]
}

enum DifficultyLevel: String, Codable, CaseIterable {
    case beginner = "beginner"
    case intermediate = "intermediate" 
    case advanced = "advanced"
    
    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        }
    }
    
    var icon: String {
        switch self {
        case .beginner: return "1.circle.fill"
        case .intermediate: return "2.circle.fill"
        case .advanced: return "3.circle.fill"
        }
    }
}

struct BootcampDay: Identifiable, Codable {
    let id: Int
    let title: [String: String] // Multilingual titles
    let description: [String: String] // Multilingual descriptions
    let isUnlocked: Bool
    let completionPercentage: Double
    let estimatedMinutes: Int
    let sections: [LessonSection]
    let objectives: [String: [String]] // Learning objectives per language
}

struct LessonSection: Identifiable, Codable {
    let id: String
    let type: SectionType
    let title: [String: String]
    let description: [String: String]?
    let content: [LessonContent]
    let estimatedMinutes: Int
}

enum SectionType: String, Codable, CaseIterable {
    case vocabulary = "vocabulary"
    case dialogue = "dialogue"
    case pronunciation = "pronunciation"
    case assessment = "assessment"
    case homework = "homework"
    case quiz = "quiz"
    case roleplay = "roleplay"
    case listening = "listening"
    
    var displayName: String {
        switch self {
        case .vocabulary: return "Vocabulary"
        case .dialogue: return "Dialogue Practice"
        case .pronunciation: return "Pronunciation"
        case .assessment: return "Assessment"
        case .homework: return "Homework"
        case .quiz: return "Quiz"
        case .roleplay: return "Role Play"
        case .listening: return "Listening"
        }
    }
    
    var icon: String {
        switch self {
        case .vocabulary: return "book.fill"
        case .dialogue: return "bubble.left.and.bubble.right.fill"
        case .pronunciation: return "speaker.wave.3.fill"
        case .assessment: return "checkmark.circle.fill"
        case .homework: return "pencil.and.outline"
        case .quiz: return "questionmark.circle.fill"
        case .roleplay: return "theatermasks.fill"
        case .listening: return "ear.fill"
        }
    }
}

struct LessonContent: Identifiable, Codable {
    let id: String
    let englishText: String
    let translations: [String: String] // Language code to translation
    let audioFileName: String?
    let audioUrls: [String: String]? // Language-specific audio files
    let isCompleted: Bool
    let isFavorited: Bool
    let contentType: ContentType
    let difficulty: DifficultyLevel
    let tags: [String]
}

enum ContentType: String, Codable, CaseIterable {
    case phrase = "phrase"
    case dialogue = "dialogue"
    case vocabulary = "vocabulary"
    case grammar = "grammar"
    case cultural = "cultural"
    case safety = "safety"
    
    var displayName: String {
        switch self {
        case .phrase: return "Phrase"
        case .dialogue: return "Dialogue"
        case .vocabulary: return "Vocabulary"
        case .grammar: return "Grammar"
        case .cultural: return "Cultural Note"
        case .safety: return "Safety"
        }
    }
}

// MARK: - Emergency Phrases (Enhanced)

struct EmergencyPhraseCollection: Codable {
    let version: String
    let lastUpdated: String
    let categories: [String: [EmergencyPhrase]]
    
    enum CodingKeys: String, CodingKey {
        case version
        case lastUpdated
        case categories
    }
}

struct EmergencyPhrase: Identifiable, Codable {
    let id: String
    let category: EmergencyCategory
    let englishText: String
    let translations: [String: String] // Language code to translation
    let audioFileName: String
    let audioUrls: [String: String]? // Language-specific audio
    let priority: Int
    let urgencyLevel: UrgencyLevel
    let contextNotes: [String: String]? // Usage context per language
    let relatedPhrases: [String]? // IDs of related phrases
}

enum UrgencyLevel: String, Codable, CaseIterable {
    case critical = "critical"
    case high = "high"
    case medium = "medium"
    case low = "low"
    
    var color: String {
        switch self {
        case .critical: return "red"
        case .high: return "orange" 
        case .medium: return "yellow"
        case .low: return "green"
        }
    }
    
    var icon: String {
        switch self {
        case .critical: return "exclamationmark.triangle.fill"
        case .high: return "exclamationmark.circle.fill"
        case .medium: return "info.circle.fill"
        case .low: return "checkmark.circle.fill"
        }
    }
}

enum EmergencyCategory: String, Codable, CaseIterable {
    case policeStop = "police_stop"
    case vehicleTrouble = "vehicle_trouble"
    case medicalEmergency = "medical_emergency"
    case roadAssistance = "road_assistance"
    case communication = "communication"
    case weatherEmergency = "weather_emergency"
    case accidentReport = "accident_report"
    case loadingUnloading = "loading_unloading"
    case cbRadio = "cb_radio"
    case truckStop = "truck_stop"
    
    var displayName: String {
        switch self {
        case .policeStop: return "Police Stop"
        case .vehicleTrouble: return "Vehicle Trouble"
        case .medicalEmergency: return "Medical Emergency"
        case .roadAssistance: return "Road Assistance"
        case .communication: return "Communication"
        case .weatherEmergency: return "Weather Emergency"
        case .accidentReport: return "Accident Report"
        case .loadingUnloading: return "Loading/Unloading"
        case .cbRadio: return "CB Radio"
        case .truckStop: return "Truck Stop"
        }
    }
    
    var icon: String {
        switch self {
        case .policeStop: return "car.fill"
        case .vehicleTrouble: return "wrench.and.screwdriver.fill"
        case .medicalEmergency: return "cross.fill"
        case .roadAssistance: return "phone.fill"
        case .communication: return "message.fill"
        case .weatherEmergency: return "cloud.rain.fill"
        case .accidentReport: return "exclamationmark.triangle.fill"
        case .loadingUnloading: return "shippingbox.fill"
        case .cbRadio: return "antenna.radiowaves.left.and.right"
        case .truckStop: return "fuelpump.fill"
        }
    }
    
    var color: String {
        switch self {
        case .policeStop: return "blue"
        case .vehicleTrouble: return "orange"
        case .medicalEmergency: return "red"
        case .roadAssistance: return "green"
        case .communication: return "purple"
        case .weatherEmergency: return "gray"
        case .accidentReport: return "red"
        case .loadingUnloading: return "brown"
        case .cbRadio: return "indigo"
        case .truckStop: return "cyan"
        }
    }
}

// MARK: - Quiz System

struct Quiz: Identifiable, Codable {
    let id: String
    let title: [String: String]
    let description: [String: String]
    let questions: [QuizQuestion]
    let passingScore: Int
    let timeLimit: Int? // seconds
    let difficulty: DifficultyLevel
    let category: QuizCategory
}

enum QuizCategory: String, Codable, CaseIterable {
    case vocabulary = "vocabulary"
    case grammar = "grammar" 
    case listening = "listening"
    case emergency = "emergency"
    case general = "general"
    case final = "final"
    
    var displayName: String {
        switch self {
        case .vocabulary: return "Vocabulary"
        case .grammar: return "Grammar"
        case .listening: return "Listening"
        case .emergency: return "Emergency"
        case .general: return "General"
        case .final: return "Final Assessment"
        }
    }
}

struct QuizQuestion: Identifiable, Codable {
    let id: String
    let type: QuestionType
    let question: [String: String]
    let options: [QuizOption]
    let correctAnswerIds: [String]
    let explanation: [String: String]?
    let audioFileName: String?
    let points: Int
}

enum QuestionType: String, Codable, CaseIterable {
    case multipleChoice = "multiple_choice"
    case multipleAnswer = "multiple_answer"
    case trueFalse = "true_false"
    case fillInBlank = "fill_in_blank"
    case matching = "matching"
    case listening = "listening"
    case ordering = "ordering"
    
    var displayName: String {
        switch self {
        case .multipleChoice: return "Multiple Choice"
        case .multipleAnswer: return "Multiple Answer"
        case .trueFalse: return "True/False"
        case .fillInBlank: return "Fill in the Blank"
        case .matching: return "Matching"
        case .listening: return "Listening"
        case .ordering: return "Put in Order"
        }
    }
}

struct QuizOption: Identifiable, Codable {
    let id: String
    let text: [String: String]
    let audioFileName: String?
    let isCorrect: Bool
}

// MARK: - User Progress (Enhanced)

struct UserProgress: Codable {
    var completedLessons: Set<String>
    var favoritePhrases: Set<String>
    var currentDay: Int
    var streak: Int
    var totalMinutesStudied: Double
    var selectedLanguage: SupportedLanguage
    var quizScores: [String: QuizResult] // Quiz ID to result
    var achievements: [Achievement]
    var lastStudyDate: Date?
    var weeklyGoalMinutes: Int
    var weeklyProgressMinutes: Int
    
    // Subscription & Premium Features
    var subscriptionTier: SubscriptionTier
    var subscriptionExpiryDate: Date?
    var downloadedContent: Set<String> // IDs of downloaded modules
    var aiCoachSessions: Int
    var pronunciationScores: [String: Double] // Content ID to score
    var customSettings: UserSettings
}

struct QuizResult: Codable {
    let quizId: String
    let score: Int
    let totalQuestions: Int
    let timeSpent: Int // seconds
    let completedAt: Date
    let passed: Bool
}

struct Achievement: Identifiable, Codable {
    let id: String
    let title: [String: String]
    let description: [String: String]
    let icon: String
    let unlockedAt: Date
    let category: AchievementCategory
}

enum AchievementCategory: String, Codable, CaseIterable {
    case streak = "streak"
    case completion = "completion"
    case quiz = "quiz"
    case emergency = "emergency"
    case milestone = "milestone"
    
    var displayName: String {
        switch self {
        case .streak: return "Streak"
        case .completion: return "Completion"
        case .quiz: return "Quiz"
        case .emergency: return "Emergency"
        case .milestone: return "Milestone"
        }
    }
}

// MARK: - Onboarding (Unchanged)
struct OnboardingPage: Identifiable, Codable {
    let id: Int
    let imageName: String
    let title: String
    let description: String
    let accessibilityImageLabel: String
    let accessibilityHint: String?
    let isLastPage: Bool
    
    static let pages: [OnboardingPage] = [
        OnboardingPage(
            id: 0,
            imageName: "onboarding_truck",
            title: "Welcome to TruckTalk",
            description: "Learn essential English for your trucking career.",
            accessibilityImageLabel: "Illustration of a truck",
            accessibilityHint: "Swipe right to continue to the next screen",
            isLastPage: false
        ),
        OnboardingPage(
            id: 1,
            imageName: "onboarding_audio",
            title: "Learn English On The Road",
            description: "Simple phrases, emergency vocabulary, and trucking terms.",
            accessibilityImageLabel: "Audio learning illustration",
            accessibilityHint: "Swipe to continue",
            isLastPage: false
        ),
        OnboardingPage(
            id: 2,
            imageName: "onboarding_audio",
            title: "Practice With Audio",
            description: "Tap to hear real-world pronunciation. Works offline.",
            accessibilityImageLabel: "Audio practice illustration",
            accessibilityHint: "Includes haptic feedback for audio interactions",
            isLastPage: false
        ),
        OnboardingPage(
            id: 3,
            imageName: "onboarding_progress",
            title: "Track Your Progress",
            description: "Streaks, lesson progress, and bootcamp milestones.",
            accessibilityImageLabel: "Progress tracking illustration",
            accessibilityHint: "Complete setup to start learning English",
            isLastPage: true
        )
    ]
}

// MARK: - Subscription & Premium Features

enum SubscriptionTier: String, Codable, CaseIterable {
    case free = "free"
    case basic = "basic"
    case premium = "premium"
    case enterprise = "enterprise"
    
    var displayName: String {
        switch self {
        case .free: return "Free"
        case .basic: return "Basic"
        case .premium: return "Premium"
        case .enterprise: return "Enterprise"
        }
    }
    
    var monthlyPrice: String {
        switch self {
        case .free: return "Free"
        case .basic: return "$4.99/month"
        case .premium: return "$9.99/month"
        case .enterprise: return "$19.99/month"
        }
    }
    
    var features: [String] {
        switch self {
        case .free:
            return [
                "Access to first 2 modules",
                "Basic vocabulary practice",
                "Limited emergency phrases"
            ]
        case .basic:
            return [
                "Full access to all 6 modules",
                "Complete vocabulary lists",
                "Progress tracking",
                "All emergency phrases",
                "Basic audio pronunciation"
            ]
        case .premium:
            return [
                "All Basic features",
                "AI speaking coach",
                "Downloadable content",
                "Offline mode",
                "Advanced pronunciation feedback",
                "Spaced repetition system"
            ]
        case .enterprise:
            return [
                "All Premium features",
                "Bulk licensing",
                "Custom content options",
                "Fleet management dashboard",
                "Advanced analytics",
                "Priority support"
            ]
        }
    }
    
    var maxModules: Int {
        switch self {
        case .free: return 2
        case .basic, .premium, .enterprise: return 6
        }
    }
    
    var hasOfflineMode: Bool {
        return self == .premium || self == .enterprise
    }
    
    var hasAISpeakingCoach: Bool {
        return self == .premium || self == .enterprise
    }
    
    var hasAdvancedAnalytics: Bool {
        return self == .enterprise
    }
}

struct PremiumFeature: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let requiredTier: SubscriptionTier
    let icon: String
    let isEnabled: Bool
}

struct UserSettings: Codable {
    var playbackSpeed: Double // 0.5x to 2.0x
    var fontSize: FontSize
    var isHighContrastMode: Bool
    var isVoiceRecognitionEnabled: Bool
    var preferredAudioQuality: AudioQuality
    var reminderFrequency: ReminderFrequency
    var isHapticFeedbackEnabled: Bool
}

enum FontSize: String, Codable, CaseIterable {
    case small = "small"
    case medium = "medium"
    case large = "large"
    case extraLarge = "extraLarge"
    
    var displayName: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        case .extraLarge: return "Extra Large"
        }
    }
    
    var scaleFactor: Double {
        switch self {
        case .small: return 0.9
        case .medium: return 1.0
        case .large: return 1.2
        case .extraLarge: return 1.4
        }
    }
}

enum AudioQuality: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    var displayName: String {
        switch self {
        case .low: return "Low (Faster Download)"
        case .medium: return "Medium"
        case .high: return "High (Best Quality)"
        }
    }
}

enum ReminderFrequency: String, Codable, CaseIterable {
    case none = "none"
    case daily = "daily"
    case weekly = "weekly"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .none: return "No Reminders"
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .custom: return "Custom"
        }
    }
} 