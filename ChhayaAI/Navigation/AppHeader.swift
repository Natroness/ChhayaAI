import SwiftUI

struct AppHeader: View {
    let title: String
    var subtitle: String?
    var trailingContent: AnyView?

    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder trailing: () -> some View = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.trailingContent = AnyView(trailing())
    }

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .textStyle(.headingMD)
                    .foregroundStyle(SemanticColor.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .textStyle(.caption)
                        .foregroundStyle(SemanticColor.textSecondary)
                }
            }

            Spacer()

            trailingContent
        }
        .padding(.horizontal, Spacing.screenPaddingH)
        .padding(.vertical, Spacing.space3)
        .background(ComponentColor.Card.bg)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(SemanticColor.borderDefault)
                .frame(height: 0.5)
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        AppHeader(title: "Dashboard", subtitle: "ChhayaAI Emergency Response") {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 18))
                .foregroundStyle(SemanticColor.iconAccent)
        }
        Spacer()
    }
}
