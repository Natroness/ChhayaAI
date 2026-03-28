import SwiftUI

struct ChatView: View {
    @State private var inputText = ""
    @State private var messages: [ChatMessage] = ChatView.sampleMessages

    var body: some View {
        VStack(spacing: 0) {
            chatHeader
            messageList
            inputBar
        }
        .background(ComponentColor.Screen.bg)
    }

    // MARK: - Header

    private var chatHeader: some View {
        HStack(spacing: Spacing.space3) {
            ZStack {
                Circle()
                    .fill(SemanticColor.bgTinted)
                    .frame(width: 40, height: 40)
                Image(systemName: "cpu")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(SemanticColor.actionPrimary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("ChhayaAI Assistant")
                    .textStyle(.labelBold)
                    .foregroundStyle(SemanticColor.textPrimary)
                HStack(spacing: Spacing.space1) {
                    Circle()
                        .fill(SemanticColor.statusSuccess)
                        .frame(width: 6, height: 6)
                    Text("Online")
                        .textStyle(.caption)
                        .foregroundStyle(SemanticColor.statusSuccess)
                }
            }

            Spacer()

            Menu {
                Button("Clear Chat", systemImage: "trash") {}
                Button("Agent Settings", systemImage: "gearshape") {}
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(SemanticColor.iconSecondary)
                    .frame(width: 36, height: 36)
            }
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

    // MARK: - Messages

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: Spacing.space4) {
                    agentCapabilities
                    ForEach(messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }
                }
                .padding(.horizontal, Spacing.screenPaddingH)
                .padding(.vertical, Spacing.space4)
            }
            .onChange(of: messages.count) {
                if let last = messages.last {
                    withAnimation {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var agentCapabilities: some View {
        VStack(spacing: Spacing.space3) {
            Image(systemName: "sparkles")
                .font(.system(size: 28))
                .foregroundStyle(SemanticColor.actionPrimary)

            Text("How can I help?")
                .textStyle(.headingMD)
                .foregroundStyle(SemanticColor.textPrimary)

            Text("I can dispatch ambulances, find the nearest hospital, track active emergencies, or provide first-aid guidance.")
                .textStyle(.body)
                .foregroundStyle(SemanticColor.textSecondary)
                .multilineTextAlignment(.center)

            HStack(spacing: Spacing.space2) {
                suggestionChip("Find nearest hospital")
                suggestionChip("Active emergencies")
            }
            HStack(spacing: Spacing.space2) {
                suggestionChip("First-aid guidance")
                suggestionChip("Route status")
            }
        }
        .padding(.vertical, Spacing.space6)
    }

    private func suggestionChip(_ text: String) -> some View {
        Button {
            inputText = text
            sendMessage()
        } label: {
            Text(text)
                .textStyle(.captionMedium)
                .foregroundStyle(SemanticColor.actionPrimary)
                .padding(.horizontal, Spacing.space3)
                .padding(.vertical, Spacing.space2)
                .background(SemanticColor.actionPrimary.opacity(0.08))
                .clipShape(Capsule())
                .overlay {
                    Capsule()
                        .stroke(SemanticColor.actionPrimary.opacity(0.2), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Input

    private var inputBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(SemanticColor.borderDefault)
                .frame(height: 0.5)

            HStack(spacing: Spacing.space3) {
                AppTextField(
                    placeholder: "Type a message...",
                    text: $inputText,
                    trailingIcon: inputText.isEmpty ? nil : "arrow.up",
                    isPill: true,
                    onTrailingAction: sendMessage,
                    onSubmit: sendMessage
                )
            }
            .padding(.horizontal, Spacing.screenPaddingH)
            .padding(.vertical, Spacing.space3)
            .background(ComponentColor.Card.bg)
        }
    }

    // MARK: - Actions

    private func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let userMsg = ChatMessage(sender: .user, text: inputText)
        messages.append(userMsg)
        inputText = ""

        let gen = UIImpactFeedbackGenerator(style: .light)
        gen.impactOccurred()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            let agentMsg = ChatMessage(
                sender: .agent,
                text: "I'm processing your request. Let me check the latest data from our Spanner Graph network."
            )
            messages.append(agentMsg)
        }
    }

    // MARK: - Sample Data

    static let sampleMessages: [ChatMessage] = [
        ChatMessage(sender: .agent, text: "Welcome to ChhayaAI. I'm your emergency response assistant. How can I help you today?"),
        ChatMessage(sender: .user, text: "What ambulances are near me?"),
        ChatMessage(sender: .agent, text: "I've found 3 ambulances within 5km:\n\n• AMB-2847 (ALS) — 2.3 km, En Route\n• AMB-1192 (BLS) — 4.1 km, Available\n• AMB-3301 (ALS) — 4.8 km, Available\n\nWould you like me to dispatch one?"),
    ]
}

#Preview {
    ChatView()
}
