import SwiftUI

struct WordDefinitionCard: View {
    let word: String
    let definition: String
    let isLoading: Bool
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                Text(word.capitalized)
                    .font(.headline.weight(.bold))
                    .overlay(
                        LinearGradient(
                            colors: [Color(hex: "#7C3AED"), Color(hex: "#EC4899")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .mask(
                            Text(word.capitalized)
                                .font(.headline.weight(.bold))
                        )
                    )
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .glassEffect(.regular.interactive(), in: Circle())
                .frame(width: 36, height: 36)
                .accessibilityLabel("Cerrar definición")
            }

            LinearGradient(
                colors: [.clear, .secondary.opacity(0.35), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 1)

            if isLoading {
                HStack(spacing: 10) {
                    ProgressView()
                        .tint(Color(hex: "#7C3AED"))
                    Text("Buscando definición…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text(definition)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.bottom, 152)
        .shadow(color: .black.opacity(0.1), radius: 16, y: 4)
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
