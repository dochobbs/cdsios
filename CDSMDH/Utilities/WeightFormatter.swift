import Foundation

struct WeightFormatter {
    enum WeightError: LocalizedError {
        case invalidFormat
        case outOfRange

        var errorDescription: String? {
            switch self {
            case .invalidFormat:
                return "Enter weight as 52#, 52 lbs, or 23.6 kg."
            case .outOfRange:
                return "Weight appears outside the supported pediatric range."
            }
        }
    }

    static func parse(weight: String) throws -> (kg: Double, formatted: String) {
        let trimmed = weight.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { throw WeightError.invalidFormat }

        if let numeric = extractValue(from: trimmed, suffixes: ["#", "lb", "lbs", "pound", "pounds"]) {
            guard numeric >= 4, numeric <= 400 else { throw WeightError.outOfRange }
            let kg = numeric / 2.20462
            return (kg, "\(String(format: "%.1f", numeric)) lbs (\(String(format: "%.1f", kg)) kg)")
        }

        if let numeric = extractValue(from: trimmed, suffixes: ["kg", "kilogram", "kilograms"]) {
            guard numeric >= 2, numeric <= 180 else { throw WeightError.outOfRange }
            let lbs = numeric * 2.20462
            return (numeric, "\(String(format: "%.1f", lbs)) lbs (\(String(format: "%.1f", numeric)) kg)")
        }

        if let numeric = Double(trimmed) {
            if numeric > 20 {
                guard numeric >= 4, numeric <= 400 else { throw WeightError.outOfRange }
                let kg = numeric / 2.20462
                return (kg, "\(String(format: "%.1f", numeric)) lbs (\(String(format: "%.1f", kg)) kg)")
            } else {
                guard numeric >= 2, numeric <= 180 else { throw WeightError.outOfRange }
                let lbs = numeric * 2.20462
                return (numeric, "\(String(format: "%.1f", lbs)) lbs (\(String(format: "%.1f", numeric)) kg)")
            }
        }

        throw WeightError.invalidFormat
    }

    private static func extractValue(from input: String, suffixes: [String]) -> Double? {
        let normalized = input.replacingOccurrences(of: " ", with: "")
        for suffix in suffixes {
            if normalized.hasSuffix(suffix) {
                let valueString = String(normalized.dropLast(suffix.count))
                return Double(valueString)
            }
        }
        return nil
    }
}
