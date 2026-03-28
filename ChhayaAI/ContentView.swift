import SwiftUI

struct ContentView: View {
    @State private var selectedTab: AppTab = .dashboard

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(AppTab.allCases) { tab in
                tabContent(for: tab)
                    .tabItem {
                        Label(tab.title, systemImage: tab.icon)
                    }
                    .tag(tab)
            }
        }
        .tint(ComponentColor.Nav.activeTint)
    }

    @ViewBuilder
    private func tabContent(for tab: AppTab) -> some View {
        switch tab {
        case .dashboard:
            NavigationStack {
                DashboardView()
                    .navigationTitle("ChhayaAI")
                    .navigationBarTitleDisplayMode(.large)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            HStack(spacing: Spacing.space3) {
                                notificationBell
                                profileAvatar
                            }
                        }
                    }
            }

        case .map:
            NavigationStack {
                MapTabView()
                    .navigationTitle("Live Map")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            }

        case .feed:
            NavigationStack {
                AlertFeedView()
                    .navigationTitle("Alerts")
                    .navigationBarTitleDisplayMode(.large)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Menu {
                                Button("Mark All Read", systemImage: "checkmark.circle") {}
                                Button("Settings", systemImage: "gearshape") {}
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .foregroundStyle(SemanticColor.iconSecondary)
                            }
                        }
                    }
            }

        case .chat:
            NavigationStack {
                ChatView()
                    .navigationBarHidden(true)
            }
        }
    }

    // MARK: - Toolbar Items

    private var notificationBell: some View {
        Button {} label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(SemanticColor.iconSecondary)
                Circle()
                    .fill(SemanticColor.statusError)
                    .frame(width: 8, height: 8)
                    .offset(x: 2, y: -2)
            }
        }
    }

    private var profileAvatar: some View {
        ZStack {
            Circle()
                .fill(SemanticColor.actionPrimary.opacity(0.15))
                .frame(width: 32, height: 32)
            Text("A")
                .textStyle(.captionSemibold)
                .foregroundStyle(SemanticColor.actionPrimary)
        }
    }
}

#Preview {
    ContentView()
}
