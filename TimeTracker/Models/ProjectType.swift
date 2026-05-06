import SwiftUI

enum ProjectType: String, Codable, CaseIterable, Sendable {
    case wireframe = "Wireframe"
    case hiFi     = "Hi-Fi"
    case research  = "Research"
    case review    = "Review"
    case untyped   = "Untyped"

    var foregroundColor: Color {
        switch self {
        case .wireframe: Color(hex: "#e8e1d3")
        case .hiFi:      Color(hex: "#a3c4ff")
        case .research:  Color(hex: "#7de8a0")
        case .review:    Color(hex: "#f3c27a")
        case .untyped:   Color.white.opacity(0.52)
        }
    }

    var backgroundColor: Color {
        switch self {
        case .wireframe: Color(hex: "#e8e1d3").opacity(0.14)
        case .hiFi:      Color(hex: "#a3c4ff").opacity(0.14)
        case .research:  Color(hex: "#7de8a0").opacity(0.14)
        case .review:    Color(hex: "#f3c27a").opacity(0.14)
        case .untyped:   Color.white.opacity(0.08)
        }
    }
}
