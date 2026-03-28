import Foundation

/// Last agent envelope for cross-tab UI (alerts strip, map banner) without duplicating transport logic.
@Observable
final class AgentSessionStore {
    var lastResponse: CommonResponseDTO?
    var lastErrorMessage: String?
}
