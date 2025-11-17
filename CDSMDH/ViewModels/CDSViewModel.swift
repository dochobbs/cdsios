import Foundation

@MainActor
final class CDSViewModel: StreamingCommandViewModel {
    enum ResponseFormat: String, CaseIterable, Identifiable {
        case full
        case quick
        case parent

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .full:
                return "Full"
            case .quick:
                return "Quick"
            case .parent:
                return "Parent"
            }
        }
    }

    @Published var presentation: String = ""
    @Published var keyConcerns: String = ""
    @Published var format: ResponseFormat = .full
    @Published var isFetchingAlternate: Bool = false

    // Cached responses for each format
    private var fullOutput: String?
    private var quickOutput: String?
    private var parentOutput: String?
    private var lastPresentation: String?
    private var lastConcerns: String?

    var displayOutput: String {
        switch format {
        case .full:
            return fullOutput ?? ""
        case .quick:
            return quickOutput ?? ""
        case .parent:
            return parentOutput ?? ""
        }
    }

    var hasAlternateFormat: Bool {
        switch format {
        case .full:
            return quickOutput != nil || parentOutput != nil
        case .quick:
            return fullOutput != nil || parentOutput != nil
        case .parent:
            return fullOutput != nil || quickOutput != nil
        }
    }

    override init(commandKey: String = "cds", gptService: GPTService, promptStore: PromptStore, settings: SecureSettings) {
        super.init(commandKey: commandKey, gptService: gptService, promptStore: promptStore, settings: settings)
    }

    func submit() {
        let trimmed = presentation.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            error = "Describe the clinical presentation."
            return
        }

        lastPresentation = trimmed
        lastConcerns = keyConcerns.trimmingCharacters(in: .whitespacesAndNewlines)

        // Clear all caches when submitting new query
        fullOutput = nil
        quickOutput = nil
        parentOutput = nil

        let message = buildUserMessage(presentation: trimmed, concerns: lastConcerns!)
        streamToCache(message: message, format: format)
    }

    func toggleFormat(to newFormat: ResponseFormat) {
        print("DEBUG toggleFormat: Switching to \(newFormat)")
        format = newFormat

        // Check if we already have this format cached
        let cached: String?
        switch newFormat {
        case .full:
            cached = fullOutput
            print("DEBUG: fullOutput cache exists: \(fullOutput != nil), length: \(fullOutput?.count ?? 0)")
        case .quick:
            cached = quickOutput
            print("DEBUG: quickOutput cache exists: \(quickOutput != nil), length: \(quickOutput?.count ?? 0)")
        case .parent:
            cached = parentOutput
            print("DEBUG: parentOutput cache exists: \(parentOutput != nil), length: \(parentOutput?.count ?? 0)")
        }

        if cached == nil, let presentation = lastPresentation {
            // Need to fetch this format
            print("DEBUG: Cache miss, fetching format \(newFormat)")
            isFetchingAlternate = true
            let message = buildUserMessage(presentation: presentation, concerns: lastConcerns ?? "")
            streamToCache(message: message, format: newFormat)
        } else if cached != nil {
            print("DEBUG: Cache hit, using cached response")
        }
    }

    private func streamToCache(message: String, format: ResponseFormat) {
        streamingTask?.cancel()
        streamingTask = Task { [weak self] in
            guard let self else { return }
            guard let template = self.promptStore.template(for: self.commandKey) else {
                await MainActor.run {
                    self.error = "Prompt template for '\(self.commandKey)' is missing."
                }
                return
            }

            guard let configuration = self.prepareConfiguration() else { return }

            await MainActor.run {
                self.error = nil
                self.output = ""
                self.isStreaming = true
            }

            do {
                let stream = await self.gptService.streamCompletion(
                    configuration: configuration,
                    systemPrompt: template.systemPrompt,
                    userMessage: message,
                    temperature: 0.25,
                    maxTokens: 4096
                )

                for try await chunk in stream {
                    try Task.checkCancellation()
                    print("DEBUG ViewModel: Received chunk, length: \(chunk.count)")
                    // Ollama sends full accumulated message, not deltas
                    await MainActor.run {
                        print("DEBUG ViewModel: Updating output on MainActor")
                        self.output = chunk
                        // Update cache in real-time for streaming display
                        switch format {
                        case .full:
                            self.fullOutput = chunk
                            print("DEBUG: Updated fullOutput cache")
                        case .quick:
                            self.quickOutput = chunk
                            print("DEBUG: Updated quickOutput cache")
                        case .parent:
                            self.parentOutput = chunk
                            print("DEBUG: Updated parentOutput cache")
                        }
                    }
                }

                print("DEBUG ViewModel: Stream completed")

                await MainActor.run {
                    self.isStreaming = false
                    self.isFetchingAlternate = false
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.isStreaming = false
                    self.isFetchingAlternate = false
                }
            }
        }
    }

    private func buildUserMessage(presentation: String, concerns: String) -> String {
        var lines: [String] = [
            "Request Type: Pediatric clinical decision support",
            "Response Style: \(format.rawValue.uppercased())",
            "Clinical Presentation:\n\(presentation)"
        ]

        if !concerns.isEmpty {
            lines.append("Provider Questions / Key Concerns:\n\(concerns)")
        }

        lines.append("Output Requirements: highlight red flags, differential, diagnostics, management, and disposition.")
        lines.append("Safety Checklist: escalate emergent findings first, note weight-based dosing if meds suggested.")

        return lines.joined(separator: "\n\n")
    }
}
