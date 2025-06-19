import SwiftUI

/// Reusable onboarding page component following Apple's Human Interface Guidelines
struct OnboardingPageView: View {
    let page: OnboardingPage
    let isCurrentPage: Bool
    let namespace: Namespace.ID
    let onSkip: () -> Void
    let onComplete: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @ScaledMetric(relativeTo: .largeTitle) private var titleSize: CGFloat = 32
    @ScaledMetric(relativeTo: .title3) private var descriptionSize: CGFloat = 18
    @State private var imageScale: CGFloat = 0.8
    @State private var textOpacity: Double = 0.0
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Image Section
            imageSection
            
            // Content Section
            contentSection
            
            Spacer()
            
            // Action Section
            actionSection
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundGradient)
        .onAppear {
            animateContent()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(page.title + ". " + page.description)
        .accessibilityHint(page.accessibilityHint ?? "")
    }
    
    // MARK: - Image Section
    private var imageSection: some View {
        ZStack {
            // Placeholder for custom images (using SF Symbols as fallback)
            Group {
                if page.imageName == "onboarding_truck" {
                    Image(systemName: "truck.box.fill")
                } else if page.imageName == "onboarding_audio" {
                    Image(systemName: "speaker.wave.3.fill")
                } else if page.imageName == "onboarding_progress" {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                } else {
                    Image(systemName: "star.fill")
                }
            }
            .font(.system(size: 100))
            .foregroundStyle(
                LinearGradient(
                    colors: [.accentColor, .accentColor.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .scaleEffect(imageScale)
            .matchedGeometryEffect(id: "onboarding_image_\(page.id)", in: namespace)
            
            // Background circle
            Circle()
                .fill(Color.accentColor.opacity(0.1))
                .frame(width: 200, height: 200)
                .scaleEffect(imageScale * 0.9)
                .blur(radius: 20)
        }
        .accessibilityLabel(page.accessibilityImageLabel)
        .accessibilityAddTraits(.isImage)
    }
    
    // MARK: - Content Section
    private var contentSection: some View {
        VStack(spacing: 16) {
            // Title
            Text(page.title)
                .font(.system(size: titleSize, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .opacity(textOpacity)
                .matchedGeometryEffect(id: "onboarding_title_\(page.id)", in: namespace)
            
            // Description
            Text(page.description)
                .font(.system(size: descriptionSize, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .opacity(textOpacity)
                .matchedGeometryEffect(id: "onboarding_description_\(page.id)", in: namespace)
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Action Section
    private var actionSection: some View {
        VStack(spacing: 20) {
            if page.isLastPage {
                // Get Started Button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        onComplete()
                    }
                }) {
                    HStack(spacing: 12) {
                        Text("Get Started")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title3)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [.accentColor, .accentColor.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .accentColor.opacity(0.3), radius: 8, y: 4)
                }
                .buttonStyle(ScaleButtonStyle())
                .accessibilityLabel("Get Started")
                .accessibilityHint("Complete onboarding and start using TruckTalk")
            } else {
                // Skip Button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        onSkip()
                    }
                }) {
                    Text("Skip")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(height: 44)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                }
                .buttonStyle(ScaleButtonStyle())
                .accessibilityLabel("Skip onboarding")
                .accessibilityHint("Skip the introduction and go directly to the app")
            }
        }
        .opacity(textOpacity)
    }
    
    // MARK: - Background
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(.systemBackground),
                Color(.systemBackground).opacity(0.95),
                Color(.secondarySystemBackground).opacity(0.5)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Animations
    private func animateContent() {
        withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
            imageScale = 1.0
        }
        
        withAnimation(.easeOut(duration: 0.6).delay(0.5)) {
            textOpacity = 1.0
        }
    }
}

// MARK: - Custom Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview
#Preview {
    @Previewable @Namespace var namespace
    
    return OnboardingPageView(
        page: OnboardingPage.pages[0],
        isCurrentPage: true,
        namespace: namespace,
        onSkip: {},
        onComplete: {}
    )
} 