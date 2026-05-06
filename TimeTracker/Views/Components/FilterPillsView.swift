import SwiftUI

struct FilterPillsView: View {
    @Binding var selected: ProjectType?   // nil = All

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                pill(label: "All", type: nil)
                ForEach(ProjectType.allCases, id: \.self) { type in
                    pill(label: type.rawValue, type: type)
                }
            }
        }
    }

    @ViewBuilder
    private func pill(label: String, type: ProjectType?) -> some View {
        let isActive = selected == type
        Button {
            selected = type
        } label: {
            Text(label)
                .font(.sfPro(11.5, weight: isActive ? .semibold : .regular))
                .foregroundStyle(isActive ? Color.ttInk : Color.ttInk2)
                .padding(.horizontal, 10)
                .frame(height: 24)
                .background(isActive ? Color.white.opacity(0.10) : Color.clear)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
