import SwiftUI

struct LanguageSelectorView: View {
    @StateObject private var languageManager = LanguageManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingConfirmation = false
    @State private var selectedLanguage: SupportedLanguage = .english
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Language List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(languageManager.availableLanguages, id: \.self) { language in
                            LanguageRow(
                                language: language,
                                isSelected: language == languageManager.selectedLanguage,
                                completeness: languageManager.translationCompleteness(for: language)
                            ) {
                                selectLanguage(language)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                
                // Info Footer
                infoFooter
            }
            .navigationTitle("Language")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            selectedLanguage = languageManager.selectedLanguage
        }
        .confirmationDialog(
            "Change Language",
            isPresented: $showingConfirmation,
            titleVisibility: .visible
        ) {
            Button("Change Language") {
                changeLanguage()
            }
            
            Button("Cancel", role: .cancel) {
                selectedLanguage = languageManager.selectedLanguage
            }
        } message: {
            Text("Changing your language will reload all content. Your progress will be saved.")
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 16) {
            Image(systemName: "globe")
                .font(.system(size: 60, weight: .light))
                .foregroundColor(.accentColor)
                .symbolRenderingMode(.hierarchical)
            
            VStack(spacing: 8) {
                Text("Choose Your Language")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Select your preferred language for lessons and emergency phrases")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    // MARK: - Info Footer
    private var infoFooter: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
                
                Text("100% Complete")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Image(systemName: "clock.circle.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
                
                Text("In Progress")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("All content works offline once downloaded")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    // MARK: - Actions
    private func selectLanguage(_ language: SupportedLanguage) {
        guard language != languageManager.selectedLanguage else { return }
        
        selectedLanguage = language
        showingConfirmation = true
    }
    
    private func changeLanguage() {
        withAnimation(.easeInOut(duration: 0.3)) {
            languageManager.changeLanguage(to: selectedLanguage)
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Language Row
struct LanguageRow: View {
    let language: SupportedLanguage
    let isSelected: Bool
    let completeness: Double
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Flag and Language Info
                HStack(spacing: 12) {
                    Text(language.flag)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(language.displayName)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text("Native language")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Completion Status
                HStack(spacing: 8) {
                    if completeness >= 1.0 {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title3)
                    } else if completeness > 0.0 {
                        ZStack {
                            Circle()
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 2)
                                .frame(width: 20, height: 20)
                            
                            Circle()
                                .trim(from: 0, to: completeness)
                                .stroke(Color.orange, lineWidth: 2)
                                .frame(width: 20, height: 20)
                                .rotationEffect(.degrees(-90))
                        }
                    } else {
                        Image(systemName: "clock.circle")
                            .foregroundColor(.secondary)
                            .font(.title3)
                    }
                    
                    // Selection Indicator
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.accentColor)
                            .font(.title3)
                    } else {
                        Image(systemName: "circle")
                            .foregroundColor(.secondary)
                            .font(.title3)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(LanguageRowButtonStyle(isSelected: isSelected))
        .accessibilityLabel(language.displayName)
        .accessibilityHint(isSelected ? "Currently selected language" : "Tap to select this language")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Button Style
struct LanguageRowButtonStyle: ButtonStyle {
    let isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor(configuration: configuration))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(borderColor, lineWidth: isSelected ? 2 : 0)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
    
    private func backgroundColor(configuration: Configuration) -> Color {
        if configuration.isPressed {
            return Color.accentColor.opacity(0.1)
        } else if isSelected {
            return Color.accentColor.opacity(0.08)
        } else {
            return Color(UIColor.systemBackground)
        }
    }
    
    private var borderColor: Color {
        return isSelected ? Color.accentColor : Color.clear
    }
}

// MARK: - Preview
struct LanguageSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LanguageSelectorView()
                .preferredColorScheme(.light)
            
            LanguageSelectorView()
                .preferredColorScheme(.dark)
            
            // Individual Row Preview
            VStack(spacing: 12) {
                LanguageRow(
                    language: .english,
                    isSelected: true,
                    completeness: 1.0
                ) {}
                
                LanguageRow(
                    language: .spanish,
                    isSelected: false,
                    completeness: 0.75
                ) {}
                
                LanguageRow(
                    language: .turkish,
                    isSelected: false,
                    completeness: 0.0
                ) {}
            }
            .padding()
            .previewDisplayName("Language Rows")
        }
    }
}

// MARK: - Sheet Presentation Helper
extension View {
    func languageSelector(isPresented: Binding<Bool>) -> some View {
        sheet(isPresented: isPresented) {
            LanguageSelectorView()
        }
    }
} 