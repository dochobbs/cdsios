import Foundation

// MARK: - Claude Configuration

struct ClaudeConfiguration: Sendable {
    enum Model: String, CaseIterable, Identifiable, Codable {
        case sonnet45 = "claude-4-5-sonnet-20241022"
        case haiku4 = "claude-4-haiku-20241022"

        static let `default`: Model = .sonnet45

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .sonnet45:
                return "Claude Sonnet 4.5 (Recommended)"
            case .haiku4:
                return "Claude Haiku 4 (Fast)"
            }
        }
    }

    var apiKey: String?
    var model: Model
    var baseURL: URL

    init(apiKey: String? = nil, model: Model = .default, baseURL: URL? = nil) {
        self.apiKey = apiKey
        self.model = model
        self.baseURL = baseURL ?? {
            guard let url = URL(string: "https://api.anthropic.com/v1") else {
                fatalError("Invalid default base URL configuration")
            }
            return url
        }()
    }
}

// MARK: - Service Error

enum ClaudeServiceError: Error, LocalizedError {
    case missingAPIKey
    case invalidResponse
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Add an Anthropic API key in Settings."
        case .invalidResponse:
            return "Received an unexpected response from Claude."
        case .serverError(let details):
            return details
        }
    }
}

// MARK: - Claude Service

actor GPTService {
    private let urlSession: URLSession

    init(session: URLSession = .shared) {
        self.urlSession = session
    }

    func streamCompletion(
        configuration: ClaudeConfiguration,
        systemPrompt: String,
        userMessage: String,
        temperature: Double = 0.2,
        maxTokens: Int = 4096
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let apiKey = configuration.apiKey?.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard let apiKey, !apiKey.isEmpty else {
                        throw ClaudeServiceError.missingAPIKey
                    }

                    var request = URLRequest(url: configuration.baseURL.appendingPathComponent("messages"))
                    request.httpMethod = "POST"
                    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
                    request.addValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

                    let payload: [String: Any] = [
                        "model": configuration.model.rawValue,
                        "max_tokens": maxTokens,
                        "temperature": temperature,
                        "stream": true,
                        "system": systemPrompt,
                        "messages": [
                            ["role": "user", "content": userMessage]
                        ]
                    ]

                    request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])

                    let (bytes, response) = try await urlSession.bytes(for: request)
                    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                        throw ClaudeServiceError.serverError("HTTP \(statusCode)")
                    }

                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        let jsonLine = line.dropFirst(6)

                        // Skip message_stop event
                        if jsonLine.contains("message_stop") {
                            break
                        }

                        guard
                            let data = jsonLine.data(using: .utf8),
                            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                        else {
                            continue
                        }

                        // Handle content_block_delta events
                        if let eventType = json["type"] as? String,
                           eventType == "content_block_delta",
                           let delta = json["delta"] as? [String: Any],
                           let text = delta["text"] as? String {
                            continuation.yield(text)
                        }
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
