import SwiftUI

struct DashboardView: View {
    @State private var showingSOSConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.space6) {
                greetingSection
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
        .confirmationDialog(
            "Confirm SOS",
            isPresented: $showingSOSConfirmation,
            titleVisibility: .visible
        ) {
            Button("Dispatch Ambulance", role: .destructive) {
                let gen = UINotificationFeedbackGenerator()
                gen.notificationOccurred(.warning)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will dispatch the nearest available ambulance to your current GPS location.")
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
        switch hour {
        case 5..<12:  return "Good Morning"
        case 12..<17: return "Good Afternoon"
        default:      return "Good Evening"
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
                    Text("All services operational. 12 units available in your area.")
                        .textStyle(.caption)
                        .foregroundStyle(SemanticColor.textSecondary)
                }
            }
        }
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
            showingSOSConfirmation = true
        } label: {
            HStack(spacing: Spacing.space3) {
                ZStack {
                    Circle()
                        .fill(BrandColor.white.opacity(0.2))
                        .frame(width: 48, height: 48)
                    Image(systemName: "cross.circle.fill")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(BrandColor.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("SOS Emergency")
                        .textStyle(.headingMD)
                        .foregroundStyle(BrandColor.white)
                    Text("Tap to dispatch nearest ambulance")
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
                Text("View All")
                    .textStyle(.labelSemibold)
                    .foregroundStyle(SemanticColor.actionPrimary)
            }

            unitCard(
                id: "AMB-2847",
                type: "Advanced Life Support",
                distance: "2.3 km",
                badge: .enRoute
            )
            unitCard(
                id: "AMB-1192",
                type: "Basic Life Support",
                distance: "4.1 km",
                badge: .active
            )
        }
    }

    private func unitCard(id: String, type: String, distance: String, badge: BadgeVariant) -> some View {
        InfoCard {
            HStack(spacing: Spacing.space3) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppRadius.sm)
                        .fill(SemanticColor.actionPrimary.opacity(AppOpacity.overlaySubtle))
                        .frame(width: 48, height: 48)
                    Image(systemName: "cross.vial.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(SemanticColor.actionPrimary)
                }

                VStack(alignment: .leading, spacing: Spacing.space1) {
                    HStack {
                        Text(id)
                            .textStyle(.labelBold)
                            .foregroundStyle(SemanticColor.textPrimary)
                        Spacer()
                        StatusBadge(variant: badge)
                    }
                    Text(type)
                        .textStyle(.caption)
                        .foregroundStyle(SemanticColor.textSecondary)
                    Text(distance)
                        .textStyle(.captionMedium)
                        .foregroundStyle(SemanticColor.textAccent)
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
                Text("History")
                    .textStyle(.labelSemibold)
                    .foregroundStyle(SemanticColor.actionPrimary)
            }

            activityRow(
                icon: "checkmark.circle.fill",
                iconColor: SemanticColor.statusSuccess,
                title: "Emergency #EMR-2024-8847",
                subtitle: "Completed — 6 min response",
                time: "2h ago"
            )
            activityRow(
                icon: "exclamationmark.triangle.fill",
                iconColor: SemanticColor.statusWarning,
                title: "Alert: Heavy Traffic Zone",
                subtitle: "Route B closed for maintenance",
                time: "5h ago"
            )
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
            }

            Spacer()

            Text(time)
                .textStyle(.caption)
                .foregroundStyle(SemanticColor.textSecondary)
        }
        .padding(Spacing.space4)
        .background(ComponentColor.Card.bg)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
    }
}

#Preview {
    DashboardView()
}
