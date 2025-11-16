import SwiftUI

struct CDSView: View {
    @ObservedObject var viewModel: CDSViewModel
    @EnvironmentObject private var settings: SecureSettings

    var body: some View {
        ZStack {
            ClinicalTheme.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    GlassCard(title: "Clinical Decision Support", subtitle: "Summarize, reason, and act", icon: "stethoscope") {
                        VStack(spacing: 12) {
                            editorField(
                                text: $viewModel.presentation,
                                placeholder: "Presentation (age, vitals, symptoms)",
                                minHeight: 140
                            )

                            editorField(
                                text: $viewModel.keyConcerns,
                                placeholder: "Provider questions or focus (optional)",
                                minHeight: 110
                            )

                            Picker("Response detail", selection: $viewModel.format) {
                                ForEach(CDSViewModel.ResponseFormat.allCases) { format in
                                    Text(format.displayName).tag(format)
                                }
                            }
                            .pickerStyle(.segmented)

                            Button(viewModel.isStreaming ? "Cancel" : "Generate CDS summary") {
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
                                .foregroundStyle(.white)
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color.red.opacity(0.4), lineWidth: 1)
                        )
                    }

                    StreamingOutputSection(title: "CDS Response", output: viewModel.output, isStreaming: viewModel.isStreaming)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
        }
    }

    private func editorField(text: Binding<String>, placeholder: String, minHeight: CGFloat) -> some View {
        TextField("", text: text, prompt: Text(placeholder).foregroundStyle(.white.opacity(0.5)), axis: .vertical)
        .lineLimit(2...8)
        .textInputAutocapitalization(.sentences)
        .padding(12)
        .frame(minHeight: minHeight, alignment: .topLeading)
        .foregroundStyle(.white)
        .background(ClinicalTheme.fieldBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func chip(text: String, icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(.caption.weight(.semibold))
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(ClinicalTheme.fieldBackground)
            .clipShape(Capsule())
            .foregroundStyle(.white)
    }
}
