import Foundation
import Combine

@MainActor
class DataService: ObservableObject {
    @Published var bootcampDays: [BootcampDay] = []
    @Published var emergencyPhrases: [EmergencyPhrase] = []
    @Published var quizzes: [Quiz] = []
    @Published var userProgress = UserProgress(
        completedLessons: Set<String>(),
        favoritePhrases: Set<String>(),
        currentDay: 1,
        streak: 0,
        totalMinutesStudied: 0.0,
        selectedLanguage: .english,
        quizScores: [:],
        achievements: [],
        lastStudyDate: nil,
        weeklyGoalMinutes: 300, // 5 hours per week
        weeklyProgressMinutes: 0,
        subscriptionTier: .free,
        subscriptionExpiryDate: nil,
        downloadedContent: Set<String>(),
        aiCoachSessions: 0,
        pronunciationScores: [:],
        customSettings: UserSettings(
            playbackSpeed: 1.0,
            fontSize: .medium,
            isHighContrastMode: false,
            isVoiceRecognitionEnabled: true,
            preferredAudioQuality: .medium,
            reminderFrequency: .daily,
            isHapticFeedbackEnabled: true
        )
    )
    
    // MARK: - Supabase Integration
    private let lessonService = LessonService()
    @Published var isOnlineMode = false
    @Published var lastSyncDate: Date?
    
    // MARK: - Language Management
    private var languageManager = LanguageManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Loading State
    private var isLoading = false
    private var hasInitialLoadCompleted = false
    
    init() {
        // Observe language changes - but only after initial load is complete
        languageManager.$selectedLanguage
            .sink { [weak self] newLanguage in
                Task { @MainActor in
                    guard let self = self, self.hasInitialLoadCompleted else { return }
                    guard !self.isLoading else { return } // Prevent multiple simultaneous loads
                    
                    self.userProgress.selectedLanguage = newLanguage
                    await self.loadLocalizedContent()
                }
            }
            .store(in: &cancellables)
        
        Task {
            await loadLocalizedContent()
            hasInitialLoadCompleted = true
            // Only try online data once during initialization
            await initializeOnlineData()
        }
    }
    
    // MARK: - Content Loading
    
    /// Load all content (bootcamp, emergency phrases, quizzes)
    func loadAllContent() async {
        await loadLocalizedContent()
    }
    
    /// Load localized content from JSON files
    private func loadLocalizedContent() async {
        guard !isLoading else { return } // Prevent concurrent loads
        isLoading = true
        defer { isLoading = false }
        
        async let bootcampTask: Void = loadBootcampData()
        async let emergencyTask: Void = loadEmergencyPhrases()
        async let quizzesTask: Void = loadQuizzes()
        
        // Wait for all content to load
        await bootcampTask
        await emergencyTask
        await quizzesTask
        
        print("📚 Localized content loaded for language: \(languageManager.selectedLanguage.displayName)")
    }
    
    /// Load bootcamp data from JSON
    private func loadBootcampData() async {
        if let bootcamp = languageManager.loadLocalizedData(TruckTalkBootcamp.self, from: "bootcamp") {
            bootcampDays = bootcamp.days
            print("✅ Loaded \(bootcampDays.count) bootcamp days")
        } else {
            // Fallback to mock data if JSON loading fails
            await loadMockBootcampData()
        }
    }
    
    /// Load emergency phrases from JSON
    private func loadEmergencyPhrases() async {
        if let loadedPhrases = languageManager.loadLocalizedData([EmergencyPhrase].self, from: "emergency_phrases") {
            emergencyPhrases = loadedPhrases
            print("✅ Loaded \(emergencyPhrases.count) emergency phrases")
        } else {
            // Fallback to mock data if JSON loading fails
            await loadMockEmergencyPhrases()
        }
    }
    
    /// Load quizzes from JSON
    private func loadQuizzes() async {
        if let loadedQuizzes = languageManager.loadLocalizedData([Quiz].self, from: "quizzes") {
            quizzes = loadedQuizzes
            print("✅ Loaded \(quizzes.count) quizzes")
        } else {
            // Create some basic quizzes if JSON loading fails
            await loadMockQuizzes()
        }
    }
    
    // MARK: - Online Data Integration
    
    /// Initialize online data and fall back to offline if needed
    private func initializeOnlineData() async {
        // Only try to fetch online data if we don't have local data
        if bootcampDays.isEmpty || emergencyPhrases.isEmpty {
            print("🌐 Attempting to fetch online data...")
            await lessonService.refreshAllData()
            
            // Check if we have online data
            if lessonService.hasCachedLessons || lessonService.hasCachedEmergencyPhrases {
                isOnlineMode = true
                lastSyncDate = Date()
                await syncOnlineDataToLocal()
                print("✅ Successfully loaded online data")
            } else {
                print("📱 Using offline data only")
            }
        } else {
            print("📱 Using cached local data")
        }
    }
    
    /// Sync online data to local models
    private func syncOnlineDataToLocal() async {
        // Convert Supabase lessons to BootcampDay format
        if lessonService.hasCachedLessons {
            let groupedLessons = Dictionary(grouping: lessonService.lessons) { $0.day }
            
            let onlineBootcampDays = groupedLessons.compactMap { (day, lessons) -> BootcampDay? in
                guard let firstLesson = lessons.first else { return nil }
                
                return BootcampDay(
                    id: day,
                    title: ["en": firstLesson.title],
                    description: ["en": firstLesson.description ?? "Learn essential English for truck drivers"],
                    isUnlocked: day <= userProgress.currentDay,
                    completionPercentage: calculateCompletionPercentage(for: day),
                    estimatedMinutes: 240, // Default 4 hours per day
                    sections: [], // Would ideally be fetched from API
                    objectives: ["en": ["Master essential trucking vocabulary", "Practice professional communication"]]
                )
            }.sorted { $0.id < $1.id }
            
            // Merge with existing bootcamp data
            if !onlineBootcampDays.isEmpty {
                bootcampDays = onlineBootcampDays
            }
        }
        
        // Convert Supabase emergency phrases to local format
        if lessonService.hasCachedEmergencyPhrases {
            let onlineEmergencyPhrases = lessonService.emergencyPhrases.compactMap { phrase in
                phrase.toEmergencyPhrase()
            }
            
            if !onlineEmergencyPhrases.isEmpty {
                emergencyPhrases = onlineEmergencyPhrases
            }
        }
        
        print("🔄 Synced online data: \(bootcampDays.count) bootcamp days, \(emergencyPhrases.count) emergency phrases")
    }
    
    /// Manually refresh data from Supabase
    func refreshFromSupabase() async {
        await lessonService.refreshAllData()
        await syncOnlineDataToLocal()
        lastSyncDate = Date()
    }
    
    // MARK: - Fallback Mock Data
    
    private func loadMockBootcampData() async {
        bootcampDays = [
            BootcampDay(
                id: 1,
                title: [
                    "en": "Day 1: Basic Greetings & Introductions",
                    "es": "Día 1: Saludos Básicos e Presentaciones",
                    "tr": "Gün 1: Temel Selamlaşmalar ve Tanışmalar"
                ],
                description: [
                    "en": "Learn essential greetings and how to introduce yourself professionally",
                    "es": "Aprende saludos esenciales y cómo presentarte profesionalmente",
                    "tr": "Temel selamlaşmaları ve kendini profesyonel olarak tanıtmayı öğren"
                ],
                isUnlocked: true,
                completionPercentage: 0.0,
                estimatedMinutes: 240,
                sections: createMockSections(for: 1),
                objectives: [
                    "en": ["Learn basic greetings", "Practice introductions", "Master professional communication"],
                    "es": ["Aprender saludos básicos", "Practicar presentaciones", "Dominar la comunicación profesional"],
                    "tr": ["Temel selamlaşmaları öğren", "Tanışmaları pratik et", "Profesyonel iletişimde ustalaş"]
                ]
            ),
            BootcampDay(
                id: 2,
                title: [
                    "en": "Day 2: Vehicle & Documentation",
                    "es": "Día 2: Vehículo y Documentación",
                    "tr": "Gün 2: Araç ve Dokümantasyon"
                ],
                description: [
                    "en": "Essential vocabulary for truck parts, maintenance, and paperwork",
                    "es": "Vocabulario esencial para partes del camión, mantenimiento y papeleo",
                    "tr": "Kamyon parçaları, bakım ve evrak işleri için temel kelime dağarcığı"
                ],
                isUnlocked: true,
                completionPercentage: 0.0,
                estimatedMinutes: 240,
                sections: createMockSections(for: 2),
                objectives: [
                    "en": ["Learn truck parts vocabulary", "Understand maintenance terms", "Practice documentation language"],
                    "es": ["Aprender vocabulario de partes del camión", "Entender términos de mantenimiento", "Practicar lenguaje de documentación"],
                    "tr": ["Kamyon parçaları kelime dağarcığını öğren", "Bakım terimlerini anla", "Dokümantasyon dilini pratik et"]
                ]
            )
        ]
        
        print("📚 Loaded mock bootcamp data")
    }
    
    private func loadMockEmergencyPhrases() async {
        emergencyPhrases = [
            EmergencyPhrase(
                id: "police_1",
                category: .policeStop,
                englishText: "Good morning, officer. Here is my license and registration.",
                translations: [
                    "en": "Good morning, officer. Here is my license and registration.",
                    "es": "Buenos días, oficial. Aquí está mi licencia y registro.",
                    "tr": "Günaydın memur bey. İşte ehliyetim ve ruhsatım.",
                    "ar": "صباح الخير أيها الضابط. هذه رخصتي وتسجيلي."
                ],
                audioFileName: "police_license.mp3",
                audioUrls: [
                    "en": "audio/en/police_license.mp3",
                    "es": "audio/es/policia_licencia.mp3"
                ],
                priority: 1,
                urgencyLevel: .high,
                contextNotes: [
                    "en": "Always remain calm and cooperative during police stops",
                    "es": "Siempre mantén la calma y coopera durante las paradas policiales"
                ],
                relatedPhrases: ["police_2", "police_3"]
            ),
            EmergencyPhrase(
                id: "vehicle_1",
                category: .vehicleTrouble,
                englishText: "My truck has broken down. I need roadside assistance.",
                translations: [
                    "en": "My truck has broken down. I need roadside assistance.",
                    "es": "Mi camión se averió. Necesito asistencia en carretera.",
                    "tr": "Kamyonum arızalandı. Yol kenarı yardımına ihtiyacım var.",
                    "ar": "شاحنتي تعطلت. أحتاج إلى مساعدة على الطريق."
                ],
                audioFileName: "vehicle_breakdown.mp3",
                audioUrls: nil,
                priority: 1,
                urgencyLevel: .critical,
                contextNotes: [
                    "en": "Call for help immediately if your vehicle breaks down"
                ],
                relatedPhrases: nil
            ),
            EmergencyPhrase(
                id: "medical_1",
                category: .medicalEmergency,
                englishText: "I need medical help. Please call 911.",
                translations: [
                    "en": "I need medical help. Please call 911.",
                    "es": "Necesito ayuda médica. Por favor llame al 911.",
                    "tr": "Tıbbi yardıma ihtiyacım var. Lütfen 911'i arayın.",
                    "ar": "أحتاج إلى مساعدة طبية. يرجى الاتصال بالـ 911."
                ],
                audioFileName: "medical_help.mp3",
                audioUrls: nil,
                priority: 1,
                urgencyLevel: .critical,
                contextNotes: [
                    "en": "Use this phrase in any serious medical emergency"
                ],
                relatedPhrases: nil
            )
        ]
        
        print("🚨 Loaded mock emergency phrases")
    }
    
    private func loadMockQuizzes() async {
        quizzes = [
            Quiz(
                id: "day_1_quiz",
                title: [
                    "en": "Day 1: Greetings & Introductions Quiz",
                    "es": "Día 1: Cuestionario de Saludos e Presentaciones",
                    "tr": "Gün 1: Selamlaşmalar ve Tanışmalar Sınavı"
                ],
                description: [
                    "en": "Test your knowledge of basic greetings and professional introductions",
                    "es": "Pon a prueba tu conocimiento de saludos básicos y presentaciones profesionales",
                    "tr": "Temel selamlaşmalar ve profesyonel tanışmalar bilginizi test edin"
                ],
                questions: [], // Would be populated with actual questions
                passingScore: 70,
                timeLimit: 300,
                difficulty: .beginner,
                category: .vocabulary
            )
        ]
        
        print("📝 Loaded mock quizzes")
    }
    
    // MARK: - Helper Methods
    
    /// Calculate completion percentage for a day
    private func calculateCompletionPercentage(for dayId: Int) -> Double {
        let dayContent = bootcampDays.first(where: { $0.id == dayId })?.sections.flatMap(\.content) ?? []
        let totalItems = dayContent.count
        let completedItems = dayContent.filter { userProgress.completedLessons.contains($0.id) }.count
        
        return totalItems > 0 ? Double(completedItems) / Double(totalItems) : 0.0
    }
    
    private func createMockSections(for dayId: Int) -> [LessonSection] {
        return [
            LessonSection(
                id: "vocab_\(dayId)",
                type: .vocabulary,
                title: [
                    "en": "Vocabulary",
                    "es": "Vocabulario",
                    "tr": "Kelime Dağarcığı"
                ],
                description: [
                    "en": "Essential vocabulary for this lesson",
                    "es": "Vocabulario esencial para esta lección"
                ],
                content: createMockVocabulary(for: dayId),
                estimatedMinutes: 60
            ),
            LessonSection(
                id: "dialogue_\(dayId)",
                type: .dialogue,
                title: [
                    "en": "Dialogue Practice",
                    "es": "Práctica de Diálogo",
                    "tr": "Diyalog Pratiği"
                ],
                description: [
                    "en": "Practice real conversations",
                    "es": "Practica conversaciones reales"
                ],
                content: createMockDialogue(for: dayId),
                estimatedMinutes: 90
            )
        ]
    }
    
    private func createMockVocabulary(for dayId: Int) -> [LessonContent] {
        switch dayId {
        case 1:
            return [
                LessonContent(
                    id: "vocab_1_1",
                    englishText: "Good morning",
                    translations: [
                        "en": "Good morning",
                        "es": "Buenos días",
                        "tr": "Günaydın",
                        "ar": "صباح الخير"
                    ],
                    audioFileName: "good_morning.mp3",
                    audioUrls: [
                        "en": "audio/en/good_morning.mp3",
                        "es": "audio/es/buenos_dias.mp3"
                    ],
                    isCompleted: false,
                    isFavorited: false,
                    contentType: .phrase,
                    difficulty: .beginner,
                    tags: ["greeting", "morning", "professional"]
                ),
                LessonContent(
                    id: "vocab_1_2",
                    englishText: "Nice to meet you",
                    translations: [
                        "en": "Nice to meet you",
                        "es": "Mucho gusto",
                        "tr": "Tanıştığımıza memnun oldum",
                        "ar": "سعدت بلقائك"
                    ],
                    audioFileName: "nice_to_meet.mp3",
                    audioUrls: nil,
                    isCompleted: false,
                    isFavorited: false,
                    contentType: .phrase,
                    difficulty: .beginner,
                    tags: ["meeting", "politeness", "professional"]
                )
            ]
        case 2:
            return [
                LessonContent(
                    id: "vocab_2_1",
                    englishText: "Engine",
                    translations: [
                        "en": "Engine",
                        "es": "Motor",
                        "tr": "Motor",
                        "ar": "محرك"
                    ],
                    audioFileName: "engine.mp3",
                    audioUrls: nil,
                    isCompleted: false,
                    isFavorited: false,
                    contentType: .vocabulary,
                    difficulty: .beginner,
                    tags: ["truck", "parts", "mechanical"]
                ),
                LessonContent(
                    id: "vocab_2_2",
                    englishText: "Brakes",
                    translations: [
                        "en": "Brakes",
                        "es": "Frenos",
                        "tr": "Frenler",
                        "ar": "مكابح"
                    ],
                    audioFileName: "brakes.mp3",
                    audioUrls: nil,
                    isCompleted: false,
                    isFavorited: false,
                    contentType: .vocabulary,
                    difficulty: .beginner,
                    tags: ["truck", "safety", "parts"]
                )
            ]
        default:
            return []
        }
    }
    
    private func createMockDialogue(for dayId: Int) -> [LessonContent] {
        return [
            LessonContent(
                id: "dialogue_\(dayId)_1",
                englishText: "Driver: Good morning! I'm here for the delivery.",
                translations: [
                    "en": "Driver: Good morning! I'm here for the delivery.",
                    "es": "Conductor: ¡Buenos días! Estoy aquí para la entrega.",
                    "tr": "Şoför: Günaydın! Teslimat için buradayım."
                ],
                audioFileName: "dialogue_\(dayId)_1.mp3",
                audioUrls: nil,
                isCompleted: false,
                isFavorited: false,
                contentType: .dialogue,
                difficulty: .beginner,
                tags: ["delivery", "professional", "greeting"]
            )
        ]
    }
    
    // MARK: - Progress Management
    func markLessonCompleted(_ lessonId: String) {
        userProgress.completedLessons.insert(lessonId)
        updateCompletionPercentages()
        updateStreak()
    }
    
    func toggleFavorite(_ itemId: String) {
        if userProgress.favoritePhrases.contains(itemId) {
            userProgress.favoritePhrases.remove(itemId)
        } else {
            userProgress.favoritePhrases.insert(itemId)
        }
    }
    
    func recordQuizResult(_ result: QuizResult) {
        userProgress.quizScores[result.quizId] = result
        
        // Add achievements for good quiz performance
        if result.passed && result.score >= 90 {
            let achievement = Achievement(
                id: "quiz_excellent_\(result.quizId)",
                title: [
                    "en": "Quiz Master",
                    "es": "Maestro de Cuestionarios",
                    "tr": "Sınav Ustası"
                ],
                description: [
                    "en": "Scored 90% or higher on a quiz",
                    "es": "Obtuvo 90% o más en un cuestionario",
                    "tr": "Bir sınavda %90 veya daha yüksek puan aldı"
                ],
                icon: "star.fill",
                unlockedAt: Date(),
                category: .quiz
            )
            userProgress.achievements.append(achievement)
        }
    }
    
    private func updateCompletionPercentages() {
        var updatedDays = bootcampDays
        for index in updatedDays.indices {
            let totalLessons = updatedDays[index].sections.flatMap { $0.content }.count
            let completedLessons = updatedDays[index].sections.flatMap { $0.content }
                .filter { userProgress.completedLessons.contains($0.id) }.count
            
            let newCompletionPercentage = totalLessons > 0 ? Double(completedLessons) / Double(totalLessons) : 0
            
            updatedDays[index] = BootcampDay(
                id: updatedDays[index].id,
                title: updatedDays[index].title,
                description: updatedDays[index].description,
                isUnlocked: updatedDays[index].isUnlocked,
                completionPercentage: newCompletionPercentage,
                estimatedMinutes: updatedDays[index].estimatedMinutes,
                sections: updatedDays[index].sections,
                objectives: updatedDays[index].objectives
            )
        }
        bootcampDays = updatedDays
    }
    
    private func updateStreak() {
        let today = Calendar.current.startOfDay(for: Date())
        let lastStudy = userProgress.lastStudyDate.map { Calendar.current.startOfDay(for: $0) }
        
        if let lastStudy = lastStudy {
            let daysBetween = Calendar.current.dateComponents([.day], from: lastStudy, to: today).day ?? 0
            
            if daysBetween == 1 {
                // Consecutive day - increase streak
                userProgress.streak += 1
            } else if daysBetween > 1 {
                // Missed days - reset streak
                userProgress.streak = 1
            }
            // If daysBetween == 0, it's the same day, don't change streak
        } else {
            // First time studying
            userProgress.streak = 1
        }
        
        userProgress.lastStudyDate = Date()
    }
    
    // MARK: - Content Filtering
    
    /// Get emergency phrases by category
    func emergencyPhrases(for category: EmergencyCategory) -> [EmergencyPhrase] {
        return emergencyPhrases.filter { $0.category == category }
    }
    
    /// Get quizzes for a specific day
    func quizzes(for day: Int) -> [Quiz] {
        return quizzes.filter { $0.id.contains("day_\(day)") }
    }
    
    /// Get user's favorite phrases
    func favoriteEmergencyPhrases() -> [EmergencyPhrase] {
        return emergencyPhrases.filter { userProgress.favoritePhrases.contains($0.id) }
    }
    
    /// Check if content is completed
    func isCompleted(_ contentId: String) -> Bool {
        return userProgress.completedLessons.contains(contentId)
    }
    
    /// Check if content is favorited
    func isFavorited(_ contentId: String) -> Bool {
        return userProgress.favoritePhrases.contains(contentId)
    }
} 