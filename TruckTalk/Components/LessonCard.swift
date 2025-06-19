import SwiftUI

struct LessonCard: View {
    let bootcampDay: BootcampDay
    let progress: Double
    let isUnlocked: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var languageManager: LanguageManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with day number and progress
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(languageManager.localizedTitle(for: bootcampDay))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .accessibilityLabel(languageManager.localizedTitle(for: bootcampDay))
                    
                    Text(languageManager.localizedDescription(for: bootcampDay))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                        .accessibilityLabel(languageManager.localizedDescription(for: bootcampDay))
                }
                
                Spacer()
                
                // Lock icon for locked lessons
                if !isUnlocked {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.secondary)
                        .font(.title2)
                        .accessibilityLabel("Lesson locked")
                }
            }
            
            // Progress bar
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Progress")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: isUnlocked ? .blue : .gray))
                    .scaleEffect(y: 1.2)
                    .accessibilityLabel("Progress: \(Int(progress * 100)) percent complete")
            }
            
            // Duration estimate
            if bootcampDay.estimatedMinutes > 0 {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    
                    Text("\(bootcampDay.estimatedMinutes) minutes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("Estimated duration: \(bootcampDay.estimatedMinutes) minutes")
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                .shadow(
                    color: colorScheme == .dark ? .clear : .black.opacity(0.1),
                    radius: 8,
                    x: 0,
                    y: 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(colorScheme == .dark ? Color(.systemGray5) : Color.clear, lineWidth: 1)
        )
        .opacity(isUnlocked ? 1.0 : 0.6)
        .accessibilityElement(children: .combine)
        .accessibilityHint(isUnlocked ? "Tap to start lesson" : "Complete previous lessons to unlock")
    }
}

#Preview {
    VStack(spacing: 20) {
        // Unlocked lesson
        LessonCard(
            bootcampDay: BootcampDay(
                id: 1,
                title: ["en": "Day 1: Basic Greetings & Introductions"],
                description: ["en": "Learn essential greetings and how to introduce yourself professionally"],
                isUnlocked: true,
                completionPercentage: 0.65,
                estimatedMinutes: 45,
                sections: [],
                objectives: ["en": ["Master professional greetings", "Learn introductions", "Practice communication"]]
            ),
            progress: 0.65,
            isUnlocked: true
        )
        
        // Locked lesson
        LessonCard(
            bootcampDay: BootcampDay(
                id: 4,
                title: ["en": "Day 4: Loading & Delivery"],
                description: ["en": "Communication for pickup and delivery processes"],
                isUnlocked: false,
                completionPercentage: 0.0,
                estimatedMinutes: 60,
                sections: [],
                objectives: ["en": ["Learn warehouse terminology", "Master delivery procedures", "Practice documentation"]]
            ),
            progress: 0.0,
            isUnlocked: false
        )
    }
    .padding()
    .environmentObject(LanguageManager.shared)
} 