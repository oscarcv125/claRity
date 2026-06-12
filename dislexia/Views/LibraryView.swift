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
    // Texto capturado pendiente: navegamos hasta que el sheet de la cámara termina de cerrarse
    @State private var pendingCapturedItem: LibraryItem? = nil

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
                .ignoresSafeArea(edges: .top)
                .backgroundExtensionEffect()

                bottomBar
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showCamera, onDismiss: {
                if let item = pendingCapturedItem {
                    pendingCapturedItem = nil
                    selectedItem = item
                }
            }) {
                CameraView { capturedText in
                    pendingCapturedItem = saveCapturedItem(text: capturedText, source: .camera)
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


    private var heroHeader: some View {
        GeometryReader { geo in
            let minY = geo.frame(in: .scrollView).minY
            let stretch = minY > 0 ? minY : 0

            ZStack(alignment: .bottom) {
                LinearGradient.clarityGradient

                VStack(spacing: 8) {
                    Image("clarity white")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 48)
                        .shadow(color: .black.opacity(0.2), radius: 6)
                    Text("Tu lector inteligente")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.88))
                        .shadow(color: .black.opacity(0.1), radius: 3)
                }
                .padding(.bottom, 52)
            }
            .frame(width: geo.size.width, height: 260 + stretch)
            .offset(y: -stretch)
        }
        .frame(height: 260)
    }


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


    @ViewBuilder
    private var gridSection: some View {
        if filteredItems.isEmpty {
            ContentUnavailableView {
                Label("Sin textos", systemImage: "books.vertical")
            } description: {
                Text("No hay textos en este nivel. Captura uno con la cámara o escríbelo tú.")
            }
            .padding(.top, 30)
            .padding(.bottom, 110)
        } else {
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
            .animation(.spring(duration: 0.35), value: selectedLevel)
        }
    }


    private var bottomBar: some View {
        // logica
        HStack(spacing: 12) {
            Button {
                showManualEntry = true
            } label: {
                Label("Escribir", systemImage: "pencil")
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .contentShape(Capsule())
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
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.tint(.clarityTeal).interactive(), in: Capsule())
            .frame(minHeight: 44)
            .accessibilityLabel("Capturar texto con cámara")
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }


    private func saveCapturedItem(text: String, source: TextSource) -> LibraryItem {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_MX")
        formatter.dateFormat = "d MMM"
        let item = LibraryItem(
            title: "Texto capturado \(formatter.string(from: .now))",
            body: text,
            level: .basic,
            source: source
        )
        LibraryStore.shared.container.mainContext.insert(item)
        try? LibraryStore.shared.container.mainContext.save()
        return item
    }
}





private struct GlassPill: View {
    let label: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(selected ? .semibold : .regular))
                .foregroundStyle(selected ? Color.white : Color.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
        }
        .buttonStyle(.plain)
        .glassEffect(selected ? .regular.tint(.clarityTeal) : .regular.interactive(), in: Capsule())
        .frame(minWidth: 44, minHeight: 44)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityLabel(label + (selected ? ", seleccionado" : ""))
    }
}


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

            HStack(spacing: 4) {
                Circle()
                    .fill(levelColor)
                    .frame(width: 6, height: 6)
                Text(item.level.rawValue)
                    .font(.caption.weight(.medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(levelColor.opacity(0.1), in: Capsule())
            .overlay(
                Capsule().stroke(levelColor.opacity(0.3), lineWidth: 0.5)
            )
            .foregroundStyle(levelColor)
        }
        .padding(16)
        .frame(minHeight: 170, alignment: .topLeading)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.clarityCardStroke, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.07), radius: 16, y: 6)
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.title). \(item.level.rawValue). \(item.body.prefix(60)).")
    }

    private var levelColor: Color {
        switch item.level {
        case .basic:        return .menta
        case .intermediate: return .azulPrincipal
        case .advanced:     return .moradoPrincipal
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


private struct RecentCard: View {
    let item: LibraryItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)

            Text(item.body.prefix(50) + (item.body.count > 50 ? "…" : ""))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(14)
        .frame(width: 155)
        .frame(minHeight: 96, alignment: .topLeading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.clarityCardStroke, lineWidth: 1)
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
