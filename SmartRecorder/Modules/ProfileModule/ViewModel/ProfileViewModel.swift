import Foundation
import SwiftUI
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {
    
    @Published private(set) var mode: AuthMode = .register
    @Published private(set) var isLoading = false
    
    @Published internal var login = LoginForm()
    @Published internal var registerForm = RegistrationForm()
    
    @Published internal var errorMessage: String? = nil
    @Published internal var infoMessage: String? = nil
    
    private let authService = AuthorizationService()
    
    internal var canSubmit: Bool {
        switch mode {
        case .register:
            return registerForm.isValid
        case .login:
            return login.isValid
        }
    }
    
    internal func toggleMode() {
        withAnimation {
            mode = mode == .login ? .register : .login
        }
    }
    
    internal func submit() async {
        switch mode {
        case .register:
            await register()
        case .login:
            await login()
        }
    }
    
    internal func register() async {
        isLoading = true
        
        defer {
            isLoading = false
        }
        
        do {
            let payload = RegistrationPayload(
                username: registerForm.username,
                email: registerForm.email,
                password: registerForm.password,
                firstName: registerForm.firstName,
                lastName: registerForm.lastName
            )
            try await authService.register(payload)
            infoMessage = Texts.ProfilePage.Toasts.registrationSuccess
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            infoMessage = nil
        }
    }
    
    internal func login() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let payload = LoginPayload(
                email: login.email,
                password: login.password
            )
            try await authService.login(payload)
            infoMessage = Texts.ProfilePage.Toasts.loginSuccess
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            infoMessage = nil
        }
    }
    
    private func clearMessages() {
        errorMessage = nil
        infoMessage = nil
    }
}

