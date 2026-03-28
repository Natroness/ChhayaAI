import SwiftUI

enum CardSeverity {
    case normal
    case info
    case warning
    case critical

    var borderColor: Color {
        switch self {
        case .normal:   return ComponentColor.Card.border
        case .info:     return SemanticColor.actionPrimary
        case .warning:  return SemanticColor.statusWarning
        case .critical: return SemanticColor.statusError
        }
    }

    var accentColor: Color {
        switch self {
        case .normal:   return SemanticColor.textSecondary
        case .info:     return SemanticColor.actionPrimary
        case .warning:  return SemanticColor.statusWarning
        case .critical: return SemanticColor.statusError
        }
    }
}

struct InfoCard<Content: View>: View {
    var severity: CardSeverity = .normal
    var showDivider: Bool = false
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: showDivider ? 0 : Spacing.space3) {
            content()
        }
        .padding(Spacing.space4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ComponentColor.Card.bg)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.sm)
                .stroke(severity.borderColor, lineWidth: 1)
        }
        .appShadow(.card)
    }
}

struct CardDivider: View {
    var body: some View {
        Rectangle()
            .fill(ComponentColor.Card.divider)
            .frame(height: 1)
            .padding(.vertical, Spacing.space3)
    }
}

struct CardRow: View {
    let label: String
    let value: String
    var valueColor: Color = SemanticColor.textPrimary

    var body: some View {
        HStack {
            Text(label)
                .textStyle(.caption)
                .foregroundStyle(SemanticColor.textSecondary)
            Spacer()
            Text(value)
                .textStyle(.bodyMedium)
                .foregroundStyle(valueColor)
        }
    }
}

#Preview("Card Variants") {
    ScrollView {
        VStack(spacing: Spacing.space4) {
            InfoCard {
                HStack(spacing: Spacing.space3) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(SemanticColor.iconAccent)
                    VStack(alignment: .leading, spacing: Spacing.space1) {
                        Text("Detected Address")
                            .textStyle(.caption)
                            .foregroundStyle(SemanticColor.textSecondary)
                        Text("42 Maple Street, Block C")
                            .textStyle(.bodyMedium)
                            .foregroundStyle(SemanticColor.textPrimary)
                    }
                }
            }

            InfoCard(severity: .warning) {
                HStack(spacing: Spacing.space3) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(SemanticColor.statusWarning)
                    Text("Heavy traffic detected on route")
                        .textStyle(.body)
                        .foregroundStyle(SemanticColor.textPrimary)
                }
            }

            InfoCard(severity: .critical) {
                HStack(spacing: Spacing.space3) {
                    Image(systemName: "bolt.heart.fill")
                        .foregroundStyle(SemanticColor.statusError)
                    VStack(alignment: .leading, spacing: Spacing.space1) {
                        Text("Critical Alert")
                            .textStyle(.labelBold)
                            .foregroundStyle(SemanticColor.statusError)
                        Text("Patient vitals require immediate attention")
                            .textStyle(.body)
                            .foregroundStyle(SemanticColor.textPrimary)
                    }
                }
            }

            InfoCard(showDivider: true) {
                CardRow(label: "Vehicle ID", value: "AMB-2847")
                CardDivider()
                CardRow(label: "Type", value: "Advanced Life Support")
                CardDivider()
                CardRow(label: "Distance", value: "2.3 km away")
            }
        }
        .padding(Spacing.screenPaddingH)
    }
    .background(ComponentColor.Screen.bg)
}
