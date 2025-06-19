import SwiftUI

struct AuthenticationView: View {
    @StateObject private var supabaseAPI = SupabaseAPI.shared
    @State private var isSignUpMode = false
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    headerSection
                    
                    // Form
                    authForm
                    
                    // Action Button
                    actionButton
                    
                    // Mode Toggle
                    modeToggle
                    
                    // Guest Mode
                    guestModeButton
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 40)
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.secondarySystemBackground)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationBarHidden(true)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .disabled(supabaseAPI.isLoading)
        .overlay {
            if supabaseAPI.isLoading {
                loadingOverlay
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // App Icon
            Circle()
                .fill(Color.accentColor.opacity(0.2))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "truck.fill")
                        .font(.title)
                        .foregroundColor(.accentColor)
                )
            
            VStack(spacing: 8) {
                Text("TruckTalk")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("English Learning for Truck Drivers")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var authForm: some View {
        VStack(spacing: 20) {
            // Email Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                TextField("Enter your email", text: $email)
                    .textFieldStyle(CustomTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .disabled(supabaseAPI.isLoading)
                    .accessibilityLabel("Email address")
            }
            
            // Password Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Password")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                SecureField("Enter your password", text: $password)
                    .textFieldStyle(CustomTextFieldStyle())
                    .textContentType(isSignUpMode ? .newPassword : .password)
                    .disabled(supabaseAPI.isLoading)
                    .accessibilityLabel("Password")
            }
            
            // Confirm Password (Sign Up Only)
            if isSignUpMode {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Confirm Password")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    SecureField("Confirm your password", text: $confirmPassword)
                        .textFieldStyle(CustomTextFieldStyle())
                        .textContentType(.newPassword)
                        .disabled(supabaseAPI.isLoading)
                        .accessibilityLabel("Confirm password")
                }
                .transition(.opacity.combined(with: .slide))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isSignUpMode)
    }
    
    private var actionButton: some View {
        Button(action: performAuthentication) {
            HStack {
                if supabaseAPI.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text(isSignUpMode ? "Create Account" : "Sign In")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isFormValid ? Color.accentColor : Color.secondary.opacity(0.5))
            )
            .foregroundColor(.white)
        }
        .disabled(!isFormValid || supabaseAPI.isLoading)
        .accessibilityLabel(isSignUpMode ? "Create account" : "Sign in")
        .accessibilityHint("Tap to \(isSignUpMode ? "create a new account" : "sign in to your account")")
    }
    
    private var modeToggle: some View {
        HStack {
            Text(isSignUpMode ? "Already have an account?" : "Don't have an account?")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isSignUpMode.toggle()
                    clearForm()
                }
            }) {
                Text(isSignUpMode ? "Sign In" : "Sign Up")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.accentColor)
            }
            .disabled(supabaseAPI.isLoading)
        }
    }
    
    private var guestModeButton: some View {
        VStack(spacing: 16) {
            HStack {
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(height: 1)
                
                Text("OR")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(height: 1)
            }
            
            Button(action: {
                // Continue without authentication
                // This would typically set a flag to skip auth
            }) {
                Text("Continue as Guest")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.secondary.opacity(0.5), lineWidth: 1)
                    )
            }
            .disabled(supabaseAPI.isLoading)
            .accessibilityLabel("Continue as guest")
            .accessibilityHint("Use the app without creating an account")
        }
    }
    
    private var loadingOverlay: some View {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
            .overlay(
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                    
                    Text(isSignUpMode ? "Creating Account..." : "Signing In...")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.regularMaterial)
                )
            )
    }
    
    // MARK: - Validation
    
    private var isFormValid: Bool {
        let emailValid = email.contains("@") && email.contains(".")
        let passwordValid = password.count >= 6
        
        if isSignUpMode {
            return emailValid && passwordValid && password == confirmPassword
        } else {
            return emailValid && passwordValid
        }
    }
    
    // MARK: - Actions
    
    private func performAuthentication() {
        Task {
            do {
                if isSignUpMode {
                    _ = try await supabaseAPI.signup(email: email, password: password)
                } else {
                    _ = try await supabaseAPI.login(email: email, password: password)
                }
                
                // Success - the app will automatically navigate due to authentication state change
                
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func clearForm() {
        email = ""
        password = ""
        confirmPassword = ""
        showError = false
        errorMessage = ""
    }
}

// MARK: - Custom Text Field Style

struct CustomTextFieldStyle: TextFieldStyle {
    @Environment(\.colorScheme) private var colorScheme
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6))
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
            )
            .font(.body)
    }
}

// MARK: - Preview

#Preview {
    AuthenticationView()
} 