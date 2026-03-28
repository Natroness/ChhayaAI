import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case dashboard
    case map
    case feed
    case chat

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: return "Home"
        case .map:       return "Map"
        case .feed:      return "Alerts"
        case .chat:      return "AI Agent"
        }
    }

    var icon: String {
        switch self {
        case .dashboard: return "house.fill"
        case .map:       return "map.fill"
        case .feed:      return "bell.badge.fill"
        case .chat:      return "bubble.left.and.bubble.right.fill"
        }
    }
}
