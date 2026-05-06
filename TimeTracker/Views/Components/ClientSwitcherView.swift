import SwiftUI
import SwiftData

struct ClientSwitcherView: View {
    @Environment(TimerStore.self) private var store
    @Query(sort: \Client.sortOrder) private var clients: [Client]

    var body: some View {
        if clients.isEmpty {
            EmptyView()
        } else {
            HStack(spacing: 0) {
                ForEach(clients) { client in
                    Button {
                        store.activeClient = client
                    } label: {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color(hex: client.color))
                                .frame(width: 7, height: 7)
                            Text(client.name)
                                .font(.sfPro(12, weight: .medium))
                                .foregroundStyle(
                                    store.activeClient?.id == client.id
                                        ? Color.ttInk
                                        : Color.ttInk2
                                )
                        }
                        .padding(.horizontal, 10)
                        .frame(height: 26)
                        .background(
                            store.activeClient?.id == client.id
                                ? Color.white.opacity(0.10)
                                : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(3)
            .background(Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 11)
                    .strokeBorder(Color.ttHairline, lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 11))
        }
    }
}
