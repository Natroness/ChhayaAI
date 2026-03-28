import SwiftUI

private struct SelectedTabKey: EnvironmentKey {
    static let defaultValue: Binding<AppTab>? = nil
}

extension EnvironmentValues {
    /// Set from `ContentView` so child views can honor `ui_actions` tab switches.
    var selectedTabBinding: Binding<AppTab>? {
        get { self[SelectedTabKey.self] }
        set { self[SelectedTabKey.self] = newValue }
    }
}

/// Maps backend `ui_actions` strings to tab navigation (minimal; extend as new actions appear).
enum UIActionRouting {
    static func apply(_ actions: [String], selectedTab: Binding<AppTab>) {
        let set = Set(actions)
        if set.contains("OPEN_MAP_SCREEN") { selectedTab.wrappedValue = .map }
        if set.contains("OPEN_ALERT_SCREEN") { selectedTab.wrappedValue = .feed }
        if set.contains("SHOW_CHAT_MESSAGE") { selectedTab.wrappedValue = .chat }
    }
}
