import Foundation

struct GPTConfiguration: Sendable {
    enum Model: String, CaseIterable, Identifiable, Codable {
        case gpt5Thinking = "gpt-5.1"
        case gpt5Chat = "gpt-5.1-chat-latest"

        static let `default`: Model = .gpt5Thinking

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .gpt5Thinking:
                return "GPT-5.1 (Thinking)"
            case .gpt5Chat:
                return "GPT-5.1 Chat (Instant)"
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
            guard let url = URL(string: "https://api.openai.com/v1") else {
                fatalError("Invalid default base URL configuration")
            }
            return url
        }()
    }
}

enum GPTServiceError: Error, LocalizedError {
    case missingAPIKey
    case invalidResponse
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Add an OpenAI API key in Settings."
        case .invalidResponse:
            return "Received an unexpected response from GPT-5.1."
        case .serverError(let details):
            return details
        }
    }
}

actor GPTService {
    private let urlSession: URLSession

    init(session: URLSession = .shared) {
        self.urlSession = session
    }

    func streamCompletion(
        configuration: GPTConfiguration,
        systemPrompt: String,
        userMessage: String,
        temperature: Double = 0.2,
        maxTokens: Int = 2048
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let apiKey = configuration.apiKey?.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard let apiKey, !apiKey.isEmpty else {
                        throw GPTServiceError.missingAPIKey
                    }

                    var request = URLRequest(url: configuration.baseURL.appendingPathComponent("chat/completions"))
                    request.httpMethod = "POST"
                    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

                    let payload: [String: Any] = [
                        "model": configuration.model.rawValue,
                        "stream": true,
                        "temperature": temperature,
                        "max_completion_tokens": maxTokens,
                        "messages": [
                            ["role": "system", "content": systemPrompt],
                            ["role": "user", "content": userMessage]
                        ]
                    ]

                    request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])

                    let (bytes, response) = try await urlSession.bytes(for: request)
                    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                        throw GPTServiceError.invalidResponse
                    }

                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        let jsonLine = line.dropFirst(6)
                        if jsonLine == "[DONE]" {
                            break
                        }

                        guard
                            let data = jsonLine.data(using: .utf8),
                            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                            let choices = json["choices"] as? [[String: Any]],
                            let delta = choices.first?["delta"] as? [String: Any],
                            let content = delta["content"] as? String
                        else {
                            continue
                        }

                        continuation.yield(content)
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
