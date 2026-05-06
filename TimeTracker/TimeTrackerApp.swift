import SwiftUI
import SwiftData
import CoreData
import KeyboardShortcuts

// MARK: - Global hotkey name

extension KeyboardShortcuts.Name {
    static let toggleSession = Self("toggleSession", default: .init(.t, modifiers: [.option, .command]))
}

// MARK: - App-wide singleton needed by App Intents (called outside SwiftUI scope)

@MainActor
final class AppState {
    static let shared = AppState()
    let store = TimerStore()
    private init() {}
}

// MARK: - Entry point

@main
struct TimeTrackerApp: App {
    private static func makeContainer() -> ModelContainer {
        let schema = Schema([Client.self, Session.self])
        let config = ModelConfiguration(schema: schema)

        func wipeStore() {
            let base = config.url.path
            for suffix in ["", "-wal", "-shm"] {
                try? FileManager.default.removeItem(atPath: base + suffix)
            }
        }

        // First attempt
        do {
            let container = try ModelContainer(for: schema, configurations: config)
            // Force-load the store synchronously so migration errors surface here,
            // not silently later when the app is already running.
            _ = container.mainContext
            return container
        } catch {
            // Schema changed or store corrupt — wipe and recreate.
            wipeStore()
        }

        // Second attempt on clean store
        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("SwiftData container failed after reset: \(error)")
        }
    }

    // Stored directly so App.body can observe changes via @Observable
    private let store: TimerStore = AppState.shared.store
    private let modelContainer: ModelContainer

    init() {
        modelContainer = Self.makeContainer()

        // Deferred: NSApp is nil during App.init() — SwiftUI sets it up after init returns.
        DispatchQueue.main.async {
            NSApp.appearance = NSAppearance(named: .darkAqua)
        }

        let container = modelContainer
        Task { @MainActor in
            AppState.shared.store.configure(context: container.mainContext)
            if AppState.shared.store.activeClient == nil {
                let descriptor = FetchDescriptor<Client>(sortBy: [SortDescriptor(\.sortOrder)])
                AppState.shared.store.activeClient = try? container.mainContext.fetch(descriptor).first
            }
        }

        KeyboardShortcuts.onKeyUp(for: .toggleSession) {
            Task { @MainActor in
                let s = AppState.shared.store
                if s.runningSession != nil { s.end() }
                else if let c = s.activeClient { s.start(client: c, type: .untyped) }
            }
        }
    }

    var body: some Scene {
        MenuBarExtra {
            MainWindowView()
                .environment(store)
                .modelContainer(modelContainer)
                .preferredColorScheme(.dark)
        } label: {
            // Inline label — App.body IS observed by @Observable, so this updates live
            PillLabel(store: store)
        }
        .menuBarExtraStyle(.window)

        Window("TimeTracker", id: "main") {
            MainWindowView()
                .environment(store)
                .modelContainer(modelContainer)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Session") {
                    Task { @MainActor in
                        let s = AppState.shared.store
                        if let c = s.activeClient { s.start(client: c, type: .untyped) }
                    }
                }
                .keyboardShortcut("n", modifiers: .command)
                Button("End Session") {
                    Task { @MainActor in AppState.shared.store.end() }
                }
                .keyboardShortcut(".", modifiers: .command)
            }
        }
    }
}

// MARK: - Menu-bar pill label
// Separate View so its body is properly tracked by SwiftUI's @Observable machinery.

private struct PillLabel: View {
    let store: TimerStore

    @State private var pulseOpacity: Double = 1
    @State private var pulseScale:   CGFloat = 1

    var body: some View {
        HStack(spacing: 8) {
            if store.runningSession != nil {
                Circle()
                    .fill(Color(red: 1, green: 0.416, blue: 0.302))
                    .frame(width: 7, height: 7)
                    .opacity(pulseOpacity)
                    .scaleEffect(pulseScale)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                            pulseOpacity = 0.55
                            pulseScale   = 0.85
                        }
                    }

                Text(store.elapsed.clockFormatted)
                    .font(.system(size: 11.5, weight: .semibold, design: .monospaced))
                    .monospacedDigit()

                if let name = store.activeClient?.name.components(separatedBy: " ").first {
                    Text(name)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            } else {
                Image(systemName: "stopwatch")
                    .font(.system(size: 11, weight: .medium))
                Text("Tracker")
                    .font(.system(size: 11.5))
            }
        }
        .padding(.horizontal, 8)
    }
}
