import Foundation

/// Reads `AGENT_API_BASE_URL` from the app Info.plist (set via Xcode build settings). Falls back to local dev.
enum AgentAPIConfiguration {
    private static let fallback = "http://127.0.0.1:8000"

    static var baseURL: URL {
        guard
            let raw = Bundle.main.object(forInfoDictionaryKey: "AGENT_API_BASE_URL") as? String,
            !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            let url = URL(string: raw.trimmingCharacters(in: .whitespacesAndNewlines))
        else {
            return URL(string: fallback)!
        }
        return url
    }
}
