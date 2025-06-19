import Foundation
import SwiftUI

// MARK: - Supabase Data Models

struct Lesson: Codable, Identifiable {
    let id: Int
    let title: String
    let day: Int
    let audio_url: String?
    
    var description: String? {
        // In a real implementation, this would come from the API
        return "Learn essential English for truck drivers"
    }
}

struct SupabaseEmergencyPhrase: Codable, Identifiable {
    let id: Int
    let category: String
    let english: String
    let translation: String
    let audioUrl: String?
    let priority: Int?
    
    enum CodingKeys: String, CodingKey {
        case id, category, english, translation
        case audioUrl = "audio_url"
        case priority
    }
}

/// Service for fetching lesson data from Supabase backend
/// Provides both online API calls and offline fallback functionality
@MainActor
class LessonService: ObservableObject {
    
    // MARK: - Published State
    @Published var isLoading = false
    @Published var lessons: [Lesson] = []
    @Published var emergencyPhrases: [SupabaseEmergencyPhrase] = []
    @Published var lastError: SupabaseAPI.SupabaseError?
    
    // MARK: - Dependencies
    private let supabaseAPI: SupabaseAPI
    private var fallbackDataService: DataService!
    
    // MARK: - Initialization
    init(supabaseAPI: SupabaseAPI? = nil) {
        self.supabaseAPI = supabaseAPI ?? SupabaseAPI.shared
        Task {
            await initializeFallbackData()
        }
    }
    
    // MARK: - Public API
    
    /// Refresh all data from Supabase
    func refreshAllData() async {
        isLoading = true
        defer { isLoading = false }
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchAllLessons() }
            group.addTask { await self.fetchEmergencyPhrases() }
        }
    }
    
    /// Fetch all lessons
    func fetchAllLessons() async {
        do {
            let url = URL(string: "\(getBaseURL())/rest/v1/lessons?order=day.asc,id.asc")!
            let request = createAuthenticatedRequest(url: url)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw SupabaseAPI.SupabaseError.networkError("Invalid response")
            }
            
            let fetchedLessons = try JSONDecoder().decode([Lesson].self, from: data)
            lessons = fetchedLessons
            
            print("✅ Fetched \(fetchedLessons.count) lessons from Supabase")
            
        } catch {
            print("❌ Failed to fetch lessons from Supabase: \(error)")
            lastError = .networkError(error.localizedDescription)
            
            // Fallback to local data if network fails
            if lessons.isEmpty {
                print("📚 Falling back to local lesson data")
                await loadMockData()
            }
        }
    }
    
    /// Fetch lessons for a specific day
    func fetchLessons(for day: Int) async {
        do {
            let url = URL(string: "\(getBaseURL())/rest/v1/lessons?day=eq.\(day)&order=id.asc")!
            let request = createAuthenticatedRequest(url: url)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw SupabaseAPI.SupabaseError.networkError("Invalid response")
            }
            
            let fetchedLessons = try JSONDecoder().decode([Lesson].self, from: data)
            
            // Update lessons for this day
            lessons.removeAll { $0.day == day }
            lessons.append(contentsOf: fetchedLessons)
            
            print("✅ Fetched \(fetchedLessons.count) lessons for day \(day)")
            
        } catch {
            print("❌ Failed to fetch lessons for day \(day): \(error)")
            lastError = .networkError(error.localizedDescription)
        }
    }
    
    /// Fetch emergency phrases for a specific category
    func fetchEmergencyPhrases(for category: String) async {
        do {
            guard let url = URL(string: "\(getBaseURL())/rest/v1/emergency_phrases?category=eq.\(category)&order=priority.asc") else {
                throw SupabaseAPI.SupabaseError.networkError("Invalid URL")
            }
            
            let request = createAuthenticatedRequest(url: url)
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw SupabaseAPI.SupabaseError.networkError("Invalid response")
            }
            
            let fetchedPhrases = try JSONDecoder().decode([SupabaseEmergencyPhrase].self, from: data)
            
            // Update phrases for this category
            emergencyPhrases.removeAll { $0.category == category }
            emergencyPhrases.append(contentsOf: fetchedPhrases)
            
            print("✅ Fetched \(fetchedPhrases.count) emergency phrases for category \(category)")
            
        } catch {
            print("❌ Failed to fetch emergency phrases for category \(category): \(error)")
            lastError = .networkError(error.localizedDescription)
        }
    }
    
    /// Fetch all emergency phrases
    func fetchEmergencyPhrases() async {
        do {
            guard let url = URL(string: "\(getBaseURL())/rest/v1/emergency_phrases?order=category.asc,priority.asc") else {
                throw SupabaseAPI.SupabaseError.networkError("Invalid URL")
            }
            
            let request = createAuthenticatedRequest(url: url)
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw SupabaseAPI.SupabaseError.networkError("Invalid response")
            }
            
            let fetchedPhrases = try JSONDecoder().decode([SupabaseEmergencyPhrase].self, from: data)
            emergencyPhrases = fetchedPhrases
            
            print("✅ Fetched \(fetchedPhrases.count) emergency phrases")
            
        } catch {
            print("❌ Failed to fetch emergency phrases: \(error)")
            lastError = .networkError(error.localizedDescription)
        }
    }
    
    // MARK: - Computed Properties
    
    var hasCachedLessons: Bool {
        !lessons.isEmpty
    }
    
    var hasCachedEmergencyPhrases: Bool {
        !emergencyPhrases.isEmpty
    }
    
    // MARK: - Private Methods
    
    private func initializeFallbackData() async {
        fallbackDataService = DataService()
        await fallbackDataService.loadAllContent()
    }
    
    private func getBaseURL() -> String {
        return "https://pvstwthufbertinmojuk.supabase.co"
    }
    
    private func createAuthenticatedRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB2c3R3dGh1ZmJlcnRpbm1vanVrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDcwOTI2NDQsImV4cCI6MjA2MjY2ODY0NH0.PG7BJeWuYe-piU_JatbBfauK-I3d9sVh-2fJypAZHS8", forHTTPHeaderField: "apikey")
        
        // Add authorization header if user is logged in
        if let accessToken = UserDefaults.standard.string(forKey: "supabase_access_token") {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        
        return request
    }
    
    // MARK: - Mock Data for Testing
    
    func loadMockData() async {
        // Mock lessons
        lessons = [
            Lesson(id: 1, title: "Basic Greetings", day: 1, audio_url: "greetings.mp3"),
            Lesson(id: 2, title: "Vehicle Parts", day: 1, audio_url: "vehicle_parts.mp3"),
            Lesson(id: 3, title: "Police Stop", day: 2, audio_url: "police_stop.mp3")
        ]
        
        // Mock emergency phrases
        emergencyPhrases = [
            SupabaseEmergencyPhrase(
                id: 1,
                category: "police_stop",
                english: "Good morning, officer. Here is my license.",
                translation: "Buenos días, oficial. Aquí está mi licencia.",
                audioUrl: "police_greeting.mp3",
                priority: 1
            ),
            SupabaseEmergencyPhrase(
                id: 2,
                category: "vehicle_trouble",
                english: "My truck has broken down.",
                translation: "Mi camión se ha averiado.",
                audioUrl: "vehicle_breakdown.mp3",
                priority: 1
            )
        ]
        
        print("📚 Loaded mock data: \(lessons.count) lessons, \(emergencyPhrases.count) emergency phrases")
    }
}

// MARK: - Data Conversion Extensions

extension Lesson {
    /// Convert Supabase Lesson to local BootcampDay model
    func toBootcampDay(isUnlocked: Bool = true, completionPercentage: Double = 0.0) -> BootcampDay {
        return BootcampDay(
            id: id,
            title: ["en": title],
            description: ["en": description ?? "Learn essential English for truck drivers"],
            isUnlocked: isUnlocked,
            completionPercentage: completionPercentage,
            estimatedMinutes: 240, // Default estimation
            sections: [], // Sections would need to be fetched separately
            objectives: ["en": ["Complete lesson objectives", "Practice vocabulary", "Master key phrases"]]
        )
    }
}

extension SupabaseEmergencyPhrase {
    /// Convert Supabase EmergencyPhrase to local EmergencyPhrase model
    func toEmergencyPhrase() -> EmergencyPhrase? {
        guard let category = EmergencyCategory(rawValue: category) else { return nil }
        
        return EmergencyPhrase(
            id: String(id),
            category: category,
            englishText: english,
            translations: ["en": translation], // Would need multiple languages from API
            audioFileName: audioUrl ?? "",
            audioUrls: nil,
            priority: priority ?? 999,
            urgencyLevel: .medium, // Would be determined by API
            contextNotes: nil,
            relatedPhrases: nil
        )
    }
}

// MARK: - Preview Helper
extension LessonService {
    /// Create a mock instance for SwiftUI previews
    static var preview: LessonService {
        let service = LessonService()
        
        // Add mock lessons
        service.lessons = [
            Lesson(id: 1, title: "Day 1: Basic Greetings", day: 1, audio_url: nil),
            Lesson(id: 2, title: "Day 2: Road Communication", day: 2, audio_url: nil)
        ]
        
        // Add mock emergency phrases
        service.emergencyPhrases = [
            SupabaseEmergencyPhrase(id: 1, category: "police_stop", english: "Here is my license", translation: "Aquí está mi licencia", audioUrl: nil, priority: 1)
        ]
        
        return service
    }
} 