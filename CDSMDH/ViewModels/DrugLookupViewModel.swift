import Foundation
import SwiftUI

@MainActor
final class DrugLookupViewModel: StreamingCommandViewModel {
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

    @Published var drugName: String = ""
    @Published var weightInput: String = ""
    @Published var ageInput: String = ""
    @Published var indication: String = ""
    @Published var format: ResponseFormat = .full
    @Published var isFetchingAlternate: Bool = false

    // Cached responses for each format
    private var fullOutput: String?
    private var quickOutput: String?
    private var parentOutput: String?
    private var lastWeightKg: Double?
    private var lastWeightDisplay: String?

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

    override init(commandKey: String = "drug", gptService: GPTService, promptStore: PromptStore, settings: SecureSettings) {
        super.init(commandKey: commandKey, gptService: gptService, promptStore: promptStore, settings: settings)
    }

    func submit() {
        guard !drugName.trimmingCharacters(in: .whitespaces).isEmpty else {
            error = "Enter a medication."
            return
        }

        do {
            let (weightKg, weightDisplay) = try WeightFormatter.parse(weight: weightInput)
            lastWeightKg = weightKg
            lastWeightDisplay = weightDisplay

            // Clear all caches when submitting new query
            fullOutput = nil
            quickOutput = nil
            parentOutput = nil

            let message = buildUserMessage(weightKg: weightKg, weightDisplay: weightDisplay)
            streamToCache(message: message, format: format)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func toggleFormat(to newFormat: ResponseFormat) {
        format = newFormat

        // Check if we already have this format cached
        let cached: String?
        switch newFormat {
        case .full:
            cached = fullOutput
        case .quick:
            cached = quickOutput
        case .parent:
            cached = parentOutput
        }

        if cached == nil, let weightKg = lastWeightKg, let weightDisplay = lastWeightDisplay {
            // Need to fetch this format
            isFetchingAlternate = true
            let message = buildUserMessage(weightKg: weightKg, weightDisplay: weightDisplay)
            streamToCache(message: message, format: newFormat)
        }
    }

    private func streamToCache(message: String, format: ResponseFormat) {
        // Use parent's stream method but capture to appropriate cache
        stream(userMessage: message, temperature: 0.2)

        // Override the output to cache properly
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
                    temperature: 0.2,
                    maxTokens: 4096
                )

                for try await chunk in stream {
                    try Task.checkCancellation()
                    // Ollama sends full accumulated message, not deltas
                    await MainActor.run {
                        self.output = chunk
                        // Update cache in real-time for streaming display
                        switch format {
                        case .full:
                            self.fullOutput = chunk
                        case .quick:
                            self.quickOutput = chunk
                        case .parent:
                            self.parentOutput = chunk
                        }
                    }
                }

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

    private func buildUserMessage(weightKg: Double, weightDisplay: String) -> String {
        var lines: [String] = [
            "Request Type: Pediatric drug lookup",
            "Drug: \(drugName)",
            "Response Style: \(format.rawValue.uppercased())",
            "Patient Weight: \(weightDisplay)",
            "Patient Weight (kg): \(String(format: "%.2f", weightKg)) kg"
        ]

        if !ageInput.isEmpty {
            lines.append("Patient Age: \(ageInput)")
        }
        if !indication.isEmpty {
            lines.append("Indication: \(indication)")
        }

        lines.append("Output Requirements: Mirror CLI structure with CALCULATED DOSE block filled out.")
        lines.append("Safety Checklist: verify dosing range, max single dose, max daily dose.")
        return lines.joined(separator: "\n")
    }
}
