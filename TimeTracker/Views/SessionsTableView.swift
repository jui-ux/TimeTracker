import SwiftUI
import SwiftData

// MARK: - Week grouping helpers

private struct WeekGroup: Identifiable {
    let id: String          // ISO week key
    let label: String
    let range: String
    let sessions: [Session]

    var totalSeconds: Int { sessions.reduce(0) { $0 + effectiveDuration($1) } }

    private func effectiveDuration(_ s: Session) -> Int {
        if s.isRunning { return 0 }
        return s.durationSeconds
    }
}

private func weekGroups(from sessions: [Session]) -> [WeekGroup] {
    let cal = Calendar.current
    var buckets: [(key: String, sessions: [Session])] = []
    var map: [String: Int] = [:]

    for s in sessions {
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: s.startedAt)
        let key   = "\(comps.yearForWeekOfYear ?? 0)-\(String(format: "%02d", comps.weekOfYear ?? 0))"
        if let idx = map[key] {
            buckets[idx].sessions.append(s)
        } else {
            map[key] = buckets.count
            buckets.append((key: key, sessions: [s]))
        }
    }

    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d"

    return buckets.map { bucket in
        let dates  = bucket.sessions.map(\.startedAt).sorted()
        let first  = dates.first ?? .now
        let last   = dates.last  ?? .now
        let today  = cal.startOfDay(for: .now)
        let weekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: first))!
        let isThisWeek = cal.isDate(weekStart, equalTo: today, toGranularity: .weekOfYear)
        let isLastWeek = cal.isDate(weekStart, equalTo: cal.date(byAdding: .weekOfYear, value: -1, to: today)!, toGranularity: .weekOfYear)
        let label  = isThisWeek ? "This week" : isLastWeek ? "Last week" : formatter.string(from: weekStart) + " week"
        let range  = first == last ? formatter.string(from: first) : "\(formatter.string(from: first)) – \(formatter.string(from: last))"
        return WeekGroup(id: bucket.key, label: label, range: range, sessions: bucket.sessions)
    }
}

// MARK: - Main sessions table

struct SessionsTableView: View {
    let sessions: [Session]
    var onRequestDelete: (Session) -> Void
    @State private var collapsedWeeks: Set<String> = []
    @State private var sortAscending = false

    private var sorted: [Session] {
        sessions.sorted {
            sortAscending
                ? $0.startedAt < $1.startedAt
                : $0.startedAt > $1.startedAt
        }
    }

    private var groups: [WeekGroup] { weekGroups(from: sorted) }

    var body: some View {
        VStack(spacing: 0) {
            columnHeaders
            Divider().overlay(Color.ttHairline2)

            ForEach(groups) { group in
                WeekGroupSection(
                    group: group,
                    isCollapsed: collapsedWeeks.contains(group.id),
                    onRequestDelete: onRequestDelete
                ) {
                    if collapsedWeeks.contains(group.id) {
                        collapsedWeeks.remove(group.id)
                    } else {
                        collapsedWeeks.insert(group.id)
                    }
                }
            }
        }
    }

    private var columnHeaders: some View {
        HStack(spacing: 0) {
            Button {
                sortAscending.toggle()
            } label: {
                HStack(spacing: 4) {
                    Text("DATE")
                        .font(.sfPro(10.5, weight: .semibold))
                        .kerning(0.6)
                    Image(systemName: sortAscending ? "arrow.up" : "arrow.down")
                        .font(.system(size: 9, weight: .semibold))
                }
                .foregroundStyle(Color.ttInk3)
            }
            .buttonStyle(.plain)
            .frame(width: 120, alignment: .leading)

            headerCell("START",    width: 70)
            headerCell("DURATION", width: 80)
            headerCell("TYPE",     width: 130)
            headerCell("NOTES")

            Spacer().frame(width: 28)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private func headerCell(_ title: String, width: CGFloat? = nil) -> some View {
        let label = Text(title)
            .font(.sfPro(10.5, weight: .semibold))
            .kerning(0.6)
            .foregroundStyle(Color.ttInk3)
        if let w = width {
            label.frame(width: w, alignment: .leading)
        } else {
            label.frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Week section

private struct WeekGroupSection: View {
    let group: WeekGroup
    let isCollapsed: Bool
    let onRequestDelete: (Session) -> Void
    let onToggle: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Week header
            Button(action: onToggle) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Color.ttInk3)
                        .rotationEffect(.degrees(isCollapsed ? 0 : 90))
                        .animation(.easeInOut(duration: 0.15), value: isCollapsed)

                    Text(group.label)
                        .font(.sfPro(13, weight: .semibold))
                        .foregroundStyle(Color.ttInk)

                    Text(group.range)
                        .font(.sfPro(12))
                        .foregroundStyle(Color.ttInk3)

                    Spacer()

                    Text("\(group.sessions.count) session\(group.sessions.count == 1 ? "" : "s")")
                        .font(.sfPro(11.5))
                        .foregroundStyle(Color.ttInk3)

                    Text(group.totalSeconds.durationFormatted)
                        .font(.sfMono(12, weight: .semibold))
                        .foregroundStyle(Color.ttInk2)
                        .monospacedDigit()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)

            if !isCollapsed {
                VStack(spacing: 0) {
                    ForEach(group.sessions) { session in
                        SessionRowView(session: session, onRequestDelete: { onRequestDelete(session) })
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // Week subtotal
                    HStack {
                        Spacer()
                        Text("WEEK TOTAL · \(group.totalSeconds.durationFormatted)")
                            .font(.sfMono(10.5, weight: .semibold))
                            .kerning(0.4)
                            .foregroundStyle(Color.ttInk3)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                    }
                    Divider().overlay(Color.ttHairline2)
                }
                .animation(.easeInOut(duration: 0.15), value: isCollapsed)
            }
        }
    }
}

// MARK: - Session row

struct SessionRowView: View {
    @Bindable var session: Session
    var onRequestDelete: () -> Void
    @State private var isHovered      = false
    @State private var showTypePicker = false
    @State private var showEditSheet  = false
    @Environment(\.modelContext) private var context

    var body: some View {
        HStack(spacing: 0) {
            // Date
            Text(session.startedAt.formatted(Date.FormatStyle().weekday(.abbreviated).month(.abbreviated).day(.twoDigits)))
                .font(.sfPro(13, weight: .medium))
                .foregroundStyle(Color.ttInk)
                .frame(width: 120, alignment: .leading)

            // Start time
            Text(session.startedAt.formatted(date: .omitted, time: .shortened))
                .font(.sfMono(12))
                .foregroundStyle(Color.ttInk2)
                .monospacedDigit()
                .frame(width: 70, alignment: .leading)

            // Duration
            Text(session.isRunning ? "—" : session.durationSeconds.durationFormatted)
                .font(.sfMono(13, weight: .semibold))
                .foregroundStyle(Color.ttInk)
                .monospacedDigit()
                .frame(width: 80, alignment: .leading)

            // Type chip
            Button { showTypePicker = true } label: {
                TypeChipView(type: session.projectType)
            }
            .buttonStyle(.plain)
            .frame(width: 130, alignment: .leading)
            .popover(isPresented: $showTypePicker, arrowEdge: .bottom) {
                TypePickerInline(session: session)
                    .preferredColorScheme(.dark)
            }

            // Notes (inline editable)
            TextField("click to add notes…", text: $session.notes)
                .font(.sfPro(13))
                .foregroundStyle(Color.ttInk)
                .textFieldStyle(.plain)
                .frame(maxWidth: .infinity)

            // Overflow ⋯
            Button {
                showEditSheet = true
            } label: {
                Text("⋯")
                    .font(.system(size: 14))
                    .foregroundStyle(isHovered ? Color.ttInk2 : Color.ttInk3)
                    .frame(width: 28, alignment: .center)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(isHovered ? Color.white.opacity(0.03) : Color.clear)
        .overlay(alignment: .top) { Divider().overlay(Color.ttHairline2) }
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.12), value: isHovered)
        .contextMenu { rowContextMenu }
        .popover(isPresented: $showEditSheet, arrowEdge: .trailing) {
            SessionEditView(session: session, onRequestDelete: onRequestDelete)
                .environment(\.modelContext, context)
                .preferredColorScheme(.dark)
        }
    }

    @ViewBuilder
    private var rowContextMenu: some View {
        Button("Edit…") { showEditSheet = true }
        Divider()
        Button("Duplicate") {
            guard let client = session.client else { return }
            let copy = Session(
                startedAt: session.startedAt,
                type: session.projectType,
                notes: session.notes,
                client: client
            )
            copy.endedAt         = session.endedAt
            copy.durationSeconds = session.durationSeconds
            context.insert(copy)
            try? context.save()
        }
        Divider()
        Button("Delete", role: .destructive) { onRequestDelete() }
    }
}

// MARK: - Inline type picker

private struct TypePickerInline: View {
    @Bindable var session: Session
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(ProjectType.allCases, id: \.self) { type in
                Button {
                    session.projectType = type
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        TypeChipView(type: type)
                        Spacer()
                        if session.projectType == type {
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

// MARK: - Month total bar

struct MonthTotalBar: View {
    let sessions: [Session]

    private var monthTotal: Int {
        let cal = Calendar.current
        let now = Date.now
        return sessions
            .filter { cal.isDate($0.startedAt, equalTo: now, toGranularity: .month) && !$0.isRunning }
            .reduce(0) { $0 + $1.durationSeconds }
    }

    private var monthLabel: String {
        Date.now.formatted(.dateTime.month(.wide).year()).uppercased()
    }

    private let barColors: [Color] = [Color(hex: "#e8e1d3"), Color(hex: "#c9bfac")]
    private let inkColor: Color = Color(hex: "#1a1612")

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(monthLabel)
                    .font(.sfPro(10.5, weight: .semibold))
                    .foregroundStyle(inkColor.opacity(0.7))
                    .kerning(0.4)
                Text("Total tracked")
                    .font(.sfPro(13, weight: .semibold))
                    .foregroundStyle(inkColor.opacity(0.85))
            }
            Spacer()
            Text(monthTotal.durationFormatted)
                .font(.sfMono(32, weight: .bold))
                .foregroundStyle(inkColor)
                .monospacedDigit()
                .kerning(-1)
        }
        .padding(16)
        .background(
            LinearGradient(colors: barColors, startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
