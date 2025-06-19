import SwiftUI

struct AudioCard: View {
    let englishText: String
    let translation: String?
    let audioFileName: String?
    let isPlaying: Bool
    let isLoading: Bool
    let isFavorited: Bool
    let isCompleted: Bool
    let onPlayTap: () -> Void
    let onFavoriteTap: () -> Void
    let onCompleteTap: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // English Text
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(englishText)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if let translation = translation {
                        Text(translation)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                Spacer()
                
                // Status Icons
                HStack(spacing: 8) {
                    if isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.green)
                    }
                    
                    Button(action: onFavoriteTap) {
                        Image(systemName: isFavorited ? "heart.fill" : "heart")
                            .font(.title3)
                            .foregroundColor(isFavorited ? .red : .secondary)
                    }
                    .accessibilityLabel(isFavorited ? "Remove from favorites" : "Add to favorites")
                }
            }
            
            // Controls
            HStack {
                // Play Button
                Button(action: onPlayTap) {
                    HStack(spacing: 8) {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.headline)
                        }
                        
                        Text(isLoading ? "Loading..." : (isPlaying ? "Playing..." : "Play Audio"))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(buttonBackgroundColor)
                    )
                }
                .disabled(audioFileName == nil || isLoading)
                .accessibilityLabel(isPlaying ? "Pause audio" : "Play audio")
                
                Spacer()
                
                // Mark Complete Button
                if !isCompleted {
                    Button(action: onCompleteTap) {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark")
                                .font(.caption)
                            Text("Done")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.secondary.opacity(0.5), lineWidth: 1)
                        )
                    }
                    .accessibilityLabel("Mark as complete")
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(cardBackgroundColor)
                .shadow(
                    color: .black.opacity(colorScheme == .dark ? 0.3 : 0.08),
                    radius: 4,
                    x: 0,
                    y: 2
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(englishText). \(translation ?? ""). \(isCompleted ? "Completed." : "Not completed.") \(isFavorited ? "Favorited." : "")")
    }
    
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? 
            Color(.systemGray6) : 
            Color(.systemBackground)
    }
    
    private var buttonBackgroundColor: Color {
        if isLoading {
            return Color.gray
        } else if isPlaying {
            return Color.orange
        } else {
            return Color.accentColor
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        AudioCard(
            englishText: "Hello, how are you today?",
            translation: "Hola, ¿cómo estás hoy?",
            audioFileName: "hello_greeting",
            isPlaying: false,
            isLoading: false,
            isFavorited: true,
            isCompleted: false,
            onPlayTap: {},
            onFavoriteTap: {},
            onCompleteTap: {}
        )
        
        AudioCard(
            englishText: "I need medical help. Please call 911.",
            translation: "Necesito ayuda médica. Por favor llame al 911.",
            audioFileName: "medical_help",
            isPlaying: true,
            isLoading: false,
            isFavorited: false,
            isCompleted: true,
            onPlayTap: {},
            onFavoriteTap: {},
            onCompleteTap: {}
        )
        
        AudioCard(
            englishText: "Loading audio example...",
            translation: "Ejemplo de carga de audio...",
            audioFileName: "loading_example",
            isPlaying: false,
            isLoading: true,
            isFavorited: false,
            isCompleted: false,
            onPlayTap: {},
            onFavoriteTap: {},
            onCompleteTap: {}
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
} 