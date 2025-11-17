import SwiftUI

struct DrugLookupView: View {
    @ObservedObject var viewModel: DrugLookupViewModel
    @EnvironmentObject private var settings: SecureSettings

    var body: some View {
        ZStack {
            LakesBrand.primaryGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: LakesBrand.spacingM) {
                    GlassCard(
                        title: "Drug Lookup",
                        subtitle: "Weight-based dosing powered by Claude",
                        icon: "pills.circle.fill"
                    ) {
                        VStack(spacing: LakesBrand.spacingM) {
                            inputField(
                                title: "Drug Name",
                                icon: "pills.fill",
                                text: $viewModel.drugName,
                                placeholder: "e.g., Amoxicillin"
                            )

                            inputField(
                                title: "Indication",
                                icon: "text.justify.leading",
                                text: $viewModel.indication,
                                placeholder: "Condition or clinical note"
                            )

                            inputField(
                                title: "Weight",
                                icon: "scalemass.fill",
                                text: $viewModel.weightInput,
                                placeholder: "52# or 23.6 kg",
                                keyboard: .numbersAndPunctuation
                            )

                            inputField(
                                title: "Age (Optional)",
                                icon: "calendar",
                                text: $viewModel.ageInput,
                                placeholder: "e.g., 5 years"
                            )

                            VStack(alignment: .leading, spacing: LakesBrand.spacingS) {
                                Text("Response Format".uppercased())
                                    .font(LakesBrand.caption())
                                    .foregroundStyle(.white.opacity(0.7))

                                Picker("Response format", selection: $viewModel.format) {
                                    ForEach(DrugLookupViewModel.ResponseFormat.allCases) { format in
                                        Text(format.displayName).tag(format)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .background(LakesBrand.darkNavy.opacity(0.3))
                                .cornerRadius(LakesBrand.radiusS)
                            }

                            Button(viewModel.isStreaming ? "Cancel Request" : "Get Dosing Information") {
                                if viewModel.isStreaming {
                                    viewModel.cancelStreaming()
                                } else {
                                    viewModel.submit()
                                }
                            }
                            .buttonStyle(PrimaryActionButtonStyle(isDestructive: viewModel.isStreaming))
                            .disabled(!viewModel.isStreaming && settings.apiKey == nil)
                        }
                    }

                    if let error = viewModel.error {
                        GlassCard(title: "Error", icon: "exclamationmark.triangle.fill") {
                            Text(error)
                                .font(LakesBrand.body())
                                .foregroundStyle(.white)
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: LakesBrand.radiusL, style: .continuous)
                                .stroke(Color.red.opacity(0.5), lineWidth: 2)
                        )
                    }

                    StreamingOutputSection(
                        title: "Dosing Recommendation",
                        output: viewModel.output,
                        isStreaming: viewModel.isStreaming
                    )
                }
                .padding(.horizontal, LakesBrand.spacingM)
                .padding(.vertical, LakesBrand.spacingM)
            }
        }
    }

    private func inputField(
        title: String,
        icon: String,
        text: Binding<String>,
        placeholder: String,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: LakesBrand.spacingS) {
            Text(title.uppercased())
                .font(LakesBrand.caption())
                .foregroundStyle(.white.opacity(0.7))

            HStack(spacing: LakesBrand.spacingM) {
                Image(systemName: icon)
                    .font(LakesBrand.body())
                    .foregroundStyle(LakesBrand.lightBlue)
                    .frame(width: 24)

                TextField(placeholder, text: text)
                    .font(LakesBrand.body())
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(keyboard)
                    .foregroundStyle(.white)
            }
            .padding(LakesBrand.spacingM)
            .background(
                RoundedRectangle(cornerRadius: LakesBrand.radiusM, style: .continuous)
                    .fill(LakesBrand.darkNavy.opacity(0.3))
            )
            .overlay(
                RoundedRectangle(cornerRadius: LakesBrand.radiusM, style: .continuous)
                    .stroke(LakesBrand.lightBlue.opacity(0.2), lineWidth: 1)
            )
        }
    }
}
