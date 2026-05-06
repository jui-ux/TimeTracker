import SwiftUI
import SwiftData

// MARK: - Preset palette for client colors

private let colorPalette: [String] = [
    "#e8e1d3", "#a3c4ff", "#bfe6c9", "#f3c27a", "#ff6a4d",
    "#c9a3ff", "#ffa3c4", "#a3ffd6", "#ffd6a3", "#a3d6ff",
]

// MARK: - Client Manager Sheet

struct ClientManagerView: View {
    @Environment(\.modelContext) private var context
    @Environment(TimerStore.self) private var store
    @Query(sort: \Client.sortOrder) private var clients: [Client]

    @State private var addingNew        = false
    @State private var newName          = ""
    @State private var newColor         = colorPalette[0]
    @State private var confirmDelete: Client? = nil
    @State private var draggingID: UUID? = nil
    @FocusState private var newFieldFocused: Bool

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Text("Clients")
                        .font(.sfPro(15, weight: .semibold))
                        .foregroundStyle(Color.ttInk)
                    Spacer()
                    Button {
                        addingNew       = true
                        newName         = ""
                        newColor        = colorPalette[0]
                        newFieldFocused = true
                    } label: {
                        Label("Add client", systemImage: "plus")
                            .font(.sfPro(12, weight: .semibold))
                            .foregroundStyle(Color.ttInk)
                            .padding(.horizontal, 10)
                            .frame(height: 26)
                            .background(Color.white.opacity(0.12))
                            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.white.opacity(0.18), lineWidth: 0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 10)

                Divider().overlay(Color.ttHairline2)

                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 0) {
                            if clients.isEmpty && !addingNew {
                                emptyClientsState
                            } else {
                                ForEach(clients) { client in
                                    ClientRow(
                                        client: client,
                                        isActive: store.activeClient?.id == client.id,
                                        sessionCount: client.sessions.count,
                                        onActivate: { store.activeClient = client },
                                        onDelete: { confirmDelete = client },
                                        onDragStart: { draggingID = client.id }
                                    )
                                    .opacity(draggingID == client.id ? 0.4 : 1)
                                    .onDrop(of: [.text], isTargeted: nil) { _ in
                                        guard let fromID = draggingID,
                                              fromID != client.id,
                                              let fromIdx = clients.firstIndex(where: { $0.id == fromID }),
                                              let toIdx   = clients.firstIndex(where: { $0.id == client.id })
                                        else { return false }
                                        var reordered = clients
                                        reordered.move(fromOffsets: IndexSet(integer: fromIdx),
                                                       toOffset: toIdx > fromIdx ? toIdx + 1 : toIdx)
                                        for (i, c) in reordered.enumerated() { c.sortOrder = i }
                                        try? context.save()
                                        draggingID = nil
                                        return true
                                    }
                                    Divider().overlay(Color.ttHairline2).padding(.leading, 44)
                                }

                                if addingNew {
                                    addNewRow
                                        .id("addNewRow")
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 320)
                    .onChange(of: addingNew) { _, isAdding in
                        if isAdding {
                            withAnimation { proxy.scrollTo("addNewRow", anchor: .bottom) }
                        }
                    }
                }
            }

            // Inline delete confirmation — no system alert panel
            if let client = confirmDelete {
                ZStack {
                    Color.black.opacity(0.55)
                        .onTapGesture { confirmDelete = nil }

                    VStack(spacing: 20) {
                        VStack(spacing: 6) {
                            Text("Delete \"\(client.name)\"?")
                                .font(.sfPro(16, weight: .semibold))
                                .foregroundStyle(Color.ttInk)
                            if client.sessions.count > 0 {
                                Text("This will also permanently delete \(client.sessions.count) recorded session\(client.sessions.count == 1 ? "" : "s").")
                                    .font(.sfPro(13))
                                    .foregroundStyle(Color.ttInk2)
                                    .multilineTextAlignment(.center)
                            }
                        }

                        VStack(spacing: 8) {
                            Button {
                                deleteClient(client)
                            } label: {
                                Text(client.sessions.count > 0
                                     ? "Delete client and \(client.sessions.count) session\(client.sessions.count == 1 ? "" : "s")"
                                     : "Delete client")
                                    .font(.sfPro(13.5, weight: .semibold))
                                    .foregroundStyle(Color.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 36)
                                    .background(Color(hex: "#ff6a4d"))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)

                            Button("Cancel") { confirmDelete = nil }
                                .buttonStyle(GhostButtonStyle())
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(24)
                    .background(Color(hex: "#1e1a16"))
                    .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.ttHairline, lineWidth: 0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(16)
                }
            }
        }
        .frame(width: 360)
        .background(Color(hex: "#111111"))
        .onAppear {
            if clients.isEmpty {
                addingNew = true
                DispatchQueue.main.async { newFieldFocused = true }
            }
        }
    }

    // MARK: - Empty state

    private var emptyClientsState: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 56, height: 56)
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(Color.ttInk3)
            }
            VStack(spacing: 4) {
                Text("No clients yet")
                    .font(.sfPro(14, weight: .semibold))
                    .foregroundStyle(Color.ttInk)
                Text("Add your first client to start\ntracking time.")
                    .font(.sfPro(12))
                    .foregroundStyle(Color.ttInk2)
                    .multilineTextAlignment(.center)
            }
            Button("Add client") {
                addingNew       = true
                newName         = ""
                newColor        = colorPalette[0]
                newFieldFocused = true
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Add new row

    private var addNewRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Row 1: color palette
            ColorDotPicker(selected: $newColor)

            // Row 2: name field + actions
            HStack(spacing: 8) {
                TextField("Client name", text: $newName)
                    .textFieldStyle(.plain)
                    .font(.sfPro(13))
                    .foregroundStyle(Color.ttInk)
                    .focused($newFieldFocused)
                    .onSubmit { commitNew() }
                    .padding(.horizontal, 10)
                    .frame(height: 32)
                    .background(Color.white.opacity(0.06))
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.ttHairline, lineWidth: 0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Button("Add client") { commitNew() }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)

                Button { addingNew = false } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.ttInk2)
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.04))
        .overlay(alignment: .top) { Color.ttHairline2.frame(height: 0.5) }
        .overlay(alignment: .bottom) { Color.ttHairline2.frame(height: 0.5) }
    }

    private func commitNew() {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let client = Client(name: trimmed, color: newColor, sortOrder: clients.count)
        context.insert(client)
        try? context.save()
        if store.activeClient == nil { store.activeClient = client }
        addingNew = false
    }


    private func deleteClient(_ client: Client) {
        if store.activeClient?.id == client.id {
            store.activeClient = clients.first(where: { $0.id != client.id })
        }
        if store.runningSession?.client?.id == client.id {
            store.end()
        }
        context.delete(client)
        try? context.save()
        confirmDelete = nil
    }
}

// MARK: - Individual client row (supports rename in-place)

private struct ClientRow: View {
    @Bindable var client: Client
    let isActive: Bool
    let sessionCount: Int
    let onActivate: () -> Void
    let onDelete: () -> Void
    let onDragStart: () -> Void

    @State private var isEditing = false
    @State private var editName  = ""
    @State private var editColor = ""
    @FocusState private var fieldFocused: Bool

    var body: some View {
        if isEditing {
            editingBody
        } else {
            normalBody
        }
    }

    // MARK: - Edit mode (stacked layout)

    private var editingBody: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Row 1: color palette
            ColorDotPicker(selected: $editColor)

            // Row 2: name field + actions
            HStack(spacing: 8) {
                TextField("Client name", text: $editName)
                    .textFieldStyle(.plain)
                    .font(.sfPro(13))
                    .foregroundStyle(Color.ttInk)
                    .focused($fieldFocused)
                    .onSubmit { commitEdit() }
                    .padding(.horizontal, 10)
                    .frame(height: 32)
                    .background(Color.white.opacity(0.06))
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.ttHairline, lineWidth: 0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Button("Save") { commitEdit() }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(editName.trimmingCharacters(in: .whitespaces).isEmpty)

                Button { isEditing = false } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.ttInk2)
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.04))
        .overlay(alignment: .top) { Color.ttHairline2.frame(height: 0.5) }
        .overlay(alignment: .bottom) { Color.ttHairline2.frame(height: 0.5) }
    }

    // MARK: - Normal mode

    private var normalBody: some View {
        HStack(spacing: 10) {            // Active indicator / color dot
            Button(action: onActivate) {
                ZStack {
                    Circle()
                        .fill(Color(hex: client.color))
                        .frame(width: 12, height: 12)
                    if isActive {
                        Circle()
                            .strokeBorder(Color.ttInk, lineWidth: 1.5)
                            .frame(width: 16, height: 16)
                    }
                }
                .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 1) {
                Text(client.name)
                    .font(.sfPro(13, weight: isActive ? .semibold : .regular))
                    .foregroundStyle(Color.ttInk)
                Text("\(sessionCount) session\(sessionCount == 1 ? "" : "s")")
                    .font(.sfPro(11))
                    .foregroundStyle(Color.ttInk2)
            }

            Spacer()

            // Rename
            Button {
                editName     = client.name
                editColor    = client.color
                isEditing    = true
                fieldFocused = true
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.ttInk2)
                    .frame(width: 26, height: 26)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            .padding(.trailing, 4)

            // Delete
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(hex: "#ff6a4d").opacity(0.85))
                    .frame(width: 26, height: 26)
                    .background(Color(hex: "#ff6a4d").opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            .padding(.trailing, 4)

            // Drag grip
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.ttInk3)
                .frame(width: 26, height: 26)
                .onDrag {
                    onDragStart()
                    return NSItemProvider(object: client.id.uuidString as NSString)
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func commitEdit() {
        let trimmed = editName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        client.name  = trimmed
        client.color = editColor
        isEditing    = false
    }
}

// MARK: - Color dot picker (horizontal row of preset swatches)

struct ColorDotPicker: View {
    @Binding var selected: String

    var body: some View {
        HStack(spacing: 5) {
            ForEach(colorPalette, id: \.self) { hex in
                Button {
                    selected = hex
                } label: {
                    ZStack {
                        Circle().fill(Color(hex: hex)).frame(width: 14, height: 14)
                        if selected == hex {
                            Circle().strokeBorder(Color.white, lineWidth: 1.5).frame(width: 18, height: 18)
                        }
                    }
                    .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
