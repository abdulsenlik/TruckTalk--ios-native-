import SwiftUI

struct EmergencyPhrasesView: View {
    @EnvironmentObject var dataService: DataService
    @StateObject private var audioManager = AudioManager()
    @State private var selectedCategory: EmergencyCategory? = nil
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Category Grid
                    categoryGrid
                    
                    // Phrases List
                    phrasesSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Emergency Phrases")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Access Phrases")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Essential phrases for emergency situations and common road scenarios. Tap any phrase to hear the pronunciation.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private var categoryGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Categories")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(EmergencyCategory.allCases, id: \.self) { category in
                    categoryCard(category)
                }
            }
        }
    }
    
    private func categoryCard(_ category: EmergencyCategory) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedCategory = selectedCategory == category ? nil : category
            }
        }) {
            VStack(spacing: 12) {
                // Icon
                Image(systemName: category.icon)
                    .font(.title)
                    .foregroundColor(categoryColor(category))
                    .frame(height: 32)
                
                // Title
                Text(category.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Count
                Text("\(phrasesForCategory(category).count) phrases")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .frame(minHeight: 120)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        selectedCategory == category ? 
                        categoryColor(category).opacity(0.1) : 
                        Color(.systemBackground)
                    )
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        selectedCategory == category ? 
                        categoryColor(category) : 
                        Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var phrasesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let selectedCategory = selectedCategory {
                HStack {
                    Text("\(selectedCategory.displayName) Phrases")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button("Show All") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            self.selectedCategory = nil
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
                }
                
                LazyVStack(spacing: 12) {
                    ForEach(phrasesForCategory(selectedCategory)) { phrase in
                        emergencyPhraseCard(phrase)
                    }
                }
            } else {
                Text("All Emergency Phrases")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                LazyVStack(spacing: 16) {
                    ForEach(EmergencyCategory.allCases, id: \.self) { category in
                        categoryPhrasesSection(category)
                    }
                }
            }
        }
    }
    
    private func categoryPhrasesSection(_ category: EmergencyCategory) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: category.icon)
                    .font(.title3)
                    .foregroundColor(categoryColor(category))
                
                Text(category.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("View All") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedCategory = category
                    }
                }
                .font(.caption)
                .foregroundColor(.accentColor)
            }
            
            LazyVStack(spacing: 8) {
                ForEach(phrasesForCategory(category).prefix(2)) { phrase in
                    emergencyPhraseCard(phrase)
                }
            }
        }
    }
    
    private func emergencyPhraseCard(_ phrase: EmergencyPhrase) -> some View {
        AudioCard(
            englishText: phrase.englishText,
            translation: phrase.localizedTranslation(),
            audioFileName: phrase.audioFileName,
            isPlaying: audioManager.currentAudioId == phrase.id && audioManager.isPlaying,
            isFavorited: dataService.userProgress.favoritePhrases.contains(phrase.id),
            isCompleted: false
        ) {
            // Play audio
            if audioManager.currentAudioId == phrase.id && audioManager.isPlaying {
                audioManager.stopAudio()
            } else {
                audioManager.playAudio(fileName: phrase.audioFileName, audioId: phrase.id)
            }
        } onFavoriteTap: {
            // Toggle favorite
            dataService.toggleFavorite(phrase.id)
        } onCompleteTap: {
            // Not used for emergency phrases
        }
    }
    
    private func phrasesForCategory(_ category: EmergencyCategory) -> [EmergencyPhrase] {
        dataService.emergencyPhrases
            .filter { $0.category == category }
            .sorted { $0.priority < $1.priority }
    }
    
    private func categoryColor(_ category: EmergencyCategory) -> Color {
        switch category.color {
        case "blue": return .blue
        case "orange": return .orange
        case "red": return .red
        case "green": return .green
        case "purple": return .purple
        default: return .accentColor
        }
    }
}

#Preview {
    EmergencyPhrasesView()
        .environmentObject(DataService())
} 