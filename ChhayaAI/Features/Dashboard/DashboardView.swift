import FirebaseAuth
import SwiftUI

struct DashboardView: View {
    @Environment(AuthService.self) private var authService
    @Environment(AgentAPIClient.self) private var agentAPI
    @Environment(AgentSessionStore.self) private var sessionStore
    @Environment(LocationManager.self) private var locationManager

    @Binding var selectedTab: AppTab

    @State private var showingSOSConfirmation = false
    @State private var sosBusy = false
    @State private var sosFeedback: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.space6) {
                greetingSection
                if let sosFeedback {
                    Text(sosFeedback)
                        .textStyle(.caption)
                        .foregroundStyle(SemanticColor.statusError)
                        .padding(Spacing.space3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(SemanticColor.statusError.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                }
                activeAlertBanner
                quickActions
                nearbyUnitsSection
                recentActivitySection
            }
            .padding(.horizontal, Spacing.screenPaddingH)
            .padding(.top, Spacing.space4)
            .padding(.bottom, Spacing.space12)
        }
        .background(ComponentColor.Screen.bg)
        .onAppear {
            locationManager.requestWhenInUse()
        }
        .confirmationDialog(
            "Confirm SOS",
            isPresented: $showingSOSConfirmation,
            titleVisibility: .visible
        ) {
            Button("Send emergency request", role: .destructive) {
                Task { await runEmergencyFlow() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This notifies the assistant using your current location. Use only for real emergencies.")
        }
    }

    // MARK: - Greeting

    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: Spacing.space1) {
            Text(greetingText)
                .textStyle(.headingLG)
                .foregroundStyle(SemanticColor.textPrimary)
            Text("ChhayaAI Emergency Response")
                .textStyle(.body)
                .foregroundStyle(SemanticColor.textSecondary)
        }
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = authService.displayName
        switch hour {
        case 5..<12:  return "Good Morning, \(name)"
        case 12..<17: return "Good Afternoon, \(name)"
        default:      return "Good Evening, \(name)"
        }
    }

    // MARK: - Active Alert

    private var activeAlertBanner: some View {
        InfoCard(severity: .info) {
            HStack(spacing: Spacing.space3) {
                ZStack {
                    Circle()
                        .fill(SemanticColor.statusSuccess.opacity(AppOpacity.overlaySubtle))
                        .frame(width: 48, height: 48)
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(SemanticColor.statusSuccess)
                }

                VStack(alignment: .leading, spacing: Spacing.space1) {
                    HStack {
                        Text("System Status")
                            .textStyle(.labelSemibold)
                            .foregroundStyle(SemanticColor.textPrimary)
                        Spacer()
                        StatusBadge(variant: .active)
                    }
                    Text(statusBlurb)
                        .textStyle(.caption)
                        .foregroundStyle(SemanticColor.textSecondary)
                }
            }
        }
    }

    private var statusBlurb: String {
        if let r = sessionStore.lastResponse,
           r.responseType == "EMERGENCY_FLOW",
           let m = r.chatMessage?.trimmingCharacters(in: .whitespacesAndNewlines),
           !m.isEmpty
        {
            return m
        }
        return "All services operational. Use SOS only for real emergencies."
    }

    // MARK: - Quick Actions

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: Spacing.space3) {
            Text("Quick Actions")
                .textStyle(.headingMD)
                .foregroundStyle(SemanticColor.textPrimary)

            sosButton

            HStack(spacing: Spacing.space3) {
                quickActionTile(
                    icon: "phone.fill",
                    title: "Emergency\nContacts",
                    color: SemanticColor.actionPrimary
                )
                quickActionTile(
                    icon: "map.fill",
                    title: "Live\nMap",
                    color: SemanticColor.statusWarning
                )
                quickActionTile(
                    icon: "bubble.left.fill",
                    title: "AI\nAssistant",
                    color: SemanticColor.textAccent
                )
            }
        }
    }

    private var sosButton: some View {
        Button {
            let gen = UIImpactFeedbackGenerator(style: .heavy)
            gen.impactOccurred()
            sosFeedback = nil
            showingSOSConfirmation = true
        } label: {
            HStack(spacing: Spacing.space3) {
                ZStack {
                    Circle()
                        .fill(BrandColor.white.opacity(0.2))
                        .frame(width: 48, height: 48)
                    if sosBusy {
                        ProgressView()
                            .tint(BrandColor.white)
                    } else {
                        Image(systemName: "cross.circle.fill")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(BrandColor.white)
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("SOS Emergency")
                        .textStyle(.headingMD)
                        .foregroundStyle(BrandColor.white)
                    Text("Tap to contact the assistant with your location")
                        .textStyle(.caption)
                        .foregroundStyle(BrandColor.white.opacity(0.8))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(BrandColor.white.opacity(0.6))
            }
            .padding(Spacing.space4)
            .background(
                LinearGradient(
                    colors: [SemanticColor.statusError, SemanticColor.statusError.opacity(0.85)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        }
        .buttonStyle(.plain)
        .disabled(sosBusy)
    }

    private func quickActionTile(icon: String, title: String, color: Color) -> some View {
        VStack(spacing: Spacing.space3) {
            ZStack {
                Circle()
                    .fill(color.opacity(AppOpacity.overlaySubtle))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(color)
            }
            Text(title)
                .textStyle(.captionMedium)
                .foregroundStyle(SemanticColor.textPrimary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.space4)
        .background(ComponentColor.Card.bg)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
        .appShadow(.card)
    }

    // MARK: - Nearby Units

    private var nearbyUnitsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.space3) {
            HStack {
                Text("Nearby Units")
                    .textStyle(.headingMD)
                    .foregroundStyle(SemanticColor.textPrimary)
                Spacer()
                Button("Open map") {
                    selectedTab = .map
                }
                .textStyle(.labelSemibold)
                .foregroundStyle(SemanticColor.actionPrimary)
            }

            InfoCard {
                VStack(alignment: .leading, spacing: Spacing.space2) {
                    Text("Live matches come from the map agent when location is enabled.")
                        .textStyle(.body)
                        .foregroundStyle(SemanticColor.textSecondary)
                    Button("Go to map tab") {
                        selectedTab = .map
                    }
                    .textStyle(.labelSemibold)
                    .foregroundStyle(SemanticColor.actionPrimary)
                }
            }
        }
    }

    // MARK: - Recent Activity

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: Spacing.space3) {
            HStack {
                Text("Recent Activity")
                    .textStyle(.headingMD)
                    .foregroundStyle(SemanticColor.textPrimary)
                Spacer()
                Button("Chat") {
                    selectedTab = .chat
                }
                .textStyle(.labelSemibold)
                .foregroundStyle(SemanticColor.actionPrimary)
            }

            if let last = sessionStore.lastResponse?.chatMessage?.trimmingCharacters(in: .whitespacesAndNewlines),
               !last.isEmpty
            {
                activityRow(
                    icon: "bubble.left.and.bubble.right.fill",
                    iconColor: SemanticColor.actionPrimary,
                    title: "Last assistant reply",
                    subtitle: last,
                    time: "Just now"
                )
            } else {
                activityRow(
                    icon: "clock.fill",
                    iconColor: SemanticColor.textSecondary,
                    title: "No recent activity",
                    subtitle: "Open AI Agent to start a conversation.",
                    time: ""
                )
            }
        }
    }

    private func activityRow(icon: String, iconColor: Color, title: String, subtitle: String, time: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.space3) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(iconColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: Spacing.space1) {
                Text(title)
                    .textStyle(.labelSemibold)
                    .foregroundStyle(SemanticColor.textPrimary)
                Text(subtitle)
                    .textStyle(.caption)
                    .foregroundStyle(SemanticColor.textSecondary)
                    .lineLimit(4)
            }

            Spacer()

            if !time.isEmpty {
                Text(time)
                    .textStyle(.caption)
                    .foregroundStyle(SemanticColor.textSecondary)
            }
        }
        .padding(Spacing.space4)
        .background(ComponentColor.Card.bg)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
    }

    // MARK: - Emergency API

    private func runEmergencyFlow() async {
        await MainActor.run {
            sosBusy = true
            sosFeedback = nil
        }
        let token: String? = await withCheckedContinuation { cont in
            Auth.auth().currentUser?.getIDTokenForcingRefresh(false) { token, _ in
                cont.resume(returning: token)
            } ?? cont.resume(returning: nil)
        }

        let pair = locationManager.latLonPair
        guard let pair else {
            await MainActor.run {
                sosBusy = false
                sosFeedback = "Location required. Enable location services and try again."
            }
            return
        }

        do {
            let res = try await agentAPI.sendChat(
                userId: authService.backendUserId,
                sessionId: SessionIdentity.sessionId,
                query: "Emergency button pressed",
                lat: pair.lat,
                lon: pair.lon,
                triggerType: "EMERGENCY_BUTTON",
                idToken: token
            )
            await MainActor.run {
                sessionStore.lastResponse = res
                sessionStore.lastErrorMessage = nil
                sosBusy = false
                UIActionRouting.apply(res.uiActions, selectedTab: $selectedTab)
            }
        } catch {
            await MainActor.run {
                sessionStore.lastErrorMessage = error.localizedDescription
                sosBusy = false
                sosFeedback = error.localizedDescription
            }
        }
    }
}

#Preview {
    DashboardView(selectedTab: .constant(.dashboard))
        .environment(AuthService())
        .environment(AgentAPIClient())
        .environment(AgentSessionStore())
        .environment(LocationManager())
}
