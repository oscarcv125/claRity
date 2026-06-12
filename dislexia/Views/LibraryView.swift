import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \LibraryItem.createdAt, order: .reverse) private var allItems: [LibraryItem]
    @Environment(AppPreferences.self) private var prefs

    @State private var selectedLevel: DifficultyLevel? = nil
    @State private var showCamera = false
    @State private var showManualEntry = false
    @State private var selectedItem: LibraryItem? = nil

    private var filteredItems: [LibraryItem] {
        guard let level = selectedLevel else { return allItems }
        return allItems.filter { $0.level == level }
    }

    private var recentItems: [LibraryItem] {
        allItems.filter { $0.lastReadAt != nil }
            .sorted { ($0.lastReadAt ?? .distantPast) > ($1.lastReadAt ?? .distantPast) }
            .prefix(3)
            .map { $0 }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterPills
                itemList
            }
            .navigationTitle("DislexIA")
            .navigationBarTitleDisplayMode(.large)
            .toolbar { bottomToolbar }
            .sheet(isPresented: $showCamera) {
                CameraView { capturedText in
                    navigateToReader(text: capturedText, source: .camera)
                }
            }
            .sheet(isPresented: $showManualEntry) {
                ManualEntryView { title, text, level in
                    LibraryStore.shared.save(title: title, body: text, level: level, source: .manual)
                }
            }
            .navigationDestination(item: $selectedItem) { item in
                ReaderView(item: item)
            }
        }
    }

    // MARK: - Subviews

    private var filterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                FilterPill(label: "Todos", selected: selectedLevel == nil) {
                    withAnimation(.spring(duration: 0.35)) { selectedLevel = nil }
                }
                ForEach(DifficultyLevel.allCases, id: \.self) { level in
                    FilterPill(label: level.rawValue, selected: selectedLevel == level) {
                        withAnimation(.spring(duration: 0.35)) {
                            selectedLevel = selectedLevel == level ? nil : level
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private var itemList: some View {
        List {
            if !recentItems.isEmpty && selectedLevel == nil {
                Section("Leídos recientemente") {
                    ForEach(recentItems) { item in
                        LibraryRow(item: item)
                            .contentShape(Rectangle())
                            .onTapGesture { selectedItem = item }
                    }
                }
            }

            ForEach(DifficultyLevel.allCases, id: \.self) { level in
                let levelItems = filteredItems.filter { $0.level == level }
                if !levelItems.isEmpty {
                    Section(level.rawValue) {
                        ForEach(levelItems) { item in
                            LibraryRow(item: item)
                                .contentShape(Rectangle())
                                .onTapGesture { selectedItem = item }
                        }
                        .onDelete { indexSet in
                            for i in indexSet {
                                LibraryStore.shared.delete(levelItems[i])
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    @ToolbarContentBuilder
    private var bottomToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {
            Button {
                showManualEntry = true
            } label: {
                Label("Escribir", systemImage: "pencil")
            }
            .accessibilityLabel("Escribir texto manualmente")

            Spacer()

            Button {
                showCamera = true
            } label: {
                Label("Cámara", systemImage: "camera.fill")
                    .font(.headline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityLabel("Capturar texto con cámara")
        }
    }

    // MARK: - Helpers

    private func navigateToReader(text: String, source: TextSource) {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        let item = LibraryItem(
            title: "Texto capturado \(formatter.string(from: .now))",
            body: text,
            level: .basic,
            source: source
        )
        LibraryStore.shared.container.mainContext.insert(item)
        try? LibraryStore.shared.container.mainContext.save()
        selectedItem = item
    }
}

// MARK: - Filter pill

struct FilterPill: View {
    let label: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(selected ? .semibold : .regular))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(selected ? Color.accentColor : Color(.systemGray5))
                .foregroundStyle(selected ? Color.white : Color.primary)
                .clipShape(Capsule())
        }
        .frame(minWidth: 44, minHeight: 44)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityLabel(label + (selected ? ", seleccionado" : ""))
    }
}

// MARK: - Library row

struct LibraryRow: View {
    let item: LibraryItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(item.title)
                    .font(.headline)
                Spacer()
                levelBadge
            }
            Text(item.body.prefix(90) + (item.body.count > 90 ? "…" : ""))
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.title). \(item.level.rawValue). \(item.body.prefix(60)).")
    }

    private var levelBadge: some View {
        Text(item.level.rawValue)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(levelColor.opacity(0.15))
            .foregroundStyle(levelColor)
            .clipShape(Capsule())
    }

    private var levelColor: Color {
        switch item.level {
        case .basic:        return .green
        case .intermediate: return .orange
        case .advanced:     return .red
        }
    }
}

#Preview {
    LibraryView()
        .modelContainer(LibraryStore.shared.container)
        .environment(AppPreferences.shared)
}
