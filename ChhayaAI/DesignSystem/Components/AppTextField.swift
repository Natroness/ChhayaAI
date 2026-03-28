import SwiftUI

struct AppTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String?
    var trailingIcon: String?
    var isPill: Bool = false
    var onTrailingAction: (() -> Void)?
    var onSubmit: (() -> Void)?

    @FocusState private var isFocused: Bool

    private var cornerRadius: CGFloat {
        isPill ? AppRadius.xl : AppRadius.sm
    }

    var body: some View {
        HStack(spacing: Spacing.space3) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: AppFont.Size.label))
                    .foregroundStyle(
                        isFocused
                            ? SemanticColor.iconAccent
                            : SemanticColor.iconSecondary
                    )
            }

            TextField(placeholder, text: $text)
                .textStyle(.body)
                .foregroundStyle(SemanticColor.textPrimary)
                .focused($isFocused)
                .onSubmit { onSubmit?() }

            if let trailingIcon {
                Button {
                    onTrailingAction?()
                } label: {
                    Image(systemName: trailingIcon)
                        .font(.system(size: AppFont.Size.label, weight: .semibold))
                        .foregroundStyle(SemanticColor.actionPrimary)
                        .frame(width: 36, height: 36)
                        .background(SemanticColor.actionPrimary.opacity(0.1))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, Spacing.space4)
        .padding(.vertical, Spacing.space3)
        .background(ComponentColor.Card.bg)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(
                    isFocused
                        ? SemanticColor.actionPrimary
                        : SemanticColor.borderDefault,
                    lineWidth: isFocused ? 1.5 : 1
                )
        }
        .animation(.easeInOut(duration: 0.15), value: isFocused)
    }
}

#Preview("Text Fields") {
    @Previewable @State var text1 = ""
    @Previewable @State var text2 = "42 Maple Street"
    @Previewable @State var text3 = ""

    VStack(spacing: Spacing.space4) {
        AppTextField(placeholder: "Search location...", text: $text1, icon: "magnifyingglass")
        AppTextField(placeholder: "Enter address", text: $text2, icon: "mappin")
        AppTextField(
            placeholder: "Type a message...",
            text: $text3,
            icon: "bubble.left",
            trailingIcon: "arrow.up",
            isPill: true,
            onTrailingAction: {}
        )
    }
    .padding(Spacing.screenPaddingH)
}
