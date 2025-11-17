import SwiftUI

struct CDSView: View {
    @ObservedObject var viewModel: CDSViewModel
    @EnvironmentObject private var settings: SecureSettings

    var body: some View {
        ZStack {
            LakesBrand.primaryGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: LakesBrand.spacingM) {
                    GlassCard(
                        title: "Clinical Decision Support",
                        subtitle: "AI-powered clinical reasoning and recommendations",
                        icon: "stethoscope"
                    ) {
                        VStack(spacing: LakesBrand.spacingM) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Clinical Presentation".uppercased())
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.5))

                                editorField(
                                    text: $viewModel.presentation,
                                    placeholder: "Patient age, chief complaint, vitals, symptoms, exam findings...",
                                    minHeight: 120
                                )
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Provider Questions (Optional)".uppercased())
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.5))

                                editorField(
                                    text: $viewModel.keyConcerns,
                                    placeholder: "Specific questions, differential considerations, or areas of focus...",
                                    minHeight: 90
                                )
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Response Detail".uppercased())
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.5))

                                Picker("Response detail", selection: $viewModel.format) {
                                    ForEach(CDSViewModel.ResponseFormat.allCases) { format in
                                        Text(format.displayName).tag(format)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .background(LakesBrand.darkNavy.opacity(0.3))
                                .cornerRadius(LakesBrand.radiusS)
                            }

                            Button(viewModel.isStreaming ? "Cancel Request" : "Generate Clinical Summary") {
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
                        title: "Clinical Summary",
                        output: viewModel.displayOutput,
                        isStreaming: viewModel.isStreaming,
                        currentFormat: viewModel.format == .full ? "Quick" : "Full",
                        isFetchingAlternate: viewModel.isFetchingAlternate,
                        onToggleFormat: {
                            let newFormat: CDSViewModel.ResponseFormat = viewModel.format == .full ? .quick : .full
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

    private func editorField(text: Binding<String>, placeholder: String, minHeight: CGFloat) -> some View {
        TextField(
            "",
            text: text,
            prompt: Text(placeholder).foregroundStyle(.white.opacity(0.4)),
            axis: .vertical
        )
        .font(.system(size: 14))
        .lineLimit(2...10)
        .textInputAutocapitalization(.sentences)
        .padding(LakesBrand.spacingS)
        .frame(minHeight: minHeight, alignment: .topLeading)
        .foregroundStyle(.white)
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
