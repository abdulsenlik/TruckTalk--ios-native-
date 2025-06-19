import SwiftUI

/// Comprehensive view for displaying curriculum content with tabs
/// Shows overview, vocabulary, dialogues, assessments, tips, and progress
struct CurriculumDetailView: View {
    @StateObject private var viewModel = CurriculumViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with section info
                if let section = viewModel.selectedSection {
                    SectionHeaderView(section: section, viewModel: viewModel)
                }
                
                // Tab selector
                TabSelectorView(viewModel: viewModel)
                
                // Tab content
                TabView(selection: $viewModel.currentTab) {
                    OverviewTabView(viewModel: viewModel)
                        .tag(CurriculumTab.overview)
                    
                    VocabularyTabView(viewModel: viewModel)
                        .tag(CurriculumTab.vocabulary)
                    
                    DialoguesTabView(viewModel: viewModel)
                        .tag(CurriculumTab.dialogues)
                    
                    AssessmentsTabView(viewModel: viewModel)
                        .tag(CurriculumTab.assessments)
                    
                    TipsTabView(viewModel: viewModel)
                        .tag(CurriculumTab.tips)
                    
                    ProgressTabView(viewModel: viewModel)
                        .tag(CurriculumTab.progress)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Curriculum")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Practice Mode") {
                            viewModel.startPracticeMode()
                        }
                        
                        Button("Clear Filters") {
                            viewModel.clearFilters()
                        }
                        
                        Button("Random Content") {
                            viewModel.startPracticeMode()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .onAppear {
            // Select first section if none selected
            if viewModel.selectedSection == nil {
                viewModel.selectedSection = viewModel.mainSections.first
            }
        }
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
                    viewModel.playVocabularyAudio(vocabulary)
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .foregroundColor(.blue)
                }
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
                    // Play dialogue audio
                } label: {
                    Image(systemName: "speaker.wave.3.fill")
                        .foregroundColor(.blue)
                }
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