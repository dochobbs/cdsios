import Foundation
import SwiftUI

@MainActor
final class DrugLookupViewModel: StreamingCommandViewModel {
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

    @Published var drugName: String = ""
    @Published var weightInput: String = ""
    @Published var ageInput: String = ""
    @Published var indication: String = ""
    @Published var format: ResponseFormat = .full

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
            let message = buildUserMessage(weightKg: weightKg, weightDisplay: weightDisplay)
            stream(userMessage: message, temperature: 0.2)
        } catch {
            self.error = error.localizedDescription
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
