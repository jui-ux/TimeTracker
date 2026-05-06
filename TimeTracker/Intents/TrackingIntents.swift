import AppIntents
import SwiftData

struct StartTrackingIntent: AppIntent {
    static let title: LocalizedStringResource = "Start Tracking"
    static let description = IntentDescription("Start a new time tracking session.")

    @Parameter(title: "Project Type", default: .untyped)
    var projectType: ProjectType

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let store = AppState.shared.store
        guard let client = store.activeClient else {
            return .result(dialog: "No active client selected.")
        }
        store.start(client: client, type: projectType)
        return .result(dialog: "Started tracking on \(client.name).")
    }
}

struct EndTrackingIntent: AppIntent {
    static let title: LocalizedStringResource = "End Tracking"
    static let description = IntentDescription("End the current time tracking session.")

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let store = AppState.shared.store
        guard store.runningSession != nil else {
            return .result(dialog: "No session is currently running.")
        }
        store.end()
        return .result(dialog: "Session ended.")
    }
}

struct TimeTrackerShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartTrackingIntent(),
            phrases: ["Start tracking on \(.applicationName)", "Begin tracking on \(.applicationName)"],
            shortTitle: "Start Tracking",
            systemImageName: "play.circle"
        )
        AppShortcut(
            intent: EndTrackingIntent(),
            phrases: ["Stop tracking on \(.applicationName)", "End tracking on \(.applicationName)"],
            shortTitle: "End Tracking",
            systemImageName: "stop.circle"
        )
    }
}

// Conform ProjectType to AppEnum so it can be an intent parameter
extension ProjectType: AppEnum {
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Project Type")
    }

    static var caseDisplayRepresentations: [ProjectType: DisplayRepresentation] {
        [
            .wireframe: DisplayRepresentation(title: "Wireframe"),
            .hiFi:      DisplayRepresentation(title: "Hi-Fi"),
            .research:  DisplayRepresentation(title: "Research"),
            .review:    DisplayRepresentation(title: "Review"),
            .untyped:   DisplayRepresentation(title: "Untyped"),
        ]
    }
}
