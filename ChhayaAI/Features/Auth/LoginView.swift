import SwiftUI

struct LoginView: View {
    @Environment(AuthService.self) private var authService
    @State private var email = ""
    @State private var password = ""
    @State private var showSignUp = false
    @State private var showResetAlert = false
    @State private var showResetConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.space6) {
                    brandHeader

                    VStack(spacing: Spacing.space4) {
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
                        .textContentType(.password)

                        HStack {
                            Spacer()
                            Button("Forgot password?") {
                                handleForgotPassword()
                            }
                            .textStyle(.labelSemibold)
                            .foregroundStyle(SemanticColor.actionPrimary)
                        }

                        if let error = authService.errorMessage {
                            errorBanner(error)
                        }

                        AppButton(
                            title: "Sign In",
                            icon: "arrow.right",
                            style: .primary,
                            isLoading: authService.isLoading
                        ) {
                            signIn()
                        }

                        dividerOr

                        AppButton(
                            title: "Create Account",
                            icon: "person.badge.plus",
                            style: .outline
                        ) {
                            showSignUp = true
                        }
                    }
                    .padding(.horizontal, Spacing.screenPaddingH)
                }
                .padding(.bottom, Spacing.space12)
            }
            .background(ComponentColor.Screen.bg)
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView()
            }
            .alert("Reset Password", isPresented: $showResetAlert) {
                Button("OK") {}
            } message: {
                Text("Enter your email address above, then tap \"Forgot password?\" again.")
            }
            .alert("Email Sent", isPresented: $showResetConfirmation) {
                Button("OK") {}
            } message: {
                Text("A password reset link has been sent to \(email).")
            }
            .onChange(of: showSignUp) {
                authService.errorMessage = nil
            }
        }
    }

    // MARK: - Brand Header

    private var brandHeader: some View {
        VStack(spacing: Spacing.space4) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                SemanticColor.actionPrimary,
                                SemanticColor.actionPrimary.opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: "cross.circle.fill")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(BrandColor.white)
            }
            .padding(.top, Spacing.space12)

            VStack(spacing: Spacing.space1) {
                Text("ChhayaAI")
                    .textStyle(.headingXL)
                    .foregroundStyle(SemanticColor.textPrimary)

                Text("Emergency Response System")
                    .textStyle(.body)
                    .foregroundStyle(SemanticColor.textSecondary)
            }

            VStack(spacing: Spacing.space1) {
                Text("Welcome back")
                    .textStyle(.headingMD)
                    .foregroundStyle(SemanticColor.textPrimary)
                Text("Sign in to continue")
                    .textStyle(.caption)
                    .foregroundStyle(SemanticColor.textSecondary)
            }
            .padding(.top, Spacing.space4)
        }
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

    private var dividerOr: some View {
        HStack(spacing: Spacing.space3) {
            Rectangle()
                .fill(SemanticColor.borderDefault)
                .frame(height: 1)
            Text("or")
                .textStyle(.caption)
                .foregroundStyle(SemanticColor.textSecondary)
            Rectangle()
                .fill(SemanticColor.borderDefault)
                .frame(height: 1)
        }
    }

    // MARK: - Actions

    private func signIn() {
        guard !email.isEmpty, !password.isEmpty else {
            authService.errorMessage = "Please enter your email and password."
            return
        }
        Task {
            await authService.signIn(email: email, password: password)
        }
    }

    private func handleForgotPassword() {
        guard !email.isEmpty else {
            showResetAlert = true
            return
        }
        Task {
            await authService.resetPassword(email: email)
            if authService.errorMessage == nil {
                showResetConfirmation = true
            }
        }
    }
}

#Preview {
    LoginView()
        .environment(AuthService())
}
