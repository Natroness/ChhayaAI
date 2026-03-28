import SwiftUI

enum AppButtonStyle {
    case primary
    case secondary
    case outline
    case destructive
}

struct AppButton: View {
    let title: String
    var icon: String?
    var style: AppButtonStyle = .primary
    var isFullWidth: Bool = true
    var isLoading: Bool = false
    let action: () -> Void

    @State private var isPressed = false

    private var backgroundColor: Color {
        switch style {
        case .primary:     return ComponentColor.Button.primaryBg
        case .secondary:   return ComponentColor.Button.secondaryBg
        case .outline:     return .clear
        case .destructive: return SemanticColor.statusError
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary:     return ComponentColor.Button.primaryText
        case .secondary:   return ComponentColor.Button.secondaryText
        case .outline:     return ComponentColor.Button.outlineText
        case .destructive: return BrandColor.white
        }
    }

    private var borderColor: Color? {
        switch style {
        case .outline: return ComponentColor.Button.outlineBorder
        default:       return nil
        }
    }

    var body: some View {
        Button(action: performAction) {
            HStack(spacing: Spacing.space2) {
                if isLoading {
                    ProgressView()
                        .tint(foregroundColor)
                } else {
                    if let icon {
                        Image(systemName: icon)
                            .font(.system(size: AppFont.Size.label, weight: .semibold))
                    }
                    Text(title)
                        .textStyle(.bodyMedium)
                }
            }
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .frame(minHeight: 44)
            .padding(.horizontal, Spacing.space5)
            .padding(.vertical, Spacing.space3)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            .overlay {
                if let borderColor {
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .stroke(borderColor, lineWidth: 1)
                }
            }
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .disabled(isLoading)
        .opacity(isLoading ? 0.8 : 1.0)
    }

    private func performAction() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        action()
    }
}

#Preview("Button Styles") {
    VStack(spacing: Spacing.space4) {
        AppButton(title: "Confirm & Dispatch", icon: "arrow.right", style: .primary) {}
        AppButton(title: "Emergency Contacts", icon: "phone.fill", style: .secondary) {}
        AppButton(title: "Edit Location Manually", icon: "pencil", style: .outline) {}
        AppButton(title: "Cancel Emergency", icon: "xmark", style: .destructive) {}
        AppButton(title: "Dispatching...", style: .primary, isLoading: true) {}
    }
    .padding(Spacing.screenPaddingH)
}
