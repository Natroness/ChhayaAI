import SwiftUI
import FirebaseAuth
import FirebaseCore

enum FirebaseConfiguration {
    static func ensureConfigured() {
        guard FirebaseApp.app() == nil else { return }
        FirebaseApp.configure()
    }
}

@Observable
final class AuthService {
    var user: FirebaseAuth.User?
    var isCheckingAuth = true
    var isLoading = false
    var errorMessage: String?

    var isAuthenticated: Bool { user != nil }

    var displayName: String {
        user?.displayName ?? user?.email?.components(separatedBy: "@").first ?? "User"
    }

    var userInitial: String {
        String(displayName.prefix(1)).uppercased()
    }

    /// Firebase uid for `user_id` in agent API requests.
    var backendUserId: String {
        user?.uid ?? "anonymous"
    }

    private var handle: AuthStateDidChangeListenerHandle?

    init() {
        FirebaseConfiguration.ensureConfigured()
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.user = user
                self?.isCheckingAuth = false
            }
        }
    }

    deinit {
        if let handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    // MARK: - Actions

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
        } catch {
            logAuthError(error, operation: "signIn")
            errorMessage = mapError(error)
        }
        isLoading = false
    }

    func signUp(email: String, password: String, fullName: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = fullName
            try await changeRequest.commitChanges()
            user = Auth.auth().currentUser
        } catch {
            logAuthError(error, operation: "signUp")
            errorMessage = mapError(error)
        }
        isLoading = false
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            logAuthError(error, operation: "signOut")
            errorMessage = mapError(error)
        }
    }

    func resetPassword(email: String) async {
        isLoading = true
        errorMessage = nil
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch {
            logAuthError(error, operation: "resetPassword")
            errorMessage = mapError(error)
        }
        isLoading = false
    }

    // MARK: - Helpers

    private func mapError(_ error: Error) -> String {
        let code = (error as NSError).code
        switch code {
        case AuthErrorCode.wrongPassword.rawValue:
            return "Incorrect password. Please try again."
        case AuthErrorCode.invalidEmail.rawValue:
            return "Invalid email address."
        case AuthErrorCode.userNotFound.rawValue:
            return "No account found with this email."
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            return "An account with this email already exists."
        case AuthErrorCode.weakPassword.rawValue:
            return "Password must be at least 6 characters."
        case AuthErrorCode.networkError.rawValue:
            return "Network error. Check your connection."
        case AuthErrorCode.tooManyRequests.rawValue:
            return "Too many attempts. Please try again later."
        default:
            return error.localizedDescription
        }
    }

    private func logAuthError(_ error: Error, operation: String) {
        let nsError = error as NSError
        print(
            """
            Firebase Auth \(operation) failed
            domain: \(nsError.domain)
            code: \(nsError.code)
            description: \(nsError.localizedDescription)
            userInfo: \(nsError.userInfo)
            """
        )

        if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? NSError {
            print(
                """
                Underlying error
                domain: \(underlyingError.domain)
                code: \(underlyingError.code)
                description: \(underlyingError.localizedDescription)
                userInfo: \(underlyingError.userInfo)
                """
            )
        }
    }
}
