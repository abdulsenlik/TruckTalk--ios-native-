import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            HomeView()
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                    Text("Home")
                }
                .tag(0)
            
            // Curriculum Tab
            CurriculumDetailView()
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "book.fill" : "book")
                    Text("Curriculum")
                }
                .tag(1)
            
            // Emergency Tab
            EmergencyPhrasesView()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "exclamationmark.triangle.fill" : "exclamationmark.triangle")
                    Text("Emergency")
                }
                .tag(2)
            
            // Progress Tab
            UserProgressView()
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "chart.line.uptrend.xyaxis" : "chart.line.uptrend.xyaxis")
                    Text("Progress")
                }
                .tag(3)
            
            // Profile Tab
            ProfileView()
                .tabItem {
                    Image(systemName: selectedTab == 4 ? "person.fill" : "person")
                    Text("Profile")
                }
                .tag(4)
        }
        .tint(.accentColor)
    }
}

// MARK: - User Progress View
struct UserProgressView: View {
    @EnvironmentObject var dataService: DataService
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Overall Progress
                    overallProgressSection
                    
                    // Weekly Progress
                    weeklyProgressSection
                    
                    // Achievements
                    achievementsSection
                    
                    // Study Statistics
                    statisticsSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var overallProgressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Overall Progress")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                // Bootcamp Progress
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("5-Day Bootcamp")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("\(dataService.userProgress.currentDay)/5 days completed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 6)
                            .frame(width: 60, height: 60)
                        
                        Circle()
                            .trim(from: 0, to: Double(dataService.userProgress.currentDay - 1) / 5.0)
                            .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .frame(width: 60, height: 60)
                            .rotationEffect(.degrees(-90))
                        
                        Text("\(Int((Double(dataService.userProgress.currentDay - 1) / 5.0) * 100))%")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                }
                
                // Lesson Progress
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Lessons Completed")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("\(dataService.userProgress.completedLessons.count) total lessons")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("\(dataService.userProgress.completedLessons.count)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                
                // Study Time
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Study Time")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("Total minutes practiced")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("\(Int(dataService.userProgress.totalMinutesStudied))")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
    }
    
    private var weeklyProgressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("This Week")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Current Streak")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("\(dataService.userProgress.streak) days")
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    }
                }
                
                // Weekly Goal Progress
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Weekly Goal")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("3/5 days")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    ProgressView(value: 0.6)
                        .tint(.accentColor)
                        .frame(height: 8)
                        .background(Color.secondary.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
    }
    
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Achievements")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                achievementCard(
                    title: "First Steps",
                    description: "Complete your first lesson",
                    icon: "star.fill",
                    isUnlocked: true,
                    color: .yellow
                )
                
                achievementCard(
                    title: "Quick Learner",
                    description: "Complete 5 lessons",
                    icon: "bolt.fill",
                    isUnlocked: dataService.userProgress.completedLessons.count >= 5,
                    color: .blue
                )
                
                achievementCard(
                    title: "Road Warrior",
                    description: "Complete all 5 days",
                    icon: "truck.fill",
                    isUnlocked: false,
                    color: .green
                )
                
                achievementCard(
                    title: "Streak Master",
                    description: "Study for 7 days straight",
                    icon: "flame.fill",
                    isUnlocked: dataService.userProgress.streak >= 7,
                    color: .orange
                )
            }
        }
    }
    
    private func achievementCard(title: String, description: String, icon: String, isUnlocked: Bool, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(isUnlocked ? color : .secondary)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(isUnlocked ? .primary : .secondary)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .frame(minHeight: 120)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isUnlocked ? color.opacity(0.1) : Color(.systemGray6))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .opacity(isUnlocked ? 1.0 : 0.6)
    }
    
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Statistics")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                statRow(title: "Favorite Phrases", value: "\(dataService.userProgress.favoritePhrases.count)")
                statRow(title: "Average Session", value: "8 min")
                statRow(title: "Best Streak", value: "\(max(7, dataService.userProgress.streak)) days")
                statRow(title: "Total Sessions", value: "12")
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
    }
    
    private func statRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Profile View
struct ProfileView: View {
    @StateObject private var supabaseAPI = SupabaseAPI.shared
    @State private var showLogoutAlert = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    profileHeader
                    
                    // Account Section (if authenticated)
                    if supabaseAPI.isAuthenticated {
                        accountSection
                    }
                    
                    // Settings
                    settingsSection
                    
                    // About
                    aboutSection
                    
                    // Logout (if authenticated)
                    if supabaseAPI.isAuthenticated {
                        logoutSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
        .alert("Sign Out", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                Task {
                    await supabaseAPI.logout()
                }
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Avatar
            Circle()
                .fill(Color.accentColor.opacity(0.2))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.title)
                        .foregroundColor(.accentColor)
                )
            
            VStack(spacing: 4) {
                if supabaseAPI.isAuthenticated {
                    Text(supabaseAPI.currentUser?.email ?? "User")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Authenticated User")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text("Guest User")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Sign in to sync progress")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
    
    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Account")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 0) {
                settingRow(icon: "person.circle.fill", title: "Profile Settings", action: {})
                Divider().padding(.leading, 44)
                settingRow(icon: "icloud.fill", title: "Sync Settings", action: {})
                Divider().padding(.leading, 44)
                settingRow(icon: "shield.fill", title: "Privacy", action: {})
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
    }
    
    private var logoutSection: some View {
        VStack(spacing: 16) {
            Button(action: {
                showLogoutAlert = true
            }) {
                Text("Sign Out")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 0) {
                settingRow(icon: "bell.fill", title: "Notifications", action: {})
                Divider().padding(.leading, 44)
                settingRow(icon: "speaker.wave.3.fill", title: "Audio Settings", action: {})
                Divider().padding(.leading, 44)
                settingRow(icon: "textformat", title: "Text Size", action: {})
                Divider().padding(.leading, 44)
                settingRow(icon: "moon.fill", title: "Dark Mode", action: {})
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
    }
    
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("About")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 0) {
                settingRow(icon: "questionmark.circle.fill", title: "Help & Support", action: {})
                Divider().padding(.leading, 44)
                settingRow(icon: "info.circle.fill", title: "About TruckTalk", action: {})
                Divider().padding(.leading, 44)
                settingRow(icon: "star.fill", title: "Rate App", action: {})
                
                #if DEBUG
                Divider().padding(.leading, 44)
                settingRow(icon: "arrow.clockwise.circle.fill", title: "Reset Onboarding (Debug)", action: {
                    UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
                })
                #endif
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
    }
    
    private func settingRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.accentColor)
                    .frame(width: 20)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    MainTabView()
} 