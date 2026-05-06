import SwiftUI

struct TypeChipView: View {
    let type: ProjectType
    var size: ChipSize = .small

    enum ChipSize { case small, large }

    private var height: CGFloat  { size == .large ? 24 : 20 }
    private var fontSize: CGFloat { size == .large ? 12 : 11.5 }

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(type.foregroundColor)
                .frame(width: 6, height: 6)
            Text(type.rawValue)
                .font(.sfPro(fontSize, weight: .semibold))
                .foregroundStyle(type.foregroundColor)
        }
        .padding(.horizontal, 10)
        .frame(height: height)
        .background(type.backgroundColor)
        .clipShape(Capsule())
    }
}
