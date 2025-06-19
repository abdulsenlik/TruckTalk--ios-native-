import SwiftUI

extension Color {
    // MARK: - Custom Theme Colors
    static let truckTalkPrimary = Color("TruckTalkPrimary")
    static let truckTalkSecondary = Color("TruckTalkSecondary")
    static let truckTalkAccent = Color("TruckTalkAccent")
    
    // MARK: - Semantic Colors for Dark/Light Mode
    static let cardBackground = Color("CardBackground")
    static let surfaceBackground = Color("SurfaceBackground")
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")
    
    // MARK: - Emergency Category Colors
    static let emergencyRed = Color("EmergencyRed")
    static let emergencyOrange = Color("EmergencyOrange")
    static let emergencyBlue = Color("EmergencyBlue")
    static let emergencyGreen = Color("EmergencyGreen")
    static let emergencyPurple = Color("EmergencyPurple")
    
    // MARK: - System Color Fallbacks
    static var adaptiveBackground: Color {
        Color(.systemBackground)
    }
    
    static var adaptiveSecondaryBackground: Color {
        Color(.secondarySystemBackground)
    }
    
    static var adaptiveGroupedBackground: Color {
        Color(.systemGroupedBackground)
    }
    
    static var adaptivePrimary: Color {
        Color(.label)
    }
    
    static var adaptiveSecondary: Color {
        Color(.secondaryLabel)
    }
}

// MARK: - Helper Extensions
extension View {
    func cardStyle() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.adaptiveBackground)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
    }
    
    func emergencyCardStyle(for category: EmergencyCategory) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.adaptiveBackground)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
    }
} 