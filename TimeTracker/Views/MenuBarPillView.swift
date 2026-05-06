import SwiftUI

struct MenuBarPillView: View {
    @Environment(TimerStore.self) private var store

    @State private var pulseOpacity: Double = 1
    @State private var pulseScale: CGFloat  = 1

    var body: some View {
        HStack(spacing: 8) {
            if store.runningSession != nil {
                runningContent
            } else {
                idleContent
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 22)
        .background(pillBackground)
        .overlay(pillBorder)
        .clipShape(RoundedRectangle(cornerRadius: 11))
        .animation(.easeInOut(duration: 0.15), value: store.runningSession != nil)
    }

    // MARK: Idle

    private var idleContent: some View {
        HStack(spacing: 6) {
            Image(systemName: "stopwatch")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.ttInk)
            Text("Tracker")
                .font(.sfPro(11.5))
                .foregroundStyle(Color.ttInk)
        }
    }

    // MARK: Running

    private var runningContent: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.ttLive)
                .frame(width: 7, height: 7)
                .shadow(color: Color.ttLive.opacity(0.7), radius: 4)
                .opacity(pulseOpacity)
                .scaleEffect(pulseScale)
                .onAppear { startPulse() }

            Text(store.elapsed.clockFormatted)
                .font(.sfMono(11.5, weight: .semibold))
                .foregroundStyle(Color.ttInk)
                .monospacedDigit()

            if let clientName = store.activeClient?.name.components(separatedBy: " ").first {
                Text(clientName)
                    .font(.sfPro(11))
                    .foregroundStyle(Color.ttInk2)
                    .lineLimit(1)
            }
        }
    }

    // MARK: Styling

    private var pillBackground: Color {
        store.runningSession != nil
            ? Color(red: 1, green: 0.416, blue: 0.302).opacity(0.16)
            : Color.white.opacity(0.08)
    }

    @ViewBuilder
    private var pillBorder: some View {
        RoundedRectangle(cornerRadius: 11)
            .strokeBorder(
                store.runningSession != nil
                    ? Color.ttLive.opacity(0.4)
                    : Color.ttHairline,
                lineWidth: 0.5
            )
    }

    // MARK: Pulse animation

    private func startPulse() {
        withAnimation(
            .easeInOut(duration: 1.6).repeatForever(autoreverses: true)
        ) {
            pulseOpacity = 0.55
            pulseScale   = 0.85
        }
    }
}
