import Foundation

/// Single transport layer for `POST /v1/chat` (supervisor entrypoint).
@Observable
final class AgentAPIClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func sendChat(
        userId: String,
        sessionId: String,
        query: String?,
        lat: Double?,
        lon: Double?,
        triggerType: String,
        idToken: String?
    ) async throws -> CommonResponseDTO {
        let base = AgentAPIConfiguration.baseURL
        let path = base.appendingPathComponent("v1").appendingPathComponent("chat")
        var request = URLRequest(url: path)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120
        if let idToken, !idToken.isEmpty {
            request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        }

        let body = CommonRequestDTO(
            userId: userId,
            sessionId: sessionId,
            query: query,
            lat: lat,
            lon: lon,
            triggerType: triggerType
        )
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        request.httpBody = try encoder.encode(body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw error
        }

        guard let http = response as? HTTPURLResponse else {
            throw AgentAPIError.invalidResponse
        }

        let textSnippet = String(data: data, encoding: .utf8)

        guard (200...299).contains(http.statusCode) else {
            throw AgentAPIError.httpStatus(http.statusCode, textSnippet)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        do {
            return try decoder.decode(CommonResponseDTO.self, from: data)
        } catch {
            throw AgentAPIError.decoding(error)
        }
    }
}
