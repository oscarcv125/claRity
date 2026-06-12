import SwiftUI

struct WordDefinitionCard: View {
    let word: String
    let definition: WordDefinition?
    let isLoading: Bool
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                Text(word.capitalized)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color(hex: "#7C3AED"))
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

            Color.secondary.opacity(0.2)
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
            } else if let definition {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(definition.senses.enumerated()), id: \.offset) { index, sense in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(index + 1)")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(sense.isCurrent ? .white : .secondary)
                                .frame(width: 18, height: 18)
                                .background(
                                    Circle()
                                        .fill(sense.isCurrent ? Color(hex: "#7C3AED") : Color.white.opacity(0.08))
                                )
                                .padding(.top, 1)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(sense.text)
                                    .font(.subheadline)
                                    .foregroundStyle(sense.isCurrent ? .primary : .secondary.opacity(0.6))
                                    .fontWeight(sense.isCurrent ? .medium : .regular)
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                if sense.isCurrent {
                                    Text("Significado en este texto")
                                        .font(.caption2)
                                        .foregroundStyle(Color(hex: "#A855F7"))
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                    }

                    if let example = definition.example {
                        VStack(alignment: .leading, spacing: 4) {
                            Color.secondary.opacity(0.15)
                                .frame(height: 1)
                                .padding(.vertical, 4)

                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: "lightbulb.fill")
                                    .font(.caption)
                                    .foregroundStyle(Color(hex: "#EC4899"))
                                    .padding(.top, 2)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Ejemplo de uso:")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                    
                                    Text("\"\(example)\"")
                                        .font(.caption.italic())
                                        .foregroundStyle(.primary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                }
            } else {
                Text("No hay definición disponible.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.bottom, 152)
        .shadow(color: .black.opacity(0.1), radius: 16, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isLoading ? "Cargando definición de \(word)" : "\(word): \(definition?.senses.first(where: { $0.isCurrent })?.text ?? "")")
    }
}

#Preview {
    ZStack(alignment: .bottom) {
        Color(.systemGroupedBackground).ignoresSafeArea()
        WordDefinitionCard(
            word: "luna",
            definition: WordDefinition(
                word: "luna",
                senses: [
                    .init(text: "Único satélite natural de la Tierra que brilla de noche.", isCurrent: true),
                    .init(text: "Cristal o vidrio plano de una ventana o espejo.", isCurrent: false)
                ],
                example: "La luna llena ilumina todo el bosque de noche."
            ),
            isLoading: false,
            onDismiss: {}
        )
    }
}
