import Foundation

/// Stable per-install session id for backend `session_id` (chat history key).
enum SessionIdentity {
    private static let key = "chhaya.agent.session_id"

    static var sessionId: String {
        if let existing = UserDefaults.standard.string(forKey: key), !existing.isEmpty {
            return existing
        }
        let id = UUID().uuidString
        UserDefaults.standard.set(id, forKey: key)
        return id
    }
}
