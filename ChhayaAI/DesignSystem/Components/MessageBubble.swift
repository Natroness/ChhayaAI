import SwiftUI

enum MessageSender {
    case user
    case agent
}

struct ChatMessage: Identifiable {
    let id: UUID
    let sender: MessageSender
    let text: String
    let timestamp: Date

    init(id: UUID = UUID(), sender: MessageSender, text: String, timestamp: Date = .now) {
        self.id = id
        self.sender = sender
        self.text = text
        self.timestamp = timestamp
    }
}

struct MessageBubble: View {
    let message: ChatMessage

    private var isUser: Bool { message.sender == .user }

    private var bubbleColor: Color {
        isUser ? SemanticColor.bgSecondary : SemanticColor.bgTinted
    }

    private var alignment: HorizontalAlignment {
        isUser ? .trailing : .leading
    }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 60) }

            VStack(alignment: isUser ? .trailing : .leading, spacing: Spacing.space1) {
                if !isUser {
                    HStack(spacing: Spacing.space1_5) {
                        Image(systemName: "cpu")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(SemanticColor.actionPrimary)
                        Text("ChhayaAI")
                            .textStyle(.captionSemibold)
                            .foregroundStyle(SemanticColor.textAccent)
                    }
                }

                Text(message.text)
                    .textStyle(.body)
                    .foregroundStyle(SemanticColor.textPrimary)
                    .padding(.horizontal, Spacing.space4)
                    .padding(.vertical, Spacing.space3)
                    .background(bubbleColor)
                    .clipShape(
                        RoundedRectangle(cornerRadius: AppRadius.md)
                    )

                Text(message.timestamp, format: .dateTime.hour().minute())
                    .textStyle(.caption)
                    .foregroundStyle(SemanticColor.textSecondary)
            }

            if !isUser { Spacer(minLength: 60) }
        }
    }
}

#Preview("Chat Bubbles") {
    VStack(spacing: Spacing.space4) {
        MessageBubble(message: ChatMessage(
            sender: .agent,
            text: "I've identified 3 ambulances within a 5km radius. The nearest one (AMB-2847) can reach you in approximately 7 minutes."
        ))
        MessageBubble(message: ChatMessage(
            sender: .user,
            text: "Dispatch the nearest one please"
        ))
        MessageBubble(message: ChatMessage(
            sender: .agent,
            text: "AMB-2847 has been dispatched. ETA: 7 minutes. I'll keep you updated on its location."
        ))
    }
    .padding(Spacing.screenPaddingH)
}
