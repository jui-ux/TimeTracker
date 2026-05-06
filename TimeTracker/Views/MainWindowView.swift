import SwiftUI
import SwiftData
import AppKit
import UniformTypeIdentifiers

struct MainWindowView: View {
    @Environment(TimerStore.self)     private var store
    @Environment(\.modelContext)      private var context
    @Query(sort: \Session.startedAt, order: .reverse) private var allSessions: [Session]
    @Query(sort: \Client.sortOrder)  private var clients: [Client]

    @State private var searchText = ""
    @State private var typeFilter: ProjectType? = nil
    @State private var showSettings = false
    @State private var sessionToDelete: Session? = nil

    private var clientSessions: [Session] {
        guard let activeClient = store.activeClient else { return allSessions }
        return allSessions.filter { $0.client?.id == activeClient.id }
    }

    private var filteredSessions: [Session] {
        clientSessions.filter { session in
            let matchesSearch = searchText.isEmpty ||
                session.notes.localizedCaseInsensitiveContains(searchText)
            let matchesType = typeFilter == nil || session.projectType == typeFilter
            return matchesSearch && matchesType
        }
    }

    var body: some View {
        ZStack {
            Color(hex: "#111111")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                titleBar
                Divider().overlay(Color.ttHairline2)
                headerRow
                Divider().overlay(Color.ttHairline2)
                bodyContent
            }

            // Inline delete confirmation — never uses a system alert panel
            if let session = sessionToDelete {
                DeleteConfirmOverlay(
                    session: session,
                    onDelete: {
                        context.delete(session)
                        try? context.save()
                        sessionToDelete = nil
                    },
                    onCancel: { sessionToDelete = nil }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.97)))
                .zIndex(20)
            }
        }
        .frame(width: 760)
        .frame(minHeight: 500, maxHeight: .infinity)
        .background(Color(hex: "#111111"))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(Color.ttHairline, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.5), radius: 30, y: 10)
        .preferredColorScheme(.dark)
        .background(WindowAccessor())
        .onAppear { seedIfNeeded() }
    }

    // MARK: - Title bar

    private var titleBar: some View {
        HStack {
            Spacer()
            Text("TimeTracker")
                .font(.sfPro(13, weight: .semibold))
                .foregroundStyle(Color.ttInk)
            Spacer()
        }
        .padding(.vertical, 14)
        .overlay(alignment: .top) {
            Color.white.opacity(0.06).frame(height: 0.5)
        }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(spacing: 12) {
            ClientSwitcherView()
                .environment(store)

            Spacer()

            // Export button
            Button {
                ExportManager.exportToCSV(
                    sessions: clientSessions.filter { !$0.isRunning },
                    clientName: store.activeClient?.name
                )
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.ttInk2)
            }
            .buttonStyle(RoundIconButtonStyle(size: 32))
            .help("Export sessions to CSV")

            // Client manager (gear icon)
            Button { showSettings = true } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.ttInk2)
            }
            .buttonStyle(RoundIconButtonStyle(size: 32))
            .popover(isPresented: $showSettings, arrowEdge: .top) {
                ClientManagerView()
                    .environment(store)
                    .modelContainer(context.container)
                    .preferredColorScheme(.dark)
            }

            // Quit
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.ttInk2)
            }
            .buttonStyle(RoundIconButtonStyle(size: 32))
            .help("Quit TimeTracker")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Body

    @ViewBuilder
    private var bodyContent: some View {
        if clients.isEmpty {
            noClientsBody
        } else {
            normalBody
        }
    }

    private var noClientsBody: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 80, height: 80)
                    Image(systemName: "person.2")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(Color.ttInk3)
                }
                VStack(spacing: 6) {
                    Text("No clients yet")
                        .font(.sfPro(18, weight: .semibold))
                        .foregroundStyle(Color.ttInk)
                    Text("Add a client to start tracking\nyour design sessions.")
                        .font(.sfPro(13))
                        .foregroundStyle(Color.ttInk2)
                        .multilineTextAlignment(.center)
                }
                Button("Add your first client") {
                    showSettings = true
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var normalBody: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: []) {
                VStack(spacing: 0) {
                    // Hero card
                    Group {
                        if store.runningSession != nil {
                            RunningHeroCard(onEnd: { store.end() })
                        } else {
                            IdleHeroCard(
                                onStart: {
                                    guard let client = store.activeClient else { return }
                                    store.start(client: client, type: .untyped)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .animation(.easeInOut(duration: 0.25), value: store.runningSession != nil)

                    Spacer().frame(height: 22)

                    // Filter row
                    HStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.ttInk3)
                            TextField("Search notes…", text: $searchText)
                                .textFieldStyle(.plain)
                                .font(.sfPro(13))
                                .foregroundStyle(Color.ttInk)
                        }
                        .padding(.horizontal, 10)
                        .frame(height: 32)
                        .background(Color.white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 9)
                                .strokeBorder(Color.ttHairline, lineWidth: 0.5)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 9))

                        FilterPillsView(selected: $typeFilter)
                    }
                    .padding(.horizontal, 16)

                    Spacer().frame(height: 6)

                    // Sessions table
                    SessionsTableView(sessions: filteredSessions, onRequestDelete: { sessionToDelete = $0 })
                        .padding(.horizontal, 0)

                    // Month total
                    MonthTotalBar(sessions: clientSessions)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Seed

    private func seedIfNeeded() {
        // Clean up any zero-duration completed sessions left by previous test launches
        var didDelete = false
        for s in allSessions where !s.isRunning && s.durationSeconds == 0 {
            context.delete(s)
            didDelete = true
        }
        if didDelete { try? context.save() }

        // Normalize sortOrder for clients added before this field existed
        let needsOrder = clients.enumerated().filter { $0.offset > 0 && $0.element.sortOrder == 0 }
        if !needsOrder.isEmpty {
            for (index, client) in clients.enumerated() { client.sortOrder = index }
            try? context.save()
        }

        guard clients.isEmpty else { return }
        let acme = Client(name: "Acme Studio", color: "#e8e1d3", sortOrder: 0)
        let beta = Client(name: "Beta Labs",   color: "#a3c4ff", sortOrder: 1)
        context.insert(acme)
        context.insert(beta)
        store.activeClient = acme

        // Seed sample sessions
        let cal = Calendar.current
        func daysAgo(_ n: Int, hour: Int, minute: Int) -> Date {
            var comps        = cal.dateComponents([.year, .month, .day], from: .now)
            comps.day        = (comps.day ?? 0) - n
            comps.hour       = hour
            comps.minute     = minute
            return cal.date(from: comps) ?? .now
        }

        let samples: [(Int, Int, Int, Int, ProjectType, String)] = [
            // (daysAgo, hour, minute, durationSec, type, notes)
            (7, 9, 12,  134*60, .wireframe, "Onboarding flow sketches"),
            (7, 13, 40, 108*60, .hiFi,      "Dashboard revisions"),
            (6, 10, 5,  182*60, .research,  "User interview — N. Patel"),
            (5, 9, 30,  165*60, .hiFi,      "Settings screens"),
            (4, 14, 12,  80*60, .review,    "Eng sync"),
            (14, 9, 45, 150*60, .wireframe, "Settings IA"),
            (13, 10, 15,130*60, .untyped,   ""),
            (11, 13, 0, 220*60, .hiFi,      "Pricing page"),
        ]

        for (ago, h, m, dur, type, notes) in samples {
            let start = daysAgo(ago, hour: h, minute: m)
            let s     = Session(startedAt: start, type: type, notes: notes, client: acme)
            s.endedAt         = start.addingTimeInterval(TimeInterval(dur))
            s.durationSeconds = dur
            context.insert(s)
        }

        try? context.save()
    }

    private var maxWindowHeight: CGFloat {
        (NSScreen.main?.visibleFrame.height ?? 900) - 130
    }
}

// MARK: - Inline delete confirmation overlay

private struct DeleteConfirmOverlay: View {
    let session: Session
    let onDelete: () -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { onCancel() }

            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text("Delete this session?")
                        .font(.sfPro(16, weight: .semibold))
                        .foregroundStyle(Color.ttInk)
                    Text("This action cannot be undone.")
                        .font(.sfPro(13))
                        .foregroundStyle(Color.ttInk2)
                }

                HStack(spacing: 10) {
                    Button("Cancel", action: onCancel)
                        .buttonStyle(GhostButtonStyle())
                    Button("Delete", action: onDelete)
                        .buttonStyle(DestructiveButtonStyle())
                }
            }
            .padding(28)
            .background(Color(hex: "#1e1a16"))
            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color.ttHairline, lineWidth: 0.5))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: .black.opacity(0.6), radius: 30)
            .frame(width: 320)
        }
    }
}

// Forces the containing NSWindow to be fully opaque with a solid dark background,
// preventing MenuBarExtra vibrancy from washing out our colors.
// Also makes the window vertically resizable by dragging the bottom edge.
private struct WindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.backgroundColor = NSColor(white: 0.067, alpha: 1)
            window.isOpaque = true
            window.appearance = NSAppearance(named: .darkAqua)
            window.styleMask.insert(.resizable)
            window.showsResizeIndicator = false
            let maxH = (NSScreen.main?.visibleFrame.height ?? 900) - 130
            window.minSize = NSSize(width: 760, height: 500)
            window.maxSize = NSSize(width: 760, height: maxH)
        }
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}

// MARK: - Export

@MainActor
private struct ExportManager {
    static func exportToCSV(sessions: [Session], clientName: String?) {
        let panel = NSSavePanel()
        panel.title = "Export Sessions"
        panel.nameFieldStringValue = defaultFileName(clientName: clientName)
        if let csvType = UTType(filenameExtension: "csv") {
            panel.allowedContentTypes = [csvType]
        }
        panel.canCreateDirectories = true

        let csv = buildCSV(sessions: sessions)

        // .popUpMenu sits above the MenuBarExtra window, and begin(completionHandler:)
        // is non-attached so it won't dismiss when the tracker panel loses focus.
        panel.level = .popUpMenu
        NSApp.activate(ignoringOtherApps: true)
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            try? csv.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    private static func defaultFileName(clientName: String?) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let date = df.string(from: .now)
        return clientName.map { "\($0) Sessions \(date).csv" } ?? "All Sessions \(date).csv"
    }

    private static func buildCSV(sessions: [Session]) -> String {
        let dateFmt = DateFormatter()
        dateFmt.dateFormat = "yyyy-MM-dd"
        let timeFmt = DateFormatter()
        timeFmt.dateFormat = "HH:mm"
        let monthFmt = DateFormatter()
        monthFmt.dateFormat = "MMMM yyyy"
        let cal = Calendar.current

        let sorted = sessions.sorted(by: { $0.startedAt < $1.startedAt })
        let grouped = Dictionary(grouping: sorted) { s -> Date in
            let comps = cal.dateComponents([.year, .month], from: s.startedAt)
            return cal.date(from: comps)!
        }
        let months = grouped.keys.sorted()

        var rows = ["Client,Date,Start,End,Duration (h),Type,Notes"]
        for month in months {
            let monthSessions = grouped[month]!
            for s in monthSessions {
                let hours = String(format: "%.2f", Double(s.durationSeconds) / 3600.0)
                let type  = s.projectType == .untyped ? "" : s.projectType.rawValue
                rows.append([
                    escape(s.client?.name ?? ""),
                    dateFmt.string(from: s.startedAt),
                    timeFmt.string(from: s.startedAt),
                    s.endedAt.map { timeFmt.string(from: $0) } ?? "",
                    hours,
                    type,
                    escape(s.notes)
                ].joined(separator: ","))
            }
            let totalHours = Double(monthSessions.reduce(0) { $0 + $1.durationSeconds }) / 3600.0
            rows.append("\(monthFmt.string(from: month)) Total,,,,\(String(format: "%.2f", totalHours)),,")
            rows.append("")
        }
        return rows.joined(separator: "\n")
    }

    private static func escape(_ value: String) -> String {
        guard value.contains(",") || value.contains("\"") || value.contains("\n") else { return value }
        return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}

private struct DestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.sfPro(13.5, weight: .semibold))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 16)
            .frame(height: 36)
            .background(Color(hex: "#ff6a4d").opacity(configuration.isPressed ? 0.8 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
