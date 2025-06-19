import SwiftUI

struct LessonDetailView: View {
    let bootcampDay: BootcampDay
    let dataService: DataService
    
    @StateObject private var audioManager = AudioManager()
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var expandedSections: Set<String> = []
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Lesson Sections
                    ForEach(bootcampDay.sections) { section in
                        lessonSection(section)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(languageManager.localizedTitle(for: bootcampDay))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(languageManager.localizedDescription(for: bootcampDay))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            // Progress Indicator
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Lesson Progress")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ProgressView(value: bootcampDay.completionPercentage)
                        .tint(.accentColor)
                        .frame(height: 8)
                        .background(Color.secondary.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                
                Spacer()
                
                Text("\(Int(bootcampDay.completionPercentage * 100))%")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.accentColor)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
    }
    
    private func lessonSection(_ section: LessonSection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    if expandedSections.contains(section.id) {
                        expandedSections.remove(section.id)
                    } else {
                        expandedSections.insert(section.id)
                    }
                }
            }) {
                HStack {
                    Image(systemName: section.type.icon)
                        .font(.title2)
                        .foregroundColor(.accentColor)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(section.type.displayName)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("\(section.content.count) items")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: expandedSections.contains(section.id) ? "chevron.up" : "chevron.down")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Section Content
            if expandedSections.contains(section.id) {
                LazyVStack(spacing: 12) {
                    ForEach(section.content) { content in
                        AudioCard(
                            englishText: content.englishText,
                            translation: languageManager.localizedTranslation(for: content),
                            audioFileName: content.audioFileName,
                            isPlaying: audioManager.currentAudioId == content.id && audioManager.isPlaying,
                            isLoading: audioManager.isLoading && audioManager.currentAudioId == content.id,
                            isFavorited: dataService.userProgress.favoritePhrases.contains(content.id),
                            isCompleted: dataService.userProgress.completedLessons.contains(content.id)
                        ) {
                            // Play audio
                            if let audioFileName = content.audioFileName {
                                if audioManager.currentAudioId == content.id && audioManager.isPlaying {
                                    audioManager.stopAudio()
                                } else {
                                    audioManager.playAudio(fileName: audioFileName, audioId: content.id)
                                }
                            }
                        } onFavoriteTap: {
                            // Toggle favorite
                            dataService.toggleFavorite(content.id)
                        } onCompleteTap: {
                            // Mark as complete
                            dataService.markLessonCompleted(content.id)
                        }
                    }
                }
                .transition(.opacity.combined(with: .slide))
            }
        }
    }
}

#Preview {
    LessonDetailView(
        bootcampDay: BootcampDay(
            id: 1,
            title: ["en": "Day 1: Basic Greetings"],
            description: ["en": "Learn essential greetings and introductions for professional truck driving communication"],
            isUnlocked: true,
            completionPercentage: 0.6,
            estimatedMinutes: 240,
            sections: [
                LessonSection(
                    id: "vocab_1",
                    type: .vocabulary,
                    title: ["en": "Vocabulary"],
                    description: ["en": "Essential vocabulary for this lesson"],
                    content: [
                        LessonContent(
                            id: "vocab_1_1",
                            englishText: "Good morning",
                            translations: ["en": "Good morning", "es": "Buenos días"],
                            audioFileName: "good_morning",
                            audioUrls: nil,
                            isCompleted: true,
                            isFavorited: false,
                            contentType: .phrase,
                            difficulty: .beginner,
                            tags: ["greeting"]
                        ),
                        LessonContent(
                            id: "vocab_1_2",
                            englishText: "Thank you",
                            translations: ["en": "Thank you", "es": "Gracias"],
                            audioFileName: "thank_you",
                            audioUrls: nil,
                            isCompleted: false,
                            isFavorited: true,
                            contentType: .phrase,
                            difficulty: .beginner,
                            tags: ["politeness"]
                        )
                    ],
                    estimatedMinutes: 60
                )
            ],
            objectives: ["en": ["Learn basic greetings", "Practice introductions"]]
        ),
        dataService: DataService()
    )
    .environmentObject(LanguageManager.shared)
    .environmentObject(DataService())
} 