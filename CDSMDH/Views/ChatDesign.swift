import SwiftUI

enum ClinicalTheme {
    static let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.04, green: 0.12, blue: 0.18),
            Color(red: 0.02, green: 0.05, blue: 0.08)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let accent = Color(red: 0.36, green: 0.80, blue: 0.67)
    static let accentSecondary = Color(red: 0.24, green: 0.45, blue: 0.90)
    static let cardStroke = Color.white.opacity(0.08)
    static let fieldBackground = Color.white.opacity(0.06)
}

struct GlassCard<Content: View>: View {
    let title: String?
    let subtitle: String?
    let icon: String?
    @ViewBuilder var content: Content

    init(title: String? = nil, subtitle: String? = nil, icon: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if title != nil || subtitle != nil || icon != nil {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    if let icon {
                        Image(systemName: icon)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(ClinicalTheme.accent)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        if let title {
                            Text(title)
                                .font(.headline)
                                .foregroundStyle(.white)
                        }
                        if let subtitle {
                            Text(subtitle)
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                }
            }

            content
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.thinMaterial.opacity(0.4))
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(ClinicalTheme.cardStroke, lineWidth: 1)
                )
        )
    }
}

struct PrimaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [ClinicalTheme.accentSecondary, ClinicalTheme.accent],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .opacity(configuration.isPressed ? 0.8 : 1)
            )
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: ClinicalTheme.accent.opacity(0.4), radius: 15, y: 8)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(ClinicalTheme.fieldBackground.opacity(configuration.isPressed ? 0.5 : 0.8))
            .foregroundStyle(.white.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct StreamingOutputSection: View {
    let title: String
    let output: String
    let isStreaming: Bool

    init(title: String = "Live Response", output: String, isStreaming: Bool) {
        self.title = title
        self.output = output
        self.isStreaming = isStreaming
    }

    var body: some View {
        GlassCard(title: title, subtitle: isStreaming ? "Streaming…" : "Completed", icon: "bubble.left.and.bubble.right.fill") {
            if output.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Responses will appear here.")
                        .foregroundStyle(.white.opacity(0.8))
                    Text("Start a request to see GPT-5.1 stream results in real time.")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(ClinicalTheme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                ScrollView {
                    Text(output)
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .padding()
                }
                .frame(minHeight: 220)
                .background(ClinicalTheme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
    }
}
