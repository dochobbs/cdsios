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
                            VStack(alignment: .leading, spacing: LakesBrand.spacingS) {
                                Text("Clinical Presentation".uppercased())
                                    .font(LakesBrand.caption())
                                    .foregroundStyle(.white.opacity(0.7))

                                editorField(
                                    text: $viewModel.presentation,
                                    placeholder: "Patient age, chief complaint, vitals, symptoms, exam findings...",
                                    minHeight: 120
                                )
                            }

                            VStack(alignment: .leading, spacing: LakesBrand.spacingS) {
                                Text("Provider Questions (Optional)".uppercased())
                                    .font(LakesBrand.caption())
                                    .foregroundStyle(.white.opacity(0.7))

                                editorField(
                                    text: $viewModel.keyConcerns,
                                    placeholder: "Specific questions, differential considerations, or areas of focus...",
                                    minHeight: 90
                                )
                            }

                            VStack(alignment: .leading, spacing: LakesBrand.spacingS) {
                                Text("Response Detail".uppercased())
                                    .font(LakesBrand.caption())
                                    .foregroundStyle(.white.opacity(0.7))

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
                        output: viewModel.output,
                        isStreaming: viewModel.isStreaming
                    )
                }
                .padding(.horizontal, LakesBrand.spacingM)
                .padding(.vertical, LakesBrand.spacingM)
            }
        }
    }

    private func editorField(text: Binding<String>, placeholder: String, minHeight: CGFloat) -> some View {
        TextField(
            "",
            text: text,
            prompt: Text(placeholder).foregroundStyle(.white.opacity(0.5)),
            axis: .vertical
        )
        .font(LakesBrand.body())
        .lineLimit(2...10)
        .textInputAutocapitalization(.sentences)
        .padding(LakesBrand.spacingM)
        .frame(minHeight: minHeight, alignment: .topLeading)
        .foregroundStyle(.white)
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
