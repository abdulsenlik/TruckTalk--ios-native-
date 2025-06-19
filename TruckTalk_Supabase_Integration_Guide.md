# 🚀 TruckTalk Supabase REST Integration Guide

## 📋 Overview

This guide documents the complete Supabase REST API integration for TruckTalk iOS app, built with Swift 6, SwiftUI, and MVVM architecture. The integration provides authentication, data management, and offline-first functionality.

## 🏗️ Architecture Overview

### Core Components

```
TruckTalk/
├── Services/
│   ├── SupabaseAPI.swift          # Main API service
│   ├── LessonService.swift        # Lesson data management
│   └── DataService.swift          # Offline fallback
├── Views/
│   ├── AuthenticationView.swift   # Login/Signup UI
│   ├── SplashView.swift          # Loading screen
│   └── ContentView.swift         # Main entry point
└── Models/
    └── LessonModels.swift         # Data structures
```

## 🔐 Authentication Flow

### SupabaseAPI.swift Features

**JWT Token Management:**
- Automatic token storage using `@AppStorage`
- Token refresh handling
- Secure header injection for authenticated requests

**Authentication Methods:**
```swift
// Login
let result = try await supabaseAPI.login(email: "user@example.com", password: "password")

// Signup
let result = try await supabaseAPI.signup(email: "user@example.com", password: "password")

// Logout
await supabaseAPI.logout()
```

**State Management:**
- `@Published var isAuthenticated: Bool`
- `@Published var currentUser: User?`
- `@Published var isLoading: Bool`

## 📡 API Service Architecture

### Generic Request Method
```swift
func performRequest<T: Codable, U: Codable>(
    url: URL,
    method: HTTPMethod = .GET,
    body: T? = nil,
    requiresAuth: Bool = true
) async throws -> U
```

### Error Handling
```swift
enum SupabaseError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    case networkError(Error)
    case authenticationRequired
    case unauthorized
    case serverError(Int)
}
```

## 📚 Data Models

### Lesson Structure (Supabase-Compatible)
```swift
struct Lesson: Codable, Identifiable {
    let id: Int
    let title: String
    let day: Int
    let audio_url: String?
    let created_at: String?
    let updated_at: String?
}
```

### Emergency Phrases
```swift
struct SupabaseEmergencyPhrase: Codable, Identifiable {
    let id: Int
    let english_text: String
    let audio_url: String?
    let category: String
    let priority: Int?
    let created_at: String?
}
```

## 🔄 Offline-First Architecture

### LessonService.swift Strategy

**Dual Data Sources:**
1. **Online**: Supabase REST API
2. **Offline**: Local DataService with mock data

**Smart Fetching:**
```swift
// Try online first, fallback to offline
func fetchLessons() async {
    isLoading = true
    do {
        lessons = try await fetchLessonsFromAPI()
    } catch {
        print("API failed, using offline data: \(error)")
        await fallbackToOfflineData()
    }
    isLoading = false
}
```

**Sync Strategy:**
- Background sync when network available
- Conflict resolution (server wins)
- Last-modified tracking

## 🎨 UI Integration

### Authentication State Management
```swift
struct ContentView: View {
    @StateObject private var supabaseAPI = SupabaseAPI.shared
    
    var body: some View {
        Group {
            if supabaseAPI.isAuthenticated {
                MainTabView()
            } else {
                AuthenticationView()
            }
        }
    }
}
```

### Loading States
- Splash screen with animations
- In-app loading indicators
- Error state handling
- Retry mechanisms

## 🛡️ Security Best Practices

### Current Implementation
```swift
private struct Config {
    static let baseURL = "https://pvstwthufbertinmojuk.supabase.co"
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

### 🚨 Production Security Recommendations

**1. Move Credentials to Secure Storage:**
```swift
// Create Secrets.plist (add to .gitignore)
struct Config {
    static let baseURL = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String ?? ""
    static let anonKey = Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String ?? ""
}
```

**2. Use .xcconfig Files:**
```bash
# Debug.xcconfig
SUPABASE_URL = https://your-project.supabase.co
SUPABASE_ANON_KEY = your_anon_key_here
```

**3. Environment Variables:**
```swift
#if DEBUG
static let baseURL = "https://staging.supabase.co"
#else
static let baseURL = "https://production.supabase.co"
#endif
```

## 📊 API Endpoints

### Lessons API
```http
GET /rest/v1/lessons?order=day.asc,id.asc
GET /rest/v1/lessons?day=eq.1
GET /rest/v1/lessons?id=eq.123
```

### Emergency Phrases API
```http
GET /rest/v1/emergency_phrases?order=category.asc,priority.asc
GET /rest/v1/emergency_phrases?category=eq.roadside_assistance
```

### Authentication API
```http
POST /auth/v1/signup
POST /auth/v1/token?grant_type=password
POST /auth/v1/logout
```

## 🔧 Configuration

### Headers
```swift
private func getHeaders(requiresAuth: Bool = true) -> [String: String] {
    var headers = [
        "apikey": Config.anonKey,
        "Content-Type": "application/json"
    ]
    
    if requiresAuth, let token = accessToken {
        headers["Authorization"] = "Bearer \(token)"
    }
    
    return headers
}
```

### URL Construction
```swift
private func getBaseURL() -> String {
    return Config.baseURL
}
```

## 🧪 Testing Strategy

### Unit Tests
```swift
class SupabaseAPITests: XCTestCase {
    func testLoginSuccess() async throws {
        // Mock successful login
    }
    
    func testFetchLessons() async throws {
        // Test lesson fetching
    }
}
```

### Integration Tests
- Network connectivity scenarios
- Authentication flow testing
- Offline/online mode switching

## 🚀 Deployment Checklist

### Pre-Production
- [ ] Move credentials to secure storage
- [ ] Enable SSL pinning
- [ ] Add network timeout configurations
- [ ] Implement proper error logging
- [ ] Add analytics tracking
- [ ] Test offline functionality
- [ ] Validate data synchronization

### Production
- [ ] Use production Supabase URLs
- [ ] Enable RLS (Row Level Security)
- [ ] Set up monitoring and alerting
- [ ] Configure rate limiting
- [ ] Implement caching strategies

## 📈 Performance Optimizations

### Network Layer
- Request deduplication
- Response caching
- Background sync
- Batch operations

### UI Layer
- Lazy loading
- Image caching
- Pagination support
- Optimistic updates

## 🔍 Debugging Tips

### Network Debugging
```swift
// Enable detailed logging
#if DEBUG
print("Request URL: \(url)")
print("Headers: \(headers)")
print("Response: \(String(data: data, encoding: .utf8) ?? "No data")")
#endif
```

### Authentication Issues
```swift
// Check token validity
if let token = accessToken {
    print("Token expires: \(tokenExpirationDate)")
    print("Token valid: \(Date() < tokenExpirationDate)")
}
```

## 🔮 Future Enhancements

### Planned Features
- Real-time subscriptions
- File upload support
- Push notifications
- Advanced caching
- GraphQL integration
- Offline queue management

### Scalability Considerations
- Implement pagination
- Add search functionality
- Support multiple languages
- Add user preferences sync
- Implement analytics tracking

## 📚 Additional Resources

- [Supabase REST API Documentation](https://supabase.com/docs/guides/api)
- [Swift Concurrency Guide](https://developer.apple.com/documentation/swift/concurrency)
- [SwiftUI State Management](https://developer.apple.com/documentation/swiftui/managing-user-interface-state)
- [iOS Security Best Practices](https://developer.apple.com/documentation/security)

---

**Last Updated:** June 18, 2025  
**Version:** 1.0.0  
**Swift Version:** 6.0  
**iOS Version:** 18.5+ 