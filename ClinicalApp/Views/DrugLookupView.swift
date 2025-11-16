import SwiftUI

struct DrugLookupView: View {
    @ObservedObject var viewModel: DrugLookupViewModel
    @EnvironmentObject private var settings: SecureSettings

    var body: some View {
        ZStack {
            ClinicalTheme.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    GlassCard(title: "Drug Lookup", subtitle: "Weight + indication + GPT‑5.1", icon: "pills.circle") {
                        VStack(spacing: 14) {
                            inputField(title: "Drug name", icon: "pills.fill", text: $viewModel.drugName, placeholder: "e.g., Amoxicillin")
                            inputField(title: "Indication", icon: "text.justify.leading", text: $viewModel.indication, placeholder: "Condition or note")
                            inputField(
                                title: "Weight",
                                icon: "scalemass.fill",
                                text: $viewModel.weightInput,
                                placeholder: "52# or 23.6 kg",
                                keyboard: .numbersAndPunctuation
                            )
                            inputField(title: "Age", icon: "calendar", text: $viewModel.ageInput, placeholder: "Optional (e.g., 5 years)")

                            Picker("Response format", selection: $viewModel.format) {
                                ForEach(DrugLookupViewModel.ResponseFormat.allCases) { format in
                                    Text(format.displayName).tag(format)
                                }
                            }
                            .pickerStyle(.segmented)

                            Button(viewModel.isStreaming ? "Cancel" : "Run lookup") {
                                if viewModel.isStreaming {
                                    viewModel.cancelStreaming()
                                } else {
                                    viewModel.submit()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .tint(ClinicalTheme.accent)
                            .disabled(!viewModel.isStreaming && settings.apiKey == nil)
                        }
                    }

                    if let error = viewModel.error {
                        GlassCard(title: "Something went wrong", icon: "exclamationmark.triangle.fill") {
                            Text(error)
                                .font(.body)
                                .foregroundStyle(.white)
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color.red.opacity(0.4), lineWidth: 1)
                        )
                    }

                    StreamingOutputSection(output: viewModel.output, isStreaming: viewModel.isStreaming)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
        }
    }

    private func inputField(title: String, icon: String, text: Binding<String>, placeholder: String, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.7))

            HStack {
                Image(systemName: icon)
                    .foregroundStyle(ClinicalTheme.accent)
                TextField(placeholder, text: text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(keyboard)
                    .foregroundStyle(.white)
            }
            .padding()
            .background(ClinicalTheme.fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}
