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

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Response Format".uppercased())
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.5))

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
                        output: viewModel.displayOutput,
                        isStreaming: viewModel.isStreaming,
                        currentFormat: viewModel.format == .full ? "Quick" : "Full",
                        isFetchingAlternate: viewModel.isFetchingAlternate,
                        onToggleFormat: {
                            let newFormat: DrugLookupViewModel.ResponseFormat = viewModel.format == .full ? .quick : .full
                            viewModel.toggleFormat(to: newFormat)
                        }
                    )
                }
                .padding(.horizontal, LakesBrand.spacingM)
                .padding(.top, LakesBrand.spacingM)
                .padding(.bottom, 100)
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
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))

            HStack(spacing: LakesBrand.spacingS) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundStyle(LakesBrand.lightBlue)
                    .frame(width: 20)

                TextField(placeholder, text: text)
                    .font(.system(size: 14))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(keyboard)
                    .foregroundStyle(.white)
            }
            .padding(LakesBrand.spacingS)
            .background(
                RoundedRectangle(cornerRadius: LakesBrand.radiusS, style: .continuous)
                    .fill(LakesBrand.darkNavy.opacity(0.3))
            )
            .overlay(
                RoundedRectangle(cornerRadius: LakesBrand.radiusS, style: .continuous)
                    .stroke(LakesBrand.lightBlue.opacity(0.15), lineWidth: 0.5)
            )
        }
    }
}
