import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppPreferences.self) private var prefs

    var body: some View {
        @Bindable var prefs = prefs
        NavigationStack {
            Form {
                Section("Texto") {
                    LabeledSlider(
                        label: "Tamaño: \(Int(prefs.fontSize))pt",
                        value: $prefs.fontSize,
                        range: 16...40,
                        step: 1,
                        accessibilityLabel: "Tamaño de fuente \(Int(prefs.fontSize)) puntos"
                    )
                    LabeledSlider(
                        label: "Espaciado entre letras: \(Int(prefs.letterSpacing))",
                        value: $prefs.letterSpacing,
                        range: 0...8,
                        step: 0.5,
                        accessibilityLabel: "Espaciado entre letras"
                    )
                    LabeledSlider(
                        label: "Espaciado entre líneas: \(Int(prefs.lineSpacing))",
                        value: $prefs.lineSpacing,
                        range: 4...28,
                        step: 1,
                        accessibilityLabel: "Espaciado entre líneas"
                    )
                    Toggle("Fuente OpenDyslexic", isOn: $prefs.useOpenDyslexic)
                        .accessibilityLabel("Usar fuente especializada para dislexia")
                }

                Section("Lectura en voz alta") {
                    LabeledSlider(
                        label: "Velocidad: \(speedLabel(prefs.readingSpeed))",
                        value: $prefs.readingSpeed,
                        range: 0.1...0.6,
                        step: 0.05,
                        accessibilityLabel: "Velocidad de lectura, \(speedLabel(prefs.readingSpeed))"
                    )
                }

                Section("Color de fondo") {
                    ForEach(BackgroundOption.allCases) { option in
                        Button {
                            prefs.backgroundColor = option
                        } label: {
                            HStack(spacing: 14) {
                                Circle()
                                    .fill(option.color)
                                    .frame(width: 26, height: 26)
                                    .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
                                Text(option.rawValue)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if prefs.backgroundColor == option {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.tint)
                                        .accessibilityHidden(true)
                                }
                            }
                        }
                        .contentShape(Rectangle())
                        .frame(minHeight: 44)
                        .accessibilityElement(children: .combine)
                        .accessibilityAddTraits(prefs.backgroundColor == option ? .isSelected : [])
                        .accessibilityLabel(option.rawValue + (prefs.backgroundColor == option ? ", seleccionado" : ""))
                    }
                }

                Section("Vista previa") {
                    Text("El texto se verá así cuando leas un libro en DislexIA.")
                        .font(.custom(prefs.fontName, size: prefs.fontSize))
                        .tracking(prefs.letterSpacing)
                        .lineSpacing(prefs.lineSpacing)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(prefs.backgroundColor.color)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .accessibilityLabel("Vista previa del texto con la configuración actual")
                }
            }
            .navigationTitle("Configuración")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") { dismiss() }
                        .fontWeight(.semibold)
                        .accessibilityLabel("Cerrar configuración")
                }
            }
        }
    }

    private func speedLabel(_ speed: Double) -> String {
        switch speed {
        case ..<0.2:  return "Muy lento"
        case ..<0.35: return "Lento"
        case ..<0.5:  return "Normal"
        default:      return "Rápido"
        }
    }
}

// MARK: - Labeled slider

private struct LabeledSlider: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let accessibilityLabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline)
            Slider(value: $value, in: range, step: step)
                .accessibilityLabel(accessibilityLabel)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    SettingsView()
        .environment(AppPreferences.shared)
}
