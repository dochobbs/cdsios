import SwiftUI

// MARK: - Lakes Pediatrics Brand System
// Based on LP Digital Style Guide (August 2023)

enum LakesBrand {
    // MARK: - Colors (from brand guide)

    /// Dark Navy #050A30 - Pantone 275 C
    static let darkNavy = Color(hex: "050A30")

    /// Navy #003B73 - Pantone 654 C
    static let navy = Color(hex: "003B73")

    /// Light Blue #60A3D9 - Pantone 284 C
    static let lightBlue = Color(hex: "60A3D9")

    /// Pale Blue #AFDDFF - Pantone 291C
    static let paleBlue = Color(hex: "AFDDFF")

    // MARK: - Semantic Colors

    static let primary = navy
    static let accent = lightBlue
    static let background = darkNavy
    static let surface = navy.opacity(0.3)
    static let surfaceVariant = Color.white.opacity(0.08)

    // MARK: - Gradients

    static let primaryGradient = LinearGradient(
        colors: [darkNavy, navy],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let accentGradient = LinearGradient(
        colors: [lightBlue, paleBlue],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Typography
    // Using SF Pro as substitute for Adelle (similar weights and proportions)

    /// Title - Bold (substitute for Adelle Bold)
    static func title() -> Font {
        .system(size: 28, weight: .bold, design: .default)
    }

    /// Headline - Semibold (substitute for Adelle Semibold)
    static func headline() -> Font {
        .system(size: 20, weight: .semibold, design: .default)
    }

    /// Body - Regular (substitute for Adelle Regular)
    static func body() -> Font {
        .system(size: 17, weight: .regular, design: .default)
    }

    /// Subheadline - Medium
    static func subheadline() -> Font {
        .system(size: 15, weight: .medium, design: .default)
    }

    /// Caption - Regular
    static func caption() -> Font {
        .system(size: 13, weight: .regular, design: .default)
    }

    // MARK: - Spacing Tokens

    static let spacingXS: CGFloat = 4
    static let spacingS: CGFloat = 8
    static let spacingM: CGFloat = 16
    static let spacingL: CGFloat = 24
    static let spacingXL: CGFloat = 32

    // MARK: - Corner Radius

    static let radiusS: CGFloat = 12
    static let radiusM: CGFloat = 16
    static let radiusL: CGFloat = 24
}

// MARK: - Color Extension for Hex Support

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: // RGB (24-bit)
            (r, g, b, a) = (int >> 16, int >> 8 & 0xFF, int & 0xFF, 255)
        case 8: // ARGB (32-bit)
            (r, g, b, a) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b, a) = (0, 0, 0, 255)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Card Component

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
        VStack(alignment: .leading, spacing: LakesBrand.spacingM) {
            if title != nil || subtitle != nil || icon != nil {
                HStack(alignment: .firstTextBaseline, spacing: LakesBrand.spacingM) {
                    if let icon {
                        Image(systemName: icon)
                            .font(LakesBrand.headline())
                            .foregroundStyle(LakesBrand.lightBlue)
                    }
                    VStack(alignment: .leading, spacing: LakesBrand.spacingXS) {
                        if let title {
                            Text(title)
                                .font(LakesBrand.headline())
                                .foregroundStyle(.white)
                        }
                        if let subtitle {
                            Text(subtitle)
                                .font(LakesBrand.caption())
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                }
            }

            content
        }
        .padding(LakesBrand.spacingL)
        .background(
            RoundedRectangle(cornerRadius: LakesBrand.radiusL, style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.5))
                .background(
                    RoundedRectangle(cornerRadius: LakesBrand.radiusL, style: .continuous)
                        .fill(LakesBrand.navy.opacity(0.2))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: LakesBrand.radiusL, style: .continuous)
                        .stroke(LakesBrand.lightBlue.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Button Styles

struct PrimaryActionButtonStyle: ButtonStyle {
    var isDestructive: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(LakesBrand.headline())
            .frame(maxWidth: .infinity)
            .padding(.vertical, LakesBrand.spacingM)
            .background(
                RoundedRectangle(cornerRadius: LakesBrand.radiusM, style: .continuous)
                    .fill(isDestructive ? Color.red : LakesBrand.accentGradient)
                    .opacity(configuration.isPressed ? 0.8 : 1)
            )
            .foregroundStyle(.white)
            .shadow(
                color: (isDestructive ? Color.red : LakesBrand.lightBlue).opacity(0.3),
                radius: 12,
                y: 6
            )
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(LakesBrand.headline())
            .frame(maxWidth: .infinity)
            .padding(.vertical, LakesBrand.spacingM)
            .background(
                RoundedRectangle(cornerRadius: LakesBrand.radiusM, style: .continuous)
                    .fill(LakesBrand.surfaceVariant)
                    .opacity(configuration.isPressed ? 0.5 : 1)
            )
            .foregroundStyle(.white.opacity(0.9))
            .overlay(
                RoundedRectangle(cornerRadius: LakesBrand.radiusM, style: .continuous)
                    .stroke(LakesBrand.lightBlue.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - Streaming Output Component

struct StreamingOutputSection: View {
    let title: String
    let output: String
    let isStreaming: Bool

    init(title: String = "Response", output: String, isStreaming: Bool) {
        self.title = title
        self.output = output
        self.isStreaming = isStreaming
    }

    var body: some View {
        GlassCard(
            title: title,
            subtitle: isStreaming ? "Streaming…" : "Complete",
            icon: "bubble.left.and.bubble.right.fill"
        ) {
            if output.isEmpty {
                VStack(alignment: .leading, spacing: LakesBrand.spacingS) {
                    Text("Your response will appear here")
                        .font(LakesBrand.body())
                        .foregroundStyle(.white.opacity(0.8))
                    Text("Clinical recommendations powered by GPT-5.1")
                        .font(LakesBrand.caption())
                        .foregroundStyle(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(LakesBrand.spacingL)
                .background(
                    RoundedRectangle(cornerRadius: LakesBrand.radiusM, style: .continuous)
                        .fill(LakesBrand.darkNavy.opacity(0.3))
                )
            } else {
                ScrollView {
                    Text(output)
                        .font(LakesBrand.body())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .padding(LakesBrand.spacingL)
                }
                .frame(minHeight: 200)
                .background(
                    RoundedRectangle(cornerRadius: LakesBrand.radiusM, style: .continuous)
                        .fill(LakesBrand.darkNavy.opacity(0.3))
                )
            }
        }
    }
}

// MARK: - Text Field Style

struct BrandedTextFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(LakesBrand.body())
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

extension View {
    func brandedTextField() -> some View {
        modifier(BrandedTextFieldStyle())
    }
}
