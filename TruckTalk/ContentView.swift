//
//  ContentView.swift
//  TruckTalk
//
//  Created by Senlik on 6/18/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var supabaseAPI = SupabaseAPI.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var showSplash = true
    
    var body: some View {
        Group {
            if showSplash {
                SplashView()
                    .onAppear {
                        // Show splash for 2 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation(.easeInOut(duration: 0.8)) {
                                showSplash = false
                            }
                        }
                    }
            } else {
                // Main app flow with onboarding check
                if !hasCompletedOnboarding {
                    OnboardingView()
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                } else if supabaseAPI.isAuthenticated {
                    MainTabView()
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                } else {
                    AuthenticationView()
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }
            }
        }
        .animation(.easeInOut(duration: 0.6), value: showSplash)
        .animation(.easeInOut(duration: 0.6), value: hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.6), value: supabaseAPI.isAuthenticated)
    }
}

#Preview("ContentView") {
    ContentView()
}

#Preview("ContentView - First Launch") {
    ContentView()
        .onAppear {
            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        }
}

#Preview("Splash") {
    SplashView()
}

#Preview("Onboarding Flow") {
    OnboardingView()
}
