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

    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var filteredItems: [LibraryItem] {
        guard let level = selectedLevel else { return allItems }
        return allItems.filter { $0.level == level }
    }

    private var recentItems: [LibraryItem] {
        allItems.filter { $0.lastReadAt != nil }
            .sorted { ($0.lastReadAt ?? .distantPast) > ($1.lastReadAt ?? .distantPast) }
            .prefix(5).map { $0 }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color(.systemBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        heroHeader
                        filterPillsRow
                        if !recentItems.isEmpty && selectedLevel == nil {
                            recentSection
                        }
                        gridSection
                    }
                }
                .backgroundExtensionEffect()

                bottomBar
            }
            .toolbar(.hidden, for: .navigationBar)
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

    // MARK: - Hero Header

    private var heroHeader: some View {
        ZStack(alignment: .bottom) {
            MeshGradient(
                width: 3, height: 3,
                points: [
                    .init(0, 0),   .init(0.5, 0),  .init(1, 0),
                    .init(0, 0.5), .init(0.6, 0.4), .init(1, 0.5),
                    .init(0, 1),   .init(0.5, 1),  .init(1, 1)
                ],
                colors: [
                    Color(hex: "#7C3AED"), Color(hex: "#9F5CF4"), Color(hex: "#B45FFF"),
                    Color(hex: "#6D28D9"), Color(hex: "#A855F7"), Color(hex: "#EC4899"),
                    Color(hex: "#7C3AED"), Color(hex: "#C026D3"), Color(hex: "#F43F5E")
                ]
            )
            .frame(height: 260)

            LinearGradient(
                colors: [.clear, Color(.systemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 100)

            VStack(spacing: 8) {
                ClaRityWordmark(size: 48)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.2), radius: 6)
                Text("Tu lector inteligente")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.88))
                    .shadow(color: .black.opacity(0.1), radius: 3)
            }
            .padding(.bottom, 52)
        }
        .frame(height: 260)
    }

    // MARK: - Filter Pills

    private var filterPillsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                GlassPill(label: "Todos", selected: selectedLevel == nil) {
                    withAnimation(.spring(duration: 0.35)) { selectedLevel = nil }
                }
                ForEach(DifficultyLevel.allCases, id: \.self) { level in
                    GlassPill(label: level.rawValue, selected: selectedLevel == level) {
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

    // MARK: - Recent Section

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Leídos recientemente")
                .font(.headline.weight(.semibold))
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(recentItems) { item in
                        RecentCard(item: item)
                            .onTapGesture { selectedItem = item }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 4)
            }
        }
        .padding(.bottom, 20)
    }

    // MARK: - Grid Section

    private var gridSection: some View {
        LazyVGrid(columns: gridColumns, spacing: 12) {
            ForEach(filteredItems) { item in
                LibraryCard(item: item)
                    .onTapGesture { selectedItem = item }
                    .contextMenu {
                        Button(role: .destructive) {
                            LibraryStore.shared.delete(item)
                        } label: {
                            Label("Eliminar", systemImage: "trash")
                        }
                    }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 110)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack(spacing: 12) {
            Button {
                showManualEntry = true
            } label: {
                Label("Escribir", systemImage: "pencil")
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: Capsule())
            .frame(minHeight: 44)
            .accessibilityLabel("Escribir texto manualmente")

            Spacer()

            Button {
                showCamera = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "camera.fill")
                    Text("Capturar")
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.tint(.accentColor), in: Capsule())
            .frame(minHeight: 44)
            .accessibilityLabel("Capturar texto con cámara")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(Color.white.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 24, y: -6)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
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

// MARK: - ClaRity Wordmark

private struct ClaRityWordmark: View {
    var size: CGFloat = 38

    var body: some View {
        HStack(spacing: 0) {
            Text("Cla")
                .font(.system(size: size, weight: .black, design: .rounded))
            Text("R")
                .font(.system(size: size, weight: .black, design: .rounded))
                .scaleEffect(x: -1, y: 1)
            Text("ity")
                .font(.system(size: size, weight: .black, design: .rounded))
        }
    }
}

// MARK: - Glass Pill

private struct GlassPill: View {
    let label: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(selected ? .semibold : .regular))
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
        }
        .buttonStyle(.plain)
        .glassEffect(selected ? .regular.tint(.accentColor) : .regular.interactive(), in: Capsule())
        .frame(minWidth: 44, minHeight: 44)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityLabel(label + (selected ? ", seleccionado" : ""))
    }
}

// MARK: - Library Card

private struct LibraryCard: View {
    let item: LibraryItem

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Image(systemName: levelIcon)
                    .font(.title3)
                    .foregroundStyle(levelColor)
                    .frame(width: 36, height: 36)
                    .background(levelColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                Spacer()
                Image(systemName: sourceIcon)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Text(item.title)
                .font(.headline)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Text(item.body.prefix(65) + (item.body.count > 65 ? "…" : ""))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)

            Text(item.level.rawValue)
                .font(.caption2.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(levelColor.opacity(0.12))
                .foregroundStyle(levelColor)
                .clipShape(Capsule())
        }
        .padding(16)
        .frame(minHeight: 170, alignment: .topLeading)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.45), .white.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.07), radius: 16, y: 6)
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.title). \(item.level.rawValue). \(item.body.prefix(60)).")
    }

    private var levelColor: Color {
        switch item.level {
        case .basic:        return .green
        case .intermediate: return .orange
        case .advanced:     return .red
        }
    }

    private var levelIcon: String {
        switch item.level {
        case .basic:        return "book.fill"
        case .intermediate: return "books.vertical.fill"
        case .advanced:     return "graduationcap.fill"
        }
    }

    private var sourceIcon: String {
        switch item.source {
        case .camera:    return "camera"
        case .manual:    return "pencil"
        case .preloaded: return "sparkles"
        }
    }
}

// MARK: - Recent Card

private struct RecentCard: View {
    let item: LibraryItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)

            Text(item.body.prefix(50) + "…")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(14)
        .frame(width: 155, minHeight: 96, alignment: .topLeading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.28), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
        .contentShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Reciente: \(item.title)")
    }
}

#Preview {
    LibraryView()
        .modelContainer(LibraryStore.shared.container)
        .environment(AppPreferences.shared)
}
