import SwiftUI

struct FriendsHubView: View {
    @Environment(FriendService.self) private var friendService

    @State private var searchEmail = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.space4) {
                    searchCard
                    if let message = friendService.errorMessage, !message.isEmpty {
                        statusCard(message, severity: .critical)
                    } else if let message = friendService.successMessage, !message.isEmpty {
                        statusCard(message, severity: .info)
                    }
                    if let result = friendService.searchResult {
                        searchResultCard(result)
                    }
                    acceptedFriendsCard
                    incomingRequestsCard
                    outgoingRequestsCard
                }
                .padding(Spacing.screenPaddingH)
            }
            .background(ComponentColor.Screen.bg)
            .navigationTitle("Close Friends")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var searchCard: some View {
        InfoCard {
            VStack(alignment: .leading, spacing: Spacing.space3) {
                Text("Add by email")
                    .textStyle(.labelBold)
                    .foregroundStyle(SemanticColor.textPrimary)

                AppTextField(
                    placeholder: "friend@example.com",
                    text: $searchEmail,
                    icon: "envelope.fill",
                    trailingIcon: friendService.isSearching ? nil : "magnifyingglass",
                    onTrailingAction: runSearch,
                    onSubmit: runSearch
                )

                AppButton(
                    title: friendService.isSearching ? "Searching..." : "Find user",
                    icon: "magnifyingglass",
                    style: .secondary,
                    isLoading: friendService.isSearching
                ) {
                    runSearch()
                }
            }
        }
    }

    private func statusCard(_ message: String, severity: CardSeverity) -> some View {
        InfoCard(severity: severity) {
            Text(message)
                .textStyle(.caption)
                .foregroundStyle(SemanticColor.textPrimary)
        }
    }

    private func searchResultCard(_ profile: FirestoreUserProfile) -> some View {
        InfoCard {
            VStack(alignment: .leading, spacing: Spacing.space3) {
                Text("Search result")
                    .textStyle(.captionSemibold)
                    .foregroundStyle(SemanticColor.textSecondary)

                Text(profile.displayName)
                    .textStyle(.labelBold)
                    .foregroundStyle(SemanticColor.textPrimary)

                if let email = profile.email, !email.isEmpty {
                    Text(email)
                        .textStyle(.caption)
                        .foregroundStyle(SemanticColor.textSecondary)
                }

                AppButton(
                    title: friendService.isSendingRequest ? "Sending..." : "Send close-friend request",
                    icon: "person.badge.plus",
                    style: .primary,
                    isLoading: friendService.isSendingRequest
                ) {
                    Task {
                        await friendService.sendRequest(to: profile)
                    }
                }
            }
        }
    }

    private var acceptedFriendsCard: some View {
        InfoCard {
            VStack(alignment: .leading, spacing: Spacing.space3) {
                Text("Accepted friends")
                    .textStyle(.labelBold)
                    .foregroundStyle(SemanticColor.textPrimary)

                if friendService.acceptedFriends.isEmpty {
                    emptyState("No close friends yet.")
                } else {
                    ForEach(friendService.acceptedFriends) { friend in
                        friendRow(name: friend.displayName, subtitle: friend.email ?? "Location and SOS enabled")
                    }
                }
            }
        }
    }

    private var incomingRequestsCard: some View {
        InfoCard {
            VStack(alignment: .leading, spacing: Spacing.space3) {
                Text("Incoming requests")
                    .textStyle(.labelBold)
                    .foregroundStyle(SemanticColor.textPrimary)

                let pending = friendService.incomingRequests.filter { $0.status == .pending }
                if pending.isEmpty {
                    emptyState("No incoming requests.")
                } else {
                    ForEach(pending) { request in
                        VStack(alignment: .leading, spacing: Spacing.space2) {
                            friendRow(name: request.fromDisplayName, subtitle: request.fromEmail ?? "Pending")
                            HStack(spacing: Spacing.space3) {
                                AppButton(
                                    title: "Accept",
                                    icon: "checkmark",
                                    style: .primary,
                                    isFullWidth: true,
                                    isLoading: friendService.isUpdatingRequest
                                ) {
                                    Task {
                                        await friendService.accept(request)
                                    }
                                }
                                AppButton(
                                    title: "Decline",
                                    icon: "xmark",
                                    style: .outline,
                                    isFullWidth: true
                                ) {
                                    Task {
                                        await friendService.decline(request)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var outgoingRequestsCard: some View {
        InfoCard {
            VStack(alignment: .leading, spacing: Spacing.space3) {
                Text("Outgoing requests")
                    .textStyle(.labelBold)
                    .foregroundStyle(SemanticColor.textPrimary)

                if friendService.outgoingRequests.isEmpty {
                    emptyState("No outgoing requests.")
                } else {
                    ForEach(friendService.outgoingRequests) { request in
                        VStack(alignment: .leading, spacing: Spacing.space2) {
                            friendRow(
                                name: request.toDisplayName ?? request.toEmail ?? "Pending request",
                                subtitle: request.status.label
                            )
                            if request.status == .pending {
                                AppButton(
                                    title: "Cancel request",
                                    icon: "xmark.circle",
                                    style: .outline
                                ) {
                                    Task {
                                        await friendService.cancel(request)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func emptyState(_ text: String) -> some View {
        Text(text)
            .textStyle(.caption)
            .foregroundStyle(SemanticColor.textSecondary)
    }

    private func friendRow(name: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.space1) {
            Text(name)
                .textStyle(.labelSemibold)
                .foregroundStyle(SemanticColor.textPrimary)
            Text(subtitle)
                .textStyle(.caption)
                .foregroundStyle(SemanticColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, Spacing.space1)
    }

    private func runSearch() {
        Task {
            await friendService.searchUser(byEmail: searchEmail)
        }
    }
}

#Preview {
    FriendsHubView()
        .environment(FriendService.shared)
}
