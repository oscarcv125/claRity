import SwiftUI

struct ManualEntryView: View {
    let onSave: (String, String, DifficultyLevel) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var level: DifficultyLevel = .basic
    @State private var titleError = false
    @State private var contentError = false

    private var characterCount: Int { content.count }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    titleCard
                    levelCard
                    contentCard
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Nuevo texto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                        .accessibilityLabel("Cancelar")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { attemptSave() }
                        .fontWeight(.semibold)
                        .accessibilityLabel("Guardar texto")
                }
            }
        }
    }

    // MARK: - Title Card

    private var titleCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Título")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            TextField("Nombre del texto", text: $title)
                .font(.body)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color(.systemBackground).opacity(0.6), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .onChange(of: title) { _, _ in titleError = false }
                .accessibilityLabel("Título del texto")

            if titleError {
                Text("Por favor ingresa un título.")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    LinearGradient(colors: [.white.opacity(0.4), .white.opacity(0.1)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.red.opacity(titleError ? 0.6 : 0), lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.05), radius: 12, y: 4)
        .animation(.spring(duration: 0.3), value: titleError)
    }

    // MARK: - Level Card

    private var levelCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nivel de dificultad")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                ForEach(DifficultyLevel.allCases, id: \.self) { lvl in
                    LevelPill(lvl: lvl, selected: level == lvl) {
                        withAnimation(.spring(duration: 0.3)) { level = lvl }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.4), .white.opacity(0.1)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 12, y: 4)
    }

    // MARK: - Content Card

    private var contentCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Contenido")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(characterCount)")
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(.systemGray5))
                    .foregroundStyle(.secondary)
                    .clipShape(Capsule())
            }

            TextEditor(text: $content)
                .font(.body)
                .frame(minHeight: 200)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color(.systemBackground).opacity(0.6), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .onChange(of: content) { _, _ in contentError = false }
                .accessibilityLabel("Contenido del texto")

            if contentError {
                Text("Por favor ingresa el contenido del texto.")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    LinearGradient(colors: [.white.opacity(0.4), .white.opacity(0.1)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.red.opacity(contentError ? 0.6 : 0), lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.05), radius: 12, y: 4)
        .animation(.spring(duration: 0.3), value: contentError)
    }

    // MARK: - Helpers

    private func attemptSave() {
        let trimTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimContent = content.trimmingCharacters(in: .whitespacesAndNewlines)

        withAnimation(.spring(duration: 0.3)) {
            titleError = trimTitle.isEmpty
            contentError = trimContent.isEmpty
        }

        guard !trimTitle.isEmpty, !trimContent.isEmpty else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        onSave(trimTitle, trimContent, level)
        dismiss()
    }
}

// MARK: - Level Pill

private struct LevelPill: View {
    let lvl: DifficultyLevel
    let selected: Bool
    let action: () -> Void

    private var tint: Color {
        switch lvl {
        case .basic:        return .green
        case .intermediate: return .orange
        case .advanced:     return .red
        }
    }

    var body: some View {
        Button(action: action) {
            Text(lvl.rawValue)
                .font(.subheadline.weight(selected ? .semibold : .regular))
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
        }
        .buttonStyle(.plain)
        .glassEffect(selected ? .regular.tint(tint) : .regular.interactive(), in: Capsule())
        .frame(minHeight: 44)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityLabel(lvl.rawValue + (selected ? ", seleccionado" : ""))
    }
}

#Preview {
    ManualEntryView { _, _, _ in }
}
