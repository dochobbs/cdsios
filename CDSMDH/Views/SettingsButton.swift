import SwiftUI

struct SettingsButton: View {
    @EnvironmentObject private var settings: SecureSettings
    @State private var showingSheet = false
    @State private var apiKey = ""
    @State private var selectedModel = ClaudeConfiguration.Model.default
    @State private var errorMessage: String?

    var body: some View {
        Button {
            apiKey = settings.apiKey ?? ""
            selectedModel = settings.model
            showingSheet = true
        } label: {
            Image(systemName: "ellipsis.circle")
        }
        .sheet(isPresented: $showingSheet) {
            NavigationStack {
                Form {
                    Section("Anthropic Credentials") {
                        SecureField("API Key", text: $apiKey)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        Text("Stored securely using the Keychain. Required for Claude access.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Section("Model") {
                        Picker("Model", selection: $selectedModel) {
                            ForEach(ClaudeConfiguration.Model.allCases) { model in
                                Text(model.displayName).tag(model)
                            }
                        }
                    }

                    if let message = errorMessage {
                        Section {
                            Text(message)
                                .foregroundStyle(.red)
                        }
                    }
                }
                .navigationTitle("Settings")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showingSheet = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            do {
                                try settings.update(apiKey: apiKey, model: selectedModel)
                                errorMessage = nil
                                showingSheet = false
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                        }
                        .disabled(apiKey.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
        }
    }
}
