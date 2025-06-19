import Foundation
import SwiftUI

/// Main Supabase API service for TruckTalk
/// Handles authentication, JWT token management, and REST API calls
@MainActor
class SupabaseAPI: ObservableObject {
    
    // MARK: - Configuration
    private struct Config {
        static let baseURL = "https://pvstwthufbertinmojuk.supabase.co"
        static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB2c3R3dGh1ZmJlcnRpbm1vanVrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDcwOTI2NDQsImV4cCI6MjA2MjY2ODY0NH0.PG7BJeWuYe-piU_JatbBfauK-I3d9sVh-2fJypAZHS8"
    }
    
    // MARK: - Published State
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    
    // MARK: - Token Storage
    @AppStorage("supabase_access_token") private var accessToken: String = ""
    @AppStorage("supabase_refresh_token") private var refreshToken: String = ""
    @AppStorage("supabase_user_id") private var userId: String = ""
    
    // MARK: - Singleton
    static let shared = SupabaseAPI()
    
    private init() {
        checkAuthStatus()
    }
    
    // MARK: - Models
    struct User: Codable, Identifiable {
        let id: String
        let email: String
        let createdAt: String
        
        enum CodingKeys: String, CodingKey {
            case id
            case email
            case createdAt = "created_at"
        }
    }
    
    struct AuthResponse: Codable {
        let accessToken: String
        let refreshToken: String
        let user: User
        
        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
            case user
        }
    }
    
    struct AuthRequest: Codable {
        let email: String
        let password: String
    }
    
    // MARK: - Error Types
    enum SupabaseError: Error, LocalizedError {
        case invalidURL
        case noData
        case invalidCredentials
        case networkError(String)
        case decodingError(String)
        case unauthorized
        case tokenExpired
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid URL configuration"
            case .noData:
                return "No data received from server"
            case .invalidCredentials:
                return "Invalid email or password"
            case .networkError(let message):
                return "Network error: \(message)"
            case .decodingError(let message):
                return "Data parsing error: \(message)"
            case .unauthorized:
                return "Unauthorized access"
            case .tokenExpired:
                return "Session expired. Please log in again."
            }
        }
    }
    
    // MARK: - Authentication Status
    private func checkAuthStatus() {
        isAuthenticated = !accessToken.isEmpty && !userId.isEmpty
        if isAuthenticated {
            // Create user object from stored data
            currentUser = User(id: userId, email: "", createdAt: "")
        }
    }
    
    // MARK: - HTTP Headers
    private var defaultHeaders: [String: String] {
        var headers = [
            "apikey": Config.anonKey,
            "Content-Type": "application/json"
        ]
        
        if !accessToken.isEmpty {
            headers["Authorization"] = "Bearer \(accessToken)"
        }
        
        return headers
    }
    
    // MARK: - Authentication Methods
    
    /// Sign up a new user with email and password
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password (minimum 6 characters)
    /// - Returns: AuthResponse containing user data and tokens
    func signup(email: String, password: String) async throws -> AuthResponse {
        guard let url = URL(string: "\(Config.baseURL)/auth/v1/signup") else {
            throw SupabaseError.invalidURL
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let request = AuthRequest(email: email, password: password)
        
        do {
            let response: AuthResponse = try await performRequest(
                url: url,
                method: "POST",
                body: request,
                requiresAuth: false
            )
            
            await storeAuthData(response)
            return response
            
        } catch {
            print("Signup error: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Sign in an existing user with email and password
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    /// - Returns: AuthResponse containing user data and tokens
    func login(email: String, password: String) async throws -> AuthResponse {
        guard let url = URL(string: "\(Config.baseURL)/auth/v1/token?grant_type=password") else {
            throw SupabaseError.invalidURL
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let request = AuthRequest(email: email, password: password)
        
        do {
            let response: AuthResponse = try await performRequest(
                url: url,
                method: "POST",
                body: request,
                requiresAuth: false
            )
            
            await storeAuthData(response)
            return response
            
        } catch {
            print("Login error: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Sign out the current user and clear stored tokens
    func logout() async {
        // Clear stored tokens
        accessToken = ""
        refreshToken = ""
        userId = ""
        
        // Update UI state
        isAuthenticated = false
        currentUser = nil
        
        print("User logged out successfully")
    }
    
    // MARK: - Token Management
    
    /// Store authentication data securely
    /// - Parameter response: AuthResponse containing tokens and user data
    private func storeAuthData(_ response: AuthResponse) async {
        accessToken = response.accessToken
        refreshToken = response.refreshToken
        userId = response.user.id
        
        currentUser = response.user
        isAuthenticated = true
        
        print("Authentication successful for user: \(response.user.email)")
    }
    
    /// Refresh the access token using the stored refresh token
    private func refreshAccessToken() async throws {
        guard !refreshToken.isEmpty else {
            throw SupabaseError.unauthorized
        }
        
        guard let url = URL(string: "\(Config.baseURL)/auth/v1/token?grant_type=refresh_token") else {
            throw SupabaseError.invalidURL
        }
        
        let requestBody = ["refresh_token": refreshToken]
        
        do {
            let response: AuthResponse = try await performRequest(
                url: url,
                method: "POST",
                body: requestBody,
                requiresAuth: false
            )
            
            await storeAuthData(response)
            
        } catch {
            // If refresh fails, logout user
            await logout()
            throw SupabaseError.tokenExpired
        }
    }
    
    // MARK: - Generic API Request Method
    
    /// Perform a generic HTTP request with automatic token refresh
    /// - Parameters:
    ///   - url: The request URL
    ///   - method: HTTP method (GET, POST, PUT, DELETE)
    ///   - body: Optional request body (will be JSON encoded)
    ///   - requiresAuth: Whether this request requires authentication
    /// - Returns: Decoded response of type T
    func performRequest<T: Codable, U: Codable>(
        url: URL,
        method: String = "GET",
        body: U? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        // Add headers
        for (key, value) in defaultHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add body if provided
        if let body = body {
            do {
                request.httpBody = try JSONEncoder().encode(body)
            } catch {
                throw SupabaseError.decodingError("Failed to encode request body")
            }
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SupabaseError.networkError("Invalid response type")
            }
            
            // Handle different status codes
            switch httpResponse.statusCode {
            case 200...299:
                break
            case 401:
                if requiresAuth {
                    // Try to refresh token and retry
                    try await refreshAccessToken()
                    return try await performRequest(url: url, method: method, body: body, requiresAuth: requiresAuth)
                } else {
                    throw SupabaseError.invalidCredentials
                }
            case 400:
                throw SupabaseError.invalidCredentials
            default:
                throw SupabaseError.networkError("HTTP \(httpResponse.statusCode)")
            }
            
            guard !data.isEmpty else {
                throw SupabaseError.noData
            }
            
            do {
                let decoder = JSONDecoder()
                return try decoder.decode(T.self, from: data)
            } catch {
                print("Decoding error: \(error)")
                print("Raw response: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
                throw SupabaseError.decodingError(error.localizedDescription)
            }
            
        } catch let error as SupabaseError {
            throw error
        } catch {
            throw SupabaseError.networkError(error.localizedDescription)
        }
    }
    
    // MARK: - Convenience Methods
    
    /// Check if user is currently authenticated
    var isUserAuthenticated: Bool {
        return isAuthenticated && !accessToken.isEmpty
    }
    
    /// Get current access token
    var currentAccessToken: String? {
        return isAuthenticated ? accessToken : nil
    }
}

// MARK: - Preview Helper
extension SupabaseAPI {
    /// Create a mock instance for SwiftUI previews
    static var preview: SupabaseAPI {
        let api = SupabaseAPI()
        api.isAuthenticated = true
        api.currentUser = User(id: "preview-user", email: "preview@trucktalk.com", createdAt: "2024-01-01")
        return api
    }
} 