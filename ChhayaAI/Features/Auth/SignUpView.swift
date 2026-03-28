import SwiftUI

struct SignUpView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var localError: String?

    private var effectiveError: String? {
        localError ?? authService.errorMessage
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.space6) {
                header

                VStack(spacing: Spacing.space4) {
                    AppTextField(
                        placeholder: "Full name",
                        text: $fullName,
                        icon: "person"
                    )
                    .textContentType(.name)

                    AppTextField(
                        placeholder: "Email address",
                        text: $email,
                        icon: "envelope"
                    )
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                    AppTextField(
                        placeholder: "Password",
                        text: $password,
                        icon: "lock",
                        isSecure: true
                    )
                    .textContentType(.newPassword)

                    AppTextField(
                        placeholder: "Confirm password",
                        text: $confirmPassword,
                        icon: "lock.shield",
                        isSecure: true
                    )
                    .textContentType(.newPassword)

                    if let error = effectiveError {
                        errorBanner(error)
                    }

                    AppButton(
                        title: "Create Account",
                        icon: "person.badge.plus",
                        style: .primary,
                        isLoading: authService.isLoading
                    ) {
                        signUp()
                    }

                    HStack(spacing: Spacing.space1) {
                        Text("Already have an account?")
                            .textStyle(.caption)
                            .foregroundStyle(SemanticColor.textSecondary)
                        Button("Sign In") {
                            dismiss()
                        }
                        .textStyle(.captionSemibold)
                        .foregroundStyle(SemanticColor.actionPrimary)
                    }
                }
                .padding(.horizontal, Spacing.screenPaddingH)
            }
            .padding(.bottom, Spacing.space12)
        }
        .background(ComponentColor.Screen.bg)
        .navigationTitle("Create Account")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            authService.errorMessage = nil
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: Spacing.space1) {
            Text("Join ChhayaAI")
                .textStyle(.headingLG)
                .foregroundStyle(SemanticColor.textPrimary)
            Text("Create your emergency response account")
                .textStyle(.body)
                .foregroundStyle(SemanticColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, Spacing.space4)
    }

    // MARK: - Components

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: Spacing.space2) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(SemanticColor.statusError)
            Text(message)
                .textStyle(.caption)
                .foregroundStyle(SemanticColor.statusError)
        }
        .padding(Spacing.space3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SemanticColor.statusError.opacity(AppOpacity.overlaySubtle))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
    }

    // MARK: - Validation & Sign Up

    private func signUp() {
        localError = nil
        authService.errorMessage = nil

        guard !fullName.trimmingCharacters(in: .whitespaces).isEmpty else {
            localError = "Please enter your full name."
            return
        }
        guard !email.isEmpty else {
            localError = "Please enter your email address."
            return
        }
        guard !password.isEmpty else {
            localError = "Please enter a password."
            return
        }
        guard password.count >= 6 else {
            localError = "Password must be at least 6 characters."
            return
        }
        guard password == confirmPassword else {
            localError = "Passwords do not match."
            return
        }

        Task {
            await authService.signUp(
                email: email,
                password: password,
                fullName: fullName.trimmingCharacters(in: .whitespaces)
            )
        }
    }
}

#Preview {
    NavigationStack {
        SignUpView()
            .environment(AuthService())
    }
}
