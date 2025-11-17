import Foundation

@MainActor
final class CDSViewModel: StreamingCommandViewModel {
    enum ResponseFormat: String, CaseIterable, Identifiable {
        case full
        case quick

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .full:
                return "Full"
            case .quick:
                return "Quick"
            }
        }
    }

    @Published var presentation: String = ""
    @Published var keyConcerns: String = ""
    @Published var format: ResponseFormat = .full

    override init(commandKey: String = "cds", gptService: GPTService, promptStore: PromptStore, settings: SecureSettings) {
        super.init(commandKey: commandKey, gptService: gptService, promptStore: promptStore, settings: settings)
    }

    func submit() {
        let trimmed = presentation.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            error = "Describe the clinical presentation."
            return
        }

        var lines: [String] = [
            "Request Type: Pediatric clinical decision support",
            "Response Style: \(format.rawValue.uppercased())",
            "Clinical Presentation:\n\(trimmed)"
        ]

        let trimmedConcerns = keyConcerns.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedConcerns.isEmpty {
            lines.append("Provider Questions / Key Concerns:\n\(trimmedConcerns)")
        }

        lines.append("Output Requirements: highlight red flags, differential, diagnostics, management, and disposition.")
        lines.append("Safety Checklist: escalate emergent findings first, note weight-based dosing if meds suggested.")

        stream(userMessage: lines.joined(separator: "\n\n"), temperature: 0.25, maxTokens: 3072)
    }
}
