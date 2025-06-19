import SwiftUI

/// Comprehensive view for displaying curriculum content with tabs
/// Shows overview, vocabulary, dialogues, assessments, tips, and progress
struct CurriculumDetailView: View {
    @StateObject private var viewModel = CurriculumViewModel()
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var showFallbackBanner = false
    @State private var selectedTab: CurriculumTab = .vocabulary
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Error banner
                if let errorMessage = viewModel.audioManager.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.orange)
                        Spacer()
                        Button("Dismiss") {
                            viewModel.audioManager.errorMessage = nil
                        }
                        .font(.caption)
                        .foregroundColor(.orange)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.1))
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                CurriculumLanguageSelectorView(viewModel: viewModel, languageManager: languageManager)
                // Language flag/label
                HStack {
                    Text("Viewing in: ")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(languageManager.currentLanguage.displayName)
                        .font(.subheadline)
                        .bold()
                    Text(languageManager.currentLanguage.flag)
                        .font(.title3)
                }
                .padding(.top, 4)
                
                // Fallback banner
                if viewModel.currentLanguage != "en" && (viewModel.sections.first?.title == nil || viewModel.sections.first?.title == "") {
                    FallbackBanner()
                } else if viewModel.currentLanguage != languageManager.selectedLanguage.rawValue {
                    FallbackBanner()
                }
                
                // Main content
                TabView(selection: $selectedTab) {
                    VocabularyTabView(viewModel: viewModel)
                        .tabItem {
                            Image(systemName: "book.fill")
                            Text("Vocabulary")
                        }
                        .tag(CurriculumTab.vocabulary)
                    
                    DialoguesTabView(viewModel: viewModel)
                        .tabItem {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                            Text("Dialogues")
                        }
                        .tag(CurriculumTab.dialogues)
                    
                    AssessmentsTabView(viewModel: viewModel)
                        .tabItem {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Assessments")
                        }
                        .tag(CurriculumTab.assessments)
                    
                    TipsTabView(viewModel: viewModel)
                        .tabItem {
                            Image(systemName: "lightbulb.fill")
                            Text("Tips")
                        }
                        .tag(CurriculumTab.tips)
                    
                    ProgressTabView(viewModel: viewModel)
                        .tabItem {
                            Image(systemName: "chart.bar.fill")
                            Text("Progress")
                        }
                        .tag(CurriculumTab.progress)
                }
            }
            .navigationTitle("Traffic Stop Course")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        // Language selector
                        Menu {
                            ForEach(SupportedLanguage.allCases, id: \.self) { language in
                                Button(language.displayName) {
                                    languageManager.selectedLanguage = language
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(languageManager.selectedLanguage.flag)
                                Text(languageManager.selectedLanguage.displayName)
                                    .font(.caption)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                        }
                        
                        // Audio status indicator
                        if viewModel.audioManager.isPlaying {
                            HStack(spacing: 4) {
                                Image(systemName: "speaker.wave.2.fill")
                                    .foregroundColor(.orange)
                                Text("Playing")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
            }
            .onAppear {
                Task {
                    await viewModel.loadCurriculum()
                }
            }
            .onDisappear {
                // Stop audio when leaving the view
                viewModel.stopAllAudio()
            }
        }
    }
}

private struct CurriculumLanguageSelectorView: View {
    @ObservedObject var viewModel: CurriculumViewModel
    var languageManager: LanguageManager
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("🌍 Current Language: \(viewModel.currentLanguage)")
                .font(.caption)
                .foregroundColor(.secondary)
            Text("📊 Curriculum Status")
                .font(.headline)
            if viewModel.isLoading {
                HStack {
                    ProgressView().scaleEffect(0.8)
                    Text("Loading curriculum...").font(.caption)
                }
            } else {
                Text("✅ Loaded \(viewModel.sections.count) sections")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            HStack(spacing: 12) {
                ForEach(SupportedLanguage.allCases, id: \.self) { language in
                    Button(action: { languageManager.changeLanguage(to: language) }) {
                        Text(language.flag)
                            .font(.title2)
                            .padding(8)
                            .background(languageManager.currentLanguage == language ? Color.blue.opacity(0.3) : Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

private struct CurriculumContentView: View {
    @ObservedObject var viewModel: CurriculumViewModel
    @Namespace private var reloadNamespace
    var body: some View {
        Group {
            if viewModel.sections.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "book.closed").font(.system(size: 48)).foregroundColor(.gray)
                    Text("No curriculum sections available").font(.headline).foregroundColor(.gray)
                    Text("Current language: \(viewModel.currentLanguage)").font(.caption).foregroundColor(.secondary)
                    Button("Reload Curriculum") {
                        Task { await viewModel.reloadCurriculum() }
                    }.buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.opacity)
            } else {
                List {
                    ForEach(viewModel.sections) { section in
                        NavigationLink(destination: SectionDetailView(section: section, viewModel: viewModel)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(section.title).font(.headline)
                                Text(section.description).font(.caption).foregroundColor(.secondary).lineLimit(2)
                                HStack {
                                    Label("\(section.vocabulary.count)", systemImage: "textformat")
                                    Label("\(section.dialogues.count)", systemImage: "bubble.left.and.bubble.right")
                                    Label("\(section.assessments.count)", systemImage: "questionmark.circle")
                                    Spacer()
                                    Text(section.difficulty.displayName)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.green.opacity(0.2))
                                        .cornerRadius(4)
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .transition(.opacity)
                .id(viewModel.currentLanguage) // force reload animation on language change
            }
        }
        .animation(.easeInOut, value: viewModel.currentLanguage)
    }
}

// MARK: - Section Detail View
struct SectionDetailView: View {
    let section: CurriculumSection
    @ObservedObject var viewModel: CurriculumViewModel
    @State private var showVocabulary = true
    @State private var showDialogues = false
    @State private var showTips = false
    @State private var selectedTab = 0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Overview
                Text(section.description)
                    .font(.body)
                    .padding(.bottom, 4)
                HStack(spacing: 16) {
                    Label("\(section.vocabulary.count)", systemImage: "textformat")
                    Label("\(section.dialogues.count)", systemImage: "bubble.left.and.bubble.right")
                    Label("\(section.assessments.count)", systemImage: "questionmark.circle")
                    Label("\(section.tips.count)", systemImage: "lightbulb")
                    Spacer()
                    Text(section.difficulty.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(4)
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 4)
                // Collapsible Vocabulary
                DisclosureGroup(isExpanded: $showVocabulary) {
                    ForEach(section.vocabulary) { vocabulary in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "textformat")
                                    .foregroundColor(.blue)
                                Text(vocabulary.word)
                                    .font(.headline)
                                Spacer()
                                Text(viewModel.getTranslation(for: vocabulary))
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                            Text(vocabulary.definition)
                                .font(.body)
                            Text("Pronunciation: \(vocabulary.pronunciation)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("Example: \(vocabulary.example)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .italic()
                        }
                        .padding(.vertical, 4)
                    }
                } label: {
                    Label("Vocabulary", systemImage: "textformat")
                        .font(.headline)
                }
                .padding(.vertical, 4)
                // Collapsible Dialogues
                DisclosureGroup(isExpanded: $showDialogues) {
                    ForEach(section.dialogues) { dialogue in
                        DialogueCard(
                            dialogue: dialogue,
                            viewModel: viewModel
                        )
                    }
                } label: {
                    Label("Dialogues", systemImage: "bubble.left")
                        .font(.headline)
                }
                .padding(.vertical, 4)
                // Collapsible Tips
                DisclosureGroup(isExpanded: $showTips) {
                    ForEach(section.tips, id: \.self) { tip in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "lightbulb")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            Text(tip)
                                .font(.body)
                        }
                        .padding(.vertical, 4)
                    }
                } label: {
                    Label("Tips", systemImage: "lightbulb")
                        .font(.headline)
                }
                .padding(.vertical, 4)
                // Assessments (not collapsible)
                if !section.assessments.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Assessments", systemImage: "questionmark.circle")
                            .font(.headline)
                        ForEach(section.assessments) { assessment in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(assessment.question)
                                    .font(.headline)
                                if let options = assessment.options {
                                    ForEach(options, id: \.self) { option in
                                        Text("• \(option)")
                                            .font(.body)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Text("Correct: \(assessment.correctAnswer)")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                Text(assessment.explanation)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .italic()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
        }
        .navigationTitle(section.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Section Header View

struct SectionHeaderView: View {
    let section: CurriculumSection
    let viewModel: CurriculumViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(section.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(section.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack {
                        Image(systemName: section.difficulty.icon)
                            .foregroundColor(Color(section.difficulty.color))
                        Text(section.difficulty.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("\(section.estimatedMinutes) min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Progress bar (placeholder)
            ProgressView(value: 0.0)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
        }
        .padding()
        .background(Color(.systemBackground))
        .shadow(radius: 1)
    }
}

// MARK: - Tab Selector View

struct TabSelectorView: View {
    @ObservedObject var viewModel: CurriculumViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(CurriculumTab.allCases, id: \.self) { tab in
                    TabButton(
                        tab: tab,
                        isSelected: viewModel.currentTab == tab,
                        action: { viewModel.switchToTab(tab) }
                    )
                }
            }
        }
        .background(Color(.systemBackground))
        .shadow(radius: 1)
    }
}

struct TabButton: View {
    let tab: CurriculumTab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: tab.icon)
                    .font(.caption)
                Text(tab.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color.clear)
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Overview Tab View

struct OverviewTabView: View {
    @ObservedObject var viewModel: CurriculumViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if let section = viewModel.selectedSection {
                    // Section statistics
                    SectionStatsView(section: section)
                    
                    // Quick access cards
                    QuickAccessCardsView(viewModel: viewModel)
                    
                    // Section content preview
                    SectionPreviewView(section: section, viewModel: viewModel)
                }
            }
            .padding()
        }
    }
}

struct SectionStatsView: View {
    let section: CurriculumSection
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Section Overview")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 16) {
                StatCard(
                    title: "Vocabulary",
                    value: "\(section.vocabulary.count)",
                    icon: "textformat",
                    color: .blue
                )
                
                StatCard(
                    title: "Dialogues",
                    value: "\(section.dialogues.count)",
                    icon: "bubble.left.and.bubble.right.fill",
                    color: .green
                )
                
                StatCard(
                    title: "Assessments",
                    value: "\(section.assessments.count)",
                    icon: "checkmark.circle.fill",
                    color: .orange
                )
                
                StatCard(
                    title: "Tips",
                    value: "\(section.tips.count)",
                    icon: "lightbulb.fill",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct QuickAccessCardsView: View {
    @ObservedObject var viewModel: CurriculumViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Quick Access")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickAccessCard(
                    title: "Practice Vocabulary",
                    icon: "textformat",
                    color: .blue
                ) {
                    viewModel.switchToTab(.vocabulary)
                }
                
                QuickAccessCard(
                    title: "Practice Dialogues",
                    icon: "bubble.left.and.bubble.right.fill",
                    color: .green
                ) {
                    viewModel.switchToTab(.dialogues)
                }
                
                QuickAccessCard(
                    title: "Take Assessments",
                    icon: "checkmark.circle.fill",
                    color: .orange
                ) {
                    viewModel.switchToTab(.assessments)
                }
                
                QuickAccessCard(
                    title: "View Tips",
                    icon: "lightbulb.fill",
                    color: .purple
                ) {
                    viewModel.switchToTab(.tips)
                }
            }
        }
    }
}

struct QuickAccessCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SectionPreviewView: View {
    let section: CurriculumSection
    let viewModel: CurriculumViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Content Preview")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Vocabulary preview
            if !section.vocabulary.isEmpty {
                VocabularyPreviewCard(vocabulary: section.vocabulary.prefix(3))
            }
            
            // Dialogue preview
            if !section.dialogues.isEmpty {
                DialoguePreviewCard(dialogue: section.dialogues.first!)
            }
            
            // Assessment preview
            if !section.assessments.isEmpty {
                AssessmentPreviewCard(assessment: section.assessments.first!)
            }
        }
    }
}

// MARK: - Vocabulary Tab View

struct VocabularyTabView: View {
    @ObservedObject var viewModel: CurriculumViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Search and filter bar
            SearchFilterBar(viewModel: viewModel)
            
            // Vocabulary list
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.selectedSectionVocabulary) { vocabulary in
                        VocabularyCard(
                            vocabulary: vocabulary,
                            viewModel: viewModel
                        )
                    }
                }
                .padding()
            }
        }
    }
}

struct SearchFilterBar: View {
    @ObservedObject var viewModel: CurriculumViewModel
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search vocabulary...", text: $viewModel.searchQuery)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !viewModel.searchQuery.isEmpty {
                    Button("Clear") {
                        viewModel.clearSearch()
                    }
                    .font(.caption)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(8)
            
            // Filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(
                        title: "All",
                        isSelected: viewModel.filterDifficulty == nil
                    ) {
                        viewModel.filterDifficulty = nil
                    }
                    
                    ForEach(DifficultyLevel.allCases, id: \.self) { difficulty in
                        FilterChip(
                            title: difficulty.displayName,
                            isSelected: viewModel.filterDifficulty == difficulty
                        ) {
                            viewModel.filterDifficulty = difficulty
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.secondarySystemBackground))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct VocabularyCard: View {
    let vocabulary: VocabularyItem
    @ObservedObject var viewModel: CurriculumViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(vocabulary.word)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(viewModel.getTranslation(for: vocabulary))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button {
                    viewModel.toggleVocabularyAudio(vocabulary)
                } label: {
                    HStack(spacing: 4) {
                        if viewModel.audioManager.isLoading && viewModel.audioManager.currentAudioId == vocabulary.id.uuidString {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: viewModel.isVocabularyAudioPlaying(vocabulary) ? "pause.fill" : "speaker.wave.2.fill")
                        }
                    }
                    .foregroundColor(viewModel.isVocabularyAudioPlaying(vocabulary) ? .orange : .blue)
                    .frame(width: 30, height: 30)
                }
                .disabled(viewModel.audioManager.isLoading)
            }
            
            Text(vocabulary.definition)
                .font(.body)
            
            Text("Pronunciation: \(vocabulary.pronunciation)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Example: \(vocabulary.example)")
                .font(.caption)
                .foregroundColor(.secondary)
                .italic()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .onTapGesture {
            viewModel.selectVocabulary(vocabulary)
        }
    }
}

// MARK: - Dialogues Tab View

struct DialoguesTabView: View {
    @ObservedObject var viewModel: CurriculumViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.selectedSectionDialogues) { dialogue in
                    DialogueCard(
                        dialogue: dialogue,
                        viewModel: viewModel
                    )
                }
            }
            .padding()
        }
    }
}

struct DialogueCard: View {
    let dialogue: Dialogue
    @ObservedObject var viewModel: CurriculumViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(dialogue.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button {
                    // Play first exchange audio or mock audio for the dialogue
                    if let firstExchange = dialogue.exchanges.first {
                        viewModel.toggleDialogueAudio(firstExchange)
                    } else {
                        let idString = dialogue.id.uuidString
                        viewModel.audioManager.playAudio(fileName: "dialogue_\(String(idString.prefix(8)))", audioId: idString)
                    }
                } label: {
                    HStack(spacing: 4) {
                        if viewModel.audioManager.isLoading && viewModel.audioManager.currentAudioId == dialogue.id.uuidString {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: viewModel.audioManager.currentAudioId == dialogue.id.uuidString && viewModel.audioManager.isPlaying ? "pause.fill" : "speaker.wave.3.fill")
                        }
                    }
                    .foregroundColor(viewModel.audioManager.currentAudioId == dialogue.id.uuidString && viewModel.audioManager.isPlaying ? .orange : .blue)
                    .frame(width: 30, height: 30)
                }
                .disabled(viewModel.audioManager.isLoading)
            }
            
            ForEach(dialogue.exchanges.prefix(3)) { exchange in
                HStack(alignment: .top, spacing: 8) {
                    Text(exchange.speaker)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                        .frame(width: 60, alignment: .leading)
                    
                    Text(exchange.text)
                        .font(.body)
                    
                    Spacer()
                    
                    // Individual exchange audio button
                    Button {
                        viewModel.toggleDialogueAudio(exchange)
                    } label: {
                        HStack(spacing: 4) {
                            if viewModel.audioManager.isLoading && viewModel.audioManager.currentAudioId == exchange.id.uuidString {
                                ProgressView()
                                    .scaleEffect(0.6)
                            } else {
                                Image(systemName: viewModel.isDialogueAudioPlaying(exchange) ? "pause.fill" : "speaker.wave.1.fill")
                            }
                        }
                        .foregroundColor(viewModel.isDialogueAudioPlaying(exchange) ? .orange : .secondary)
                        .frame(width: 24, height: 24)
                    }
                    .disabled(viewModel.audioManager.isLoading)
                }
            }
            
            if dialogue.exchanges.count > 3 {
                Text("+ \(dialogue.exchanges.count - 3) more exchanges")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .onTapGesture {
            viewModel.selectDialogue(dialogue)
        }
    }
}

// MARK: - Assessments Tab View

struct AssessmentsTabView: View {
    @ObservedObject var viewModel: CurriculumViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter bar
            AssessmentFilterBar(viewModel: viewModel)
            
            // Assessment list
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.selectedSectionAssessments) { assessment in
                        AssessmentCard(
                            assessment: assessment,
                            viewModel: viewModel
                        )
                    }
                }
                .padding()
            }
        }
    }
}

struct AssessmentFilterBar: View {
    @ObservedObject var viewModel: CurriculumViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(
                    title: "All Types",
                    isSelected: viewModel.filterType == nil
                ) {
                    viewModel.filterType = nil
                }
                
                ForEach(QuestionType.allCases, id: \.self) { type in
                    FilterChip(
                        title: type.displayName,
                        isSelected: viewModel.filterType == type
                    ) {
                        viewModel.filterType = type
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
    }
}

struct AssessmentCard: View {
    let assessment: AssessmentQuestion
    @ObservedObject var viewModel: CurriculumViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(assessment.type.displayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    
                    Text(assessment.skillTested.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: assessment.difficulty.icon)
                        .foregroundColor(Color(assessment.difficulty.color))
                    Text(assessment.difficulty.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(assessment.question)
                .font(.body)
                .fontWeight(.medium)
            
            // Audio button for audio-based assessments
            if assessment.type == .audioBased {
                HStack {
                    Button {
                        viewModel.toggleAssessmentAudio(assessment)
                    } label: {
                        HStack(spacing: 8) {
                            if viewModel.audioManager.isLoading && viewModel.audioManager.currentAudioId == assessment.id {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: viewModel.isAssessmentAudioPlaying(assessment) ? "pause.fill" : "speaker.wave.3.fill")
                            }
                            
                            Text(viewModel.isAssessmentAudioPlaying(assessment) ? "Playing..." : "Play Audio")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(viewModel.isAssessmentAudioPlaying(assessment) ? Color.orange : Color.blue)
                        )
                    }
                    .disabled(viewModel.audioManager.isLoading)
                    
                    Spacer()
                }
            }
            
            if let options = assessment.options {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(options, id: \.self) { option in
                        Text("• \(option)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .onTapGesture {
            viewModel.selectAssessment(assessment)
        }
    }
}

// MARK: - Tips Tab View

struct TipsTabView: View {
    @ObservedObject var viewModel: CurriculumViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(Array(viewModel.selectedSectionTips.enumerated()), id: \.offset) { index, tip in
                    TipCard(tip: tip, index: index + 1)
                }
            }
            .padding()
        }
    }
}

struct TipCard: View {
    let tip: String
    let index: Int
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(index)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Color.blue)
                .clipShape(Circle())
            
            Text(tip)
                .font(.body)
            
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Progress Tab View

struct ProgressTabView: View {
    @ObservedObject var viewModel: CurriculumViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Overall progress
                OverallProgressCard(stats: viewModel.stats)
                
                // Section progress
                SectionProgressList(viewModel: viewModel)
            }
            .padding()
        }
    }
}

struct OverallProgressCard: View {
    let stats: CurriculumStats
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Overall Progress")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                ProgressRow(
                    title: "Sections",
                    completed: stats.completedSections,
                    total: stats.totalSections
                )
                
                ProgressRow(
                    title: "Vocabulary",
                    completed: stats.completedVocabulary,
                    total: stats.totalVocabulary
                )
                
                ProgressRow(
                    title: "Dialogues",
                    completed: stats.completedDialogues,
                    total: stats.totalDialogues
                )
                
                ProgressRow(
                    title: "Assessments",
                    completed: stats.completedAssessments,
                    total: stats.totalAssessments
                )
            }
            
            HStack {
                Text("Total Study Time")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(stats.estimatedTotalMinutes) min")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct ProgressRow: View {
    let title: String
    let completed: Int
    let total: Int
    
    private var progress: Double {
        total > 0 ? Double(completed) / Double(total) : 0.0
    }
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(title)
                    .font(.subheadline)
                
                Spacer()
                
                Text("\(completed)/\(total)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
        }
    }
}

struct SectionProgressList: View {
    @ObservedObject var viewModel: CurriculumViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Section Progress")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ForEach(viewModel.mainSections) { section in
                SectionProgressRow(
                    section: section,
                    isCompleted: viewModel.isSectionCompleted(section.id)
                )
            }
        }
    }
}

struct SectionProgressRow: View {
    let section: CurriculumSection
    let isCompleted: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(section.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(section.estimatedMinutes) min • \(section.difficulty.displayName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Image(systemName: "circle")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Preview Cards

struct VocabularyPreviewCard: View {
    let vocabulary: ArraySlice<VocabularyItem>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "textformat")
                    .foregroundColor(.blue)
                Text("Vocabulary Preview")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            ForEach(Array(vocabulary), id: \.id) { item in
                HStack {
                    Text(item.word)
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text(item.translation["en"] ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct DialoguePreviewCard: View {
    let dialogue: Dialogue
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .foregroundColor(.green)
                Text("Dialogue Preview")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            Text(dialogue.title)
                .font(.caption)
                .fontWeight(.medium)
            
            if let firstExchange = dialogue.exchanges.first {
                HStack {
                    Text(firstExchange.speaker)
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Text(firstExchange.text)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct AssessmentPreviewCard: View {
    let assessment: AssessmentQuestion
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.orange)
                Text("Assessment Preview")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            Text(assessment.question)
                .font(.caption)
                .lineLimit(2)
            
            HStack {
                Text(assessment.type.displayName)
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Spacer()
                
                Text(assessment.difficulty.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Preview

struct CurriculumDetailView_Previews: PreviewProvider {
    static var previews: some View {
        CurriculumDetailView()
    }
}

private struct FallbackBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellow)
            Text("This content is not yet translated. Showing English instead.")
                .font(.caption)
                .foregroundColor(.primary)
        }
        .padding(8)
        .background(Color.yellow.opacity(0.15))
        .cornerRadius(8)
        .padding(.horizontal)
        .padding(.bottom, 4)
    }
} 