import Foundation

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
                print("Failed to load prompt from \(file.lastPathComponent): \(error)")
            }
        }

        templates = loaded
    }
}
