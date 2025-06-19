import SwiftUI

struct HomeView: View {
    @EnvironmentObject var dataService: DataService
    @State private var selectedDay: BootcampDay?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    headerSection
                    
                    // Progress Overview
                    progressOverview
                    
                    // Bootcamp Days
                    bootcampSection
                    
                    // Quick Access Section
                    quickAccessSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100) // Account for tab bar
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("TruckTalk")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                // Future: Refresh from server
            }
        }
        .sheet(item: $selectedDay) { day in
            LessonDetailView(bootcampDay: day, dataService: dataService)
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome back!")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Ready to improve your English?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Streak indicator
                VStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .font(.title2)
                        .foregroundColor(.orange)
                    
                    Text("\(dataService.userProgress.streak)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    
                    Text("day streak")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.orange.opacity(0.1))
                )
            }
            
            // Online/Offline Status
            HStack(spacing: 8) {
                Circle()
                    .fill(dataService.isOnlineMode ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)
                
                Text(dataService.isOnlineMode ? "Connected" : "Offline Mode")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let lastSync = dataService.lastSyncDate {
                    Text("• Last sync: \(lastSync, formatter: timeFormatter)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if dataService.isOnlineMode {
                    Button("Sync") {
                        Task {
                            await dataService.refreshFromSupabase()
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.accentColor)
                }
            }
        }
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
    
    private var progressOverview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Progress")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 16) {
                // Current Day
                progressCard(
                    title: "Current Day",
                    value: "\(dataService.userProgress.currentDay)",
                    subtitle: "of 5",
                    icon: "calendar",
                    color: .blue
                )
                
                // Completed Lessons
                progressCard(
                    title: "Completed",
                    value: "\(dataService.userProgress.completedLessons.count)",
                    subtitle: "lessons",
                    icon: "checkmark.circle",
                    color: .green
                )
                
                // Study Time
                progressCard(
                    title: "Study Time",
                    value: "\(Int(dataService.userProgress.totalMinutesStudied))",
                    subtitle: "minutes",
                    icon: "clock",
                    color: .purple
                )
            }
        }
    }
    
    private func progressCard(title: String, value: String, subtitle: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            VStack(spacing: 2) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
    
    private var bootcampSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("5-Day Bootcamp")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("English for Truckers")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            LazyVStack(spacing: 16) {
                ForEach(dataService.bootcampDays) { day in
                    Button(action: {
                        selectedDay = day
                    }) {
                        LessonCard(
                            bootcampDay: day,
                            progress: day.completionPercentage,
                            isUnlocked: day.isUnlocked
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    private var quickAccessSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Access")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                quickAccessCard(
                    title: "Emergency Phrases",
                    subtitle: "Quick help when needed",
                    icon: "exclamationmark.triangle.fill",
                    color: .red
                ) {
                    // Navigate to emergency phrases
                }
                
                quickAccessCard(
                    title: "Favorites",
                    subtitle: "Your saved phrases",
                    icon: "heart.fill",
                    color: .pink
                ) {
                    // Navigate to favorites
                }
            }
        }
    }
    
    private func quickAccessCard(title: String, subtitle: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(16)
            .frame(height: 100)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    HomeView()
        .environmentObject(DataService())
} 