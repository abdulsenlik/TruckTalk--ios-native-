import SwiftUI

/// Main onboarding container view with horizontal paging and page indicators
struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @Namespace private var namespace
    
    var body: some View {
        ZStack {
            // Main Content
            TabView(selection: $viewModel.currentIndex) {
                ForEach(OnboardingPage.pages) { page in
                    OnboardingPageView(
                        page: page,
                        isCurrentPage: viewModel.currentIndex == page.id,
                        namespace: namespace,
                        onSkip: {
                            viewModel.skipOnboarding()
                        },
                        onComplete: {
                            viewModel.completeOnboarding()
                        }
                    )
                    .tag(page.id)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.5), value: viewModel.currentIndex)
            
            // Custom Page Indicators
            VStack {
                Spacer()
                pageIndicators
                    .padding(.bottom, 100)
            }
        }
        .navigationBarHidden(true)
        .statusBarHidden(false)
        .onAppear {
            setupHaptics()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Onboarding screen")
        .accessibilityValue("Page \(viewModel.currentIndex + 1) of \(OnboardingPage.pages.count)")
    }
    
    // MARK: - Page Indicators
    private var pageIndicators: some View {
        HStack(spacing: 12) {
            ForEach(0..<OnboardingPage.pages.count, id: \.self) { index in
                Circle()
                    .fill(index == viewModel.currentIndex ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(width: index == viewModel.currentIndex ? 12 : 8, height: index == viewModel.currentIndex ? 12 : 8)
                    .scaleEffect(index == viewModel.currentIndex ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.currentIndex)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            viewModel.goToPage(index)
                        }
                    }
                    .accessibilityElement()
                    .accessibilityLabel("Page \(index + 1)")
                    .accessibilityHint("Tap to go to page \(index + 1)")
                    .accessibilityAddTraits(index == viewModel.currentIndex ? .isSelected : [])
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        )
    }
    
    // MARK: - Setup Methods
    private func setupHaptics() {
        // Prepare haptic feedback generators for better performance
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        let notificationFeedback = UINotificationFeedbackGenerator()
        impactFeedback.prepare()
        notificationFeedback.prepare()
    }
}

// MARK: - OnboardingViewModel
@MainActor
class OnboardingViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentIndex: Int = 0
    @Published var showPageIndicator: Bool = true
    @Published var isAnimating: Bool = false
    
    // MARK: - AppStorage for Persistence
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    
    // MARK: - Constants
    let pages = OnboardingPage.pages
    
    // MARK: - Computed Properties
    var currentPage: OnboardingPage {
        guard currentIndex < pages.count else {
            return pages.last ?? pages[0]
        }
        return pages[currentIndex]
    }
    
    var isFirstPage: Bool {
        currentIndex == 0
    }
    
    var isLastPage: Bool {
        currentIndex == pages.count - 1
    }
    
    var canGoNext: Bool {
        currentIndex < pages.count - 1
    }
    
    var canGoPrevious: Bool {
        currentIndex > 0
    }
    
    // MARK: - Navigation Methods
    
    /// Navigate to the next page with animation
    func nextPage() {
        guard canGoNext else { return }
        
        withAnimation(.easeInOut(duration: 0.5)) {
            isAnimating = true
            currentIndex += 1
        }
        
        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isAnimating = false
        }
    }
    
    /// Navigate to the previous page with animation
    func previousPage() {
        guard canGoPrevious else { return }
        
        withAnimation(.easeInOut(duration: 0.5)) {
            isAnimating = true
            currentIndex -= 1
        }
        
        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isAnimating = false
        }
    }
    
    /// Navigate to a specific page
    func goToPage(_ index: Int) {
        guard index >= 0 && index < pages.count else { return }
        
        withAnimation(.easeInOut(duration: 0.5)) {
            isAnimating = true
            currentIndex = index
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isAnimating = false
        }
    }
    
    /// Skip onboarding flow entirely
    func skipOnboarding() {
        withAnimation(.easeInOut(duration: 0.8)) {
            hasCompletedOnboarding = true
        }
        
        // Provide success haptic feedback
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.prepare()
        notificationFeedback.notificationOccurred(.success)
    }
    
    /// Complete onboarding flow
    func completeOnboarding() {
        withAnimation(.easeInOut(duration: 0.8)) {
            hasCompletedOnboarding = true
        }
        
        // Provide success haptic feedback
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.prepare()
        notificationFeedback.notificationOccurred(.success)
    }
    
    /// Reset onboarding (for testing/debug purposes)
    func resetOnboarding() {
        hasCompletedOnboarding = false
        currentIndex = 0
    }
    
    // MARK: - Accessibility Helpers
    
    /// Get accessibility announcement for current page
    var accessibilityPageAnnouncement: String {
        let pageNumber = currentIndex + 1
        let totalPages = pages.count
        let page = currentPage
        
        return "Page \(pageNumber) of \(totalPages). \(page.title). \(page.description)"
    }
    
    /// Get accessibility hint for navigation
    var accessibilityNavigationHint: String {
        if isLastPage {
            return "Tap Get Started to complete onboarding"
        } else {
            return "Swipe left to go to next page, or tap Skip to complete onboarding"
        }
    }
}

// MARK: - Preview
#Preview("Onboarding") {
    OnboardingView()
}

#Preview("Onboarding Page 1") {
    @Previewable @Namespace var namespace
    
    return OnboardingPageView(
        page: OnboardingPage.pages[0],
        isCurrentPage: true,
        namespace: namespace,
        onSkip: {},
        onComplete: {}
    )
}

#Preview("Onboarding Page Last") {
    @Previewable @Namespace var namespace
    
    return OnboardingPageView(
        page: OnboardingPage.pages[3],
        isCurrentPage: true,
        namespace: namespace,
        onSkip: {},
        onComplete: {}
    )
} 