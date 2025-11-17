import SwiftUI

// MARK: - Privacy & HIPAA Compliance Notice
/*
 IMPORTANT: PRIVACY AND DATA TRANSMISSION DISCLOSURE

 This application transmits clinical information to OpenAI's API for processing.

 Healthcare organizations using this app must ensure:
 1. A valid Business Associate Agreement (BAA) is in place with OpenAI
 2. Users are informed about data transmission to third-party services
 3. Appropriate consent is obtained before transmitting patient information
 4. All usage complies with HIPAA, state privacy laws, and organizational policies

 No patient data is stored locally on the device beyond the current session.
 All data transmission occurs over encrypted HTTPS connections.
 API keys are stored securely in the iOS Keychain.

 Consult your organization's privacy and compliance teams before clinical use.
 */

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
