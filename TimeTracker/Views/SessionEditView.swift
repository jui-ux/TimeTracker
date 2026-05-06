import SwiftUI
import SwiftData

struct SessionEditView: View {
    @Bindable var session: Session
    var onRequestDelete: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    // Local edit state — committed only on "Save"
    @State private var startedAt: Date
    @State private var endedAt: Date
    @State private var selectedType: ProjectType
    @State private var notes: String

    init(session: Session, onRequestDelete: (() -> Void)? = nil) {
        self.session = session
        self.onRequestDelete = onRequestDelete
        _startedAt    = State(initialValue: session.startedAt)
        _endedAt      = State(initialValue: session.endedAt ?? Date.now)
        _selectedType = State(initialValue: session.projectType)
        _notes        = State(initialValue: session.notes)
    }

    private var computedDuration: Int {
        max(0, Int(endedAt.timeIntervalSince(startedAt)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Header ──
            HStack {
                Text("Edit Session")
                    .font(.sfPro(15, weight: .semibold))
                    .foregroundStyle(Color.ttInk)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.ttInk3)
                        .frame(width: 24, height: 24)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(16)

            Divider().overlay(Color.ttHairline2)

            // ── Fields ──
            VStack(alignment: .leading, spacing: 16) {

                // Start time
                fieldRow(label: "Start") {
                    DatePicker("", selection: $startedAt, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .onChange(of: startedAt) {
                            // Keep end ≥ start
                            if endedAt < startedAt { endedAt = startedAt }
                        }
                }

                // End time
                fieldRow(label: "End") {
                    DatePicker("", selection: $endedAt, in: startedAt..., displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                        .datePickerStyle(.compact)
                }

                // Computed duration preview
                fieldRow(label: "Duration") {
                    Text(computedDuration.durationFormatted)
                        .font(.sfMono(13, weight: .semibold))
                        .foregroundStyle(Color.ttInk)
                        .monospacedDigit()
                }

                // Type
                fieldRow(label: "Type") {
                    Menu {
                        ForEach(ProjectType.allCases, id: \.self) { type in
                            Button {
                                selectedType = type
                            } label: {
                                HStack {
                                    Text(type.rawValue)
                                    if selectedType == type { Image(systemName: "checkmark") }
                                }
                            }
                        }
                    } label: {
                        TypeChipView(type: selectedType, size: .large)
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                }

                // Notes
                fieldRow(label: "Notes") {
                    TextField("Add notes…", text: $notes, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(.sfPro(13))
                        .foregroundStyle(Color.ttInk)
                        .lineLimit(3, reservesSpace: true)
                        .padding(8)
                        .background(Color.white.opacity(0.05))
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.ttHairline, lineWidth: 0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(16)

            Divider().overlay(Color.ttHairline2)

            // ── Actions ──
            HStack(spacing: 8) {
                // Delete
                Button {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        onRequestDelete?()
                    }
                } label: {
                    Label("Delete", systemImage: "trash")
                        .font(.sfPro(12, weight: .medium))
                        .foregroundStyle(Color(hex: "#ff6a4d"))
                        .padding(.horizontal, 12)
                        .frame(height: 32)
                        .background(Color(hex: "#ff6a4d").opacity(0.10))
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color(hex: "#ff6a4d").opacity(0.25), lineWidth: 0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)

                Spacer()

                Button("Cancel") { dismiss() }
                    .buttonStyle(GhostButtonStyle())

                Button("Save") { save() }
                    .buttonStyle(PrimaryButtonStyle())
            }
            .padding(16)
        }
        .frame(width: 380)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.ttHairline, lineWidth: 0.5))
        .shadow(color: .black.opacity(0.4), radius: 20)
    }

    // MARK: - Row layout helper

    @ViewBuilder
    private func fieldRow<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .center, spacing: 0) {
            Text(label)
                .font(.sfPro(12, weight: .medium))
                .foregroundStyle(Color.ttInk3)
                .frame(width: 72, alignment: .leading)
            content()
        }
    }

    // MARK: - Save

    private func save() {
        session.startedAt       = startedAt
        session.endedAt         = endedAt
        session.durationSeconds = computedDuration
        session.projectType     = selectedType
        session.notes           = notes
        try? context.save()
        dismiss()
    }
}
