import Foundation

/// Reads and validates `AGENT_API_BASE_URL` from the app Info.plist.
enum AgentAPIConfiguration {
    private static let configKey = "AGENT_API_BASE_URL"

    static func validatedBaseURL() throws -> URL {
        guard let raw = resolvedValue() else {
            throw AgentAPIError.invalidBaseURL(
                "Missing \(configKey). Check Info.plist build settings and Secrets.xcconfig."
            )
        }

        if raw.contains("$(") || raw.contains("${") {
            throw AgentAPIError.invalidBaseURL(
                "\(configKey) was not resolved at build time. Clean the build folder and rebuild the app."
            )
        }

        guard let components = URLComponents(string: raw) else {
            throw AgentAPIError.invalidBaseURL(
                "\(configKey) is not a valid URL."
            )
        }

        guard let scheme = components.scheme?.lowercased(), scheme == "https" || scheme == "http" else {
            throw AgentAPIError.invalidBaseURL(
                "\(configKey) must use http or https."
            )
        }

        guard let host = components.host, !host.isEmpty else {
            throw AgentAPIError.invalidBaseURL(
                "\(configKey) is missing a hostname."
            )
        }

        guard let url = components.url else {
            throw AgentAPIError.invalidBaseURL(
                "\(configKey) could not be parsed into a usable URL."
            )
        }

        return url
    }

    private static func resolvedValue() -> String? {
        if let raw = Bundle.main.object(forInfoDictionaryKey: configKey) as? String {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return trimmed
            }
        }
        if let raw = ProcessInfo.processInfo.environment[configKey] {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return trimmed
            }
        }
        return nil
    }
}
