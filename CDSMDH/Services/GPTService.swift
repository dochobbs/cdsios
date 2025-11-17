import Foundation

// MARK: - Ollama Configuration

struct OllamaConfiguration: Sendable {
    enum Model: String, CaseIterable, Identifiable, Codable {
        case kimiK2Thinking = "kimi-k2-thinking"
        case kimiK2 = "kimi-k2"
        case deepseekV3 = "deepseek-v3.1:671b"
        case gptOss = "gpt-oss:120b"

        static let `default`: Model = .kimiK2Thinking

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .kimiK2Thinking:
                return "Kimi K2 Thinking (Recommended)"
            case .kimiK2:
                return "Kimi K2"
            case .deepseekV3:
                return "DeepSeek V3.1 (671B)"
            case .gptOss:
                return "GPT-OSS (120B)"
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
            guard let url = URL(string: "https://ollama.com/api") else {
                fatalError("Invalid default base URL configuration")
            }
            return url
        }()
    }
}

// MARK: - Service Error

enum OllamaServiceError: Error, LocalizedError {
    case missingAPIKey
    case invalidResponse
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Add an Ollama API key in Settings."
        case .invalidResponse:
            return "Received an unexpected response from Ollama."
        case .serverError(let details):
            return details
        }
    }
}

// MARK: - Ollama Service

actor GPTService {
    private let urlSession: URLSession

    init(session: URLSession = .shared) {
        self.urlSession = session
    }

    func streamCompletion(
        configuration: OllamaConfiguration,
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
                        throw OllamaServiceError.missingAPIKey
                    }

                    var request = URLRequest(url: configuration.baseURL.appendingPathComponent("chat"))
                    request.httpMethod = "POST"
                    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

                    let payload: [String: Any] = [
                        "model": configuration.model.rawValue,
                        "messages": [
                            ["role": "system", "content": systemPrompt],
                            ["role": "user", "content": userMessage]
                        ],
                        "stream": true,
                        "options": [
                            "temperature": temperature,
                            "num_predict": maxTokens
                        ]
                    ]

                    request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])

                    let (bytes, response) = try await urlSession.bytes(for: request)
                    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                        throw OllamaServiceError.serverError("HTTP \(statusCode)")
                    }

                    for try await line in bytes.lines {
                        guard !line.isEmpty else { continue }

                        guard
                            let data = line.data(using: .utf8),
                            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                        else {
                            continue
                        }

                        // Check if done
                        if let done = json["done"] as? Bool, done {
                            break
                        }

                        // Extract message content
                        if let message = json["message"] as? [String: Any],
                           let content = message["content"] as? String {
                            continuation.yield(content)
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
