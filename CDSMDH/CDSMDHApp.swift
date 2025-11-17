import SwiftUI

@main
struct CDSMDHApp: App {
    @StateObject private var settings: SecureSettings
    @StateObject private var drugLookupViewModel: DrugLookupViewModel
    @StateObject private var cdsViewModel: CDSViewModel
    private let promptStore: PromptStore
    private let gptService: GPTService

    init() {
        let settingsInstance = SecureSettings.shared
        let promptStore = PromptStore.shared
        let gptService = GPTService()

        _settings = StateObject(wrappedValue: settingsInstance)
        _drugLookupViewModel = StateObject(
            wrappedValue: DrugLookupViewModel(
                gptService: gptService,
                promptStore: promptStore,
                settings: settingsInstance
            )
        )
        _cdsViewModel = StateObject(
            wrappedValue: CDSViewModel(
                gptService: gptService,
                promptStore: promptStore,
                settings: settingsInstance
            )
        )

        self.promptStore = promptStore
        self.gptService = gptService
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                NavigationStack {
                    DrugLookupView(viewModel: drugLookupViewModel)
                        .navigationTitle("Drug Lookup")
                        .toolbar {
                            ToolbarItem(placement: .primaryAction) {
                                SettingsButton()
                            }
                        }
                }
                .tabItem {
                    Label("Medications", systemImage: "pills")
                }

                NavigationStack {
                    CDSView(viewModel: cdsViewModel)
                        .navigationTitle("CDS")
                        .toolbar {
                            ToolbarItem(placement: .primaryAction) {
                                SettingsButton()
                            }
                        }
                }
                .tabItem {
                    Label("CDS", systemImage: "stethoscope")
                }
            }
            .environmentObject(settings)
        }
    }
}
