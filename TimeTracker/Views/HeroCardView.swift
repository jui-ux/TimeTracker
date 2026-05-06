import SwiftUI

// MARK: - Idle hero card

struct IdleHeroCard: View {
    @Environment(TimerStore.self) private var store
    var onStart: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 48, height: 48)
                Image(systemName: "stopwatch")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(Color.ttInk2)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Ready to track")
                    .font(.sfPro(15, weight: .semibold))
                    .foregroundStyle(Color.ttInk)
                HStack(spacing: 0) {
                    Text("on ")
                        .font(.sfPro(12))
                        .foregroundStyle(Color.ttInk2)
                    Text(store.activeClient?.name ?? "…")
                        .font(.sfPro(12, weight: .semibold))
                        .foregroundStyle(Color.ttInk)
                }
            }

            Spacer()

            Button(action: onStart) {
                Text("Start")
                    .font(.sfPro(13.5, weight: .semibold))
                    .foregroundStyle(Color.ttAccentInk)
                    .padding(.horizontal, 16)
                    .frame(height: 32)
                    .background(Color.ttAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .keyboardShortcut("n", modifiers: .command)
        }
        .padding(20)
        .background(Color.white.opacity(0.04))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.ttHairline, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Running hero card

struct RunningHeroCard: View {
    @Environment(TimerStore.self) private var store
    @State private var showTypePicker = false
    @State private var selectedType: ProjectType = .untyped
    var onEnd: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RadialGradient(
                colors: [Color.ttLive.opacity(0.30), .clear],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 180
            )
            .frame(width: 180, height: 180)
            .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    PulseDot()
                    Text(store.isPaused ? "PAUSED" : "RECORDING")
                        .font(.sfPro(11, weight: .semibold))
                        .foregroundStyle(store.isPaused ? Color.ttInk3 : Color.ttLive)
                        .kerning(0.4)
                    Spacer()
                    if let session = store.runningSession {
                        let startStr = session.startedAt.formatted(date: .omitted, time: .shortened)
                        Text("Started \(startStr) · \(session.client?.name ?? "")")
                            .font(.sfPro(11.5))
                            .foregroundStyle(Color.ttInk2)
                    }
                }

                Text(store.elapsed.clockFormatted)
                    .font(.sfMono(56, weight: .bold))
                    .foregroundStyle(Color.ttInk)
                    .monospacedDigit()
                    .kerning(-2)

                HStack(spacing: 10) {
                    Button {
                        if let t = store.runningSession?.projectType { selectedType = t }
                        showTypePicker = true
                    } label: {
                        TypeChipView(type: store.runningSession?.projectType ?? .untyped, size: .large)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showTypePicker, arrowEdge: .bottom) {
                        TypePickerPopover(selectedType: $selectedType) { t in
                            store.runningSession?.projectType = t
                        }
                        .preferredColorScheme(.dark)
                    }

                    Spacer()

                    Button {
                        store.isPaused ? store.resume() : store.pause()
                    } label: {
                        Text(store.isPaused ? "Resume" : "Pause")
                            .font(.sfPro(13, weight: .medium))
                            .foregroundStyle(Color.ttInk2)
                            .padding(.horizontal, 14)
                            .frame(height: 30)
                            .background(Color.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(Color.ttHairline, lineWidth: 0.5)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)

                    Button(action: onEnd) {
                        Text("End session")
                            .font(.sfPro(13.5, weight: .semibold))
                            .foregroundStyle(Color.ttAccentInk)
                            .padding(.horizontal, 16)
                            .frame(height: 32)
                            .background(Color.ttAccent)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(".", modifiers: .command)
                }
            }
            .padding(20)
        }
        .background(
            LinearGradient(
                colors: [Color.ttLive.opacity(0.18), Color.ttLive.opacity(0.04)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.ttLive.opacity(0.32), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Pulse dot

struct PulseDot: View {
    @State private var opacity: Double = 1
    @State private var scale: CGFloat = 1

    var body: some View {
        Circle()
            .fill(Color.ttLive)
            .frame(width: 8, height: 8)
            .opacity(opacity)
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                    opacity = 0.55
                    scale   = 0.85
                }
            }
    }
}

// MARK: - Type picker popover

private struct TypePickerPopover: View {
    @Binding var selectedType: ProjectType
    var onSelect: (ProjectType) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(ProjectType.allCases, id: \.self) { type in
                Button {
                    selectedType = type
                    onSelect(type)
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        TypeChipView(type: type)
                        Spacer()
                        if selectedType == type {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color.ttInk2)
                        }
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 32)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 6)
        .frame(width: 180)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Round icon button style

struct RoundIconButtonStyle: ButtonStyle {
    var size: CGFloat = 32

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: size, height: size)
            .background(Color.white.opacity(configuration.isPressed ? 0.10 : 0.06))
            .overlay(Circle().strokeBorder(Color.ttHairline, lineWidth: 0.5))
            .clipShape(Circle())
            .contentShape(Circle())
    }
}
