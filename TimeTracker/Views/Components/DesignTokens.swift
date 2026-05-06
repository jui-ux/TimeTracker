import SwiftUI

// MARK: - Color tokens
// Fixed dark-mode palette matching the original design file.

extension Color {
    static let ttInk       = Color.white
    static let ttInk2      = Color.white.opacity(0.80)
    static let ttInk3      = Color.white.opacity(0.65)
    static let ttHairline  = Color.white.opacity(0.15)
    static let ttHairline2 = Color.white.opacity(0.12)

    static let ttAccent    = Color(hex: "#e8e1d3")
    static let ttAccentInk = Color(hex: "#1a1612")

    static let ttLive = Color(hex: "#ff6a4d")

    // Hex initializer
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var rgb: UInt64 = 0
        Scanner(string: h).scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >>  8) & 0xFF) / 255
        let b = Double( rgb        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Duration formatting

extension Int {
    var durationFormatted: String {
        let h = self / 3600, m = (self % 3600) / 60
        return "\(h):\(String(format: "%02d", m))"
    }
    var clockFormatted: String {
        let h = self / 3600, m = (self % 3600) / 60, s = self % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
}

// MARK: - Shared button styles

struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.sfPro(13.5, weight: .medium)).foregroundStyle(Color.ttInk2)
            .padding(.horizontal, 16).frame(height: 36)
            .background(Color.white.opacity(configuration.isPressed ? 0.08 : 0.05))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.ttHairline, lineWidth: 0.5))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.sfPro(13.5, weight: .semibold)).foregroundStyle(Color.ttAccentInk)
            .padding(.horizontal, 16).frame(height: 36)
            .background(Color.ttAccent.opacity(configuration.isPressed ? 0.85 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Font shorthands

extension Font {
    static func sfPro(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    static func sfMono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}
