import Foundation
import os.log

struct PromptTemplate: Identifiable, Codable {
    var id: UUID = UUID()
    let name: String
    let command: String
    let source: String
    let systemPrompt: String

    enum CodingKeys: String, CodingKey {
        case name
        case command
        case source
        case systemPrompt = "system_prompt"
    }

    init(id: UUID = UUID(), name: String, command: String, source: String, systemPrompt: String) {
        self.id = id
        self.name = name
        self.command = command
        self.source = source
        self.systemPrompt = systemPrompt
    }
}

@MainActor
final class PromptStore: ObservableObject {
    static let shared = PromptStore()
    private let logger = Logger(subsystem: "com.dochobbs.clinicalapp", category: "PromptStore")

    @Published private(set) var templates: [String: PromptTemplate] = [:]

    private init() {
        loadPrompts()
    }

    func template(for command: String) -> PromptTemplate? {
        templates[command]
    }

    private func loadPrompts() {
        guard let files = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: "Prompts") else {
            return
        }

        var loaded: [String: PromptTemplate] = [:]

        for file in files {
            do {
                let data = try Data(contentsOf: file)
                let template = try JSONDecoder().decode(PromptTemplate.self, from: data)
                loaded[template.command] = template
            } catch {
                logger.error("Failed to load prompt from \(file.lastPathComponent, privacy: .public): \(error.localizedDescription, privacy: .public)")
            }
        }

        templates = loaded
    }
}
