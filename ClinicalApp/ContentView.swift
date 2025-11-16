import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var settings: SecureSettings
    private let promptStore = PromptStore.shared
    private let gptService = GPTService()

    var body: some View {
        DrugLookupView(
            viewModel: DrugLookupViewModel(
                gptService: gptService,
                promptStore: promptStore,
                settings: settings
            )
        )
    }
}

#Preview {
    ContentView()
        .environmentObject(SecureSettings.shared)
}
