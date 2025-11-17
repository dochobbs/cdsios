import Foundation

/// Shared Claude streaming plumbing so each clinical command can focus on its inputs.
@MainActor
class StreamingCommandViewModel: ObservableObject {
    @Published var output: String = ""
    @Published var isStreaming: Bool = false
    @Published var error: String?

    internal var streamingTask: Task<Void, Never>?

    let commandKey: String
    let gptService: GPTService
    let promptStore: PromptStore
    let settings: SecureSettings

    init(commandKey: String, gptService: GPTService, promptStore: PromptStore, settings: SecureSettings) {
        self.commandKey = commandKey
        self.gptService = gptService
        self.promptStore = promptStore
        self.settings = settings
    }

    func stream(userMessage: String, temperature: Double = 0.2, maxTokens: Int = 4096) {
        guard let template = promptStore.template(for: commandKey) else {
            error = "Prompt template for '\(commandKey)' is missing."
            return
        }

        guard let configuration = prepareConfiguration() else { return }

        error = nil
        output = ""
        isStreaming = true

        streamingTask?.cancel()
        streamingTask = Task { [weak self] in
            guard let self else { return }
            do {
                let stream = await self.gptService.streamCompletion(
                    configuration: configuration,
                    systemPrompt: template.systemPrompt,
                    userMessage: userMessage,
                    temperature: temperature,
                    maxTokens: maxTokens
                )

                for try await chunk in stream {
                    try Task.checkCancellation()
                    // Ollama sends full accumulated message, not deltas
                    await MainActor.run {
                        self.output = chunk
                    }
                }

                await MainActor.run {
                    self.isStreaming = false
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.isStreaming = false
                }
            }
        }
    }

    func cancelStreaming() {
        streamingTask?.cancel()
        streamingTask = nil
        isStreaming = false
    }

    internal func prepareConfiguration() -> OllamaConfiguration? {
        let configuration = settings.configuration()
        guard let apiKey = configuration.apiKey, !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            error = "Add an Ollama API key in Settings."
            return nil
        }
        return configuration
    }
}
