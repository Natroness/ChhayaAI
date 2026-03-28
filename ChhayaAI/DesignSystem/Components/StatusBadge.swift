import SwiftUI

enum BadgeVariant {
    case active
    case approaching
    case enRoute
    case resolved
    case critical
    case verified
    case custom(text: String, bg: Color, fg: Color)

    var text: String {
        switch self {
        case .active:      return "Active"
        case .approaching: return "Approaching"
        case .enRoute:     return "En Route"
        case .resolved:    return "Resolved"
        case .critical:    return "Critical"
        case .verified:    return "Verified"
        case .custom(let text, _, _): return text
        }
    }

    var backgroundColor: Color {
        switch self {
        case .active, .enRoute:           return ComponentColor.StatusBadge.successBg
        case .approaching:                return ComponentColor.StatusBadge.warningBg
        case .resolved, .verified:        return ComponentColor.StatusBadge.successBg
        case .critical:                   return ComponentColor.StatusBadge.errorBg
        case .custom(_, let bg, _):       return bg
        }
    }

    var foregroundColor: Color {
        switch self {
        case .active, .enRoute:           return ComponentColor.StatusBadge.successText
        case .approaching:                return ComponentColor.StatusBadge.warningText
        case .resolved, .verified:        return ComponentColor.StatusBadge.successText
        case .critical:                   return ComponentColor.StatusBadge.errorText
        case .custom(_, _, let fg):       return fg
        }
    }

    var dotColor: Color? {
        switch self {
        case .active, .enRoute: return SemanticColor.statusSuccess
        case .approaching:      return SemanticColor.statusWarning
        case .critical:         return SemanticColor.statusError
        default:                return nil
        }
    }

    var icon: String? {
        switch self {
        case .resolved:  return "checkmark"
        case .verified:  return "checkmark.shield.fill"
        default:         return nil
        }
    }
}

struct StatusBadge: View {
    let variant: BadgeVariant

    var body: some View {
        HStack(spacing: Spacing.space1_5) {
            if let dotColor = variant.dotColor {
                Circle()
                    .fill(dotColor)
                    .frame(width: 8, height: 8)
            }

            if let icon = variant.icon {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
            }

            Text(variant.text)
                .textStyle(.captionMedium)
        }
        .foregroundStyle(variant.foregroundColor)
        .padding(.horizontal, Spacing.space3)
        .padding(.vertical, Spacing.space1_5)
        .background(variant.backgroundColor)
        .clipShape(Capsule())
    }
}

#Preview("Badge Variants") {
    VStack(spacing: Spacing.space3) {
        StatusBadge(variant: .active)
        StatusBadge(variant: .enRoute)
        StatusBadge(variant: .approaching)
        StatusBadge(variant: .critical)
        StatusBadge(variant: .resolved)
        StatusBadge(variant: .verified)
        StatusBadge(variant: .custom(
            text: "Dispatched",
            bg: SemanticColor.actionPrimary.opacity(0.1),
            fg: SemanticColor.actionPrimary
        ))
    }
    .padding()
}
