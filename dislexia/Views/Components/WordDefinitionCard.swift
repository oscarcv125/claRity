import SwiftUI

struct WordDefinitionCard: View {
    let word: String
    let definition: String
    let isLoading: Bool
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(word.capitalized)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Cerrar definición")
                .frame(minWidth: 44, minHeight: 44)
            }

            Divider()

            if isLoading {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Buscando definición…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text(definition)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.bottom, 148)
        .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isLoading ? "Cargando definición de \(word)" : "\(word): \(definition)")
    }
}

#Preview {
    ZStack(alignment: .bottom) {
        Color(.systemGroupedBackground).ignoresSafeArea()
        WordDefinitionCard(
            word: "aprendizaje",
            definition: "Aprendizaje significa obtener conocimiento nuevo. Ejemplo: El aprendizaje en la escuela nos ayuda a crecer.",
            isLoading: false,
            onDismiss: {}
        )
    }
}
