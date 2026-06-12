import SwiftUI
import AVFoundation

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppPreferences.self) private var prefs

    @State private var personalVoiceStatus: AVSpeechSynthesizer.PersonalVoiceAuthorizationStatus = .notDetermined

    var body: some View {
        @Bindable var prefs = prefs
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    textCard(prefs: $prefs)
                    speedCard(prefs: $prefs)
                    voiceCard(prefs: prefs)
                    englishCard(prefs: prefs)
                    backgroundCard(prefs: prefs)
                    previewCard(prefs: prefs)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .onAppear { personalVoiceStatus = TTSEngine.personalVoiceStatus }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
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


    @ViewBuilder
    private func textCard(prefs: Bindable<AppPreferences>) -> some View {
        GlassCard(title: "Texto") {
            VStack(spacing: 18) {
                StyledSlider(
                    label: "Tamaño: \(Int(prefs.fontSize.wrappedValue))pt",
                    value: prefs.fontSize,
                    range: 16...80,
                    step: 1,
                    accessibilityLabel: "Tamaño de fuente \(Int(prefs.fontSize.wrappedValue)) puntos"
                )
                StyledSlider(
                    label: "Espaciado letras: \(Int(prefs.letterSpacing.wrappedValue))",
                    value: prefs.letterSpacing,
                    range: 0...8,
                    step: 0.5,
                    accessibilityLabel: "Espaciado entre letras"
                )
                StyledSlider(
                    label: "Espaciado líneas: \(Int(prefs.lineSpacing.wrappedValue))",
                    value: prefs.lineSpacing,
                    range: 4...28,
                    step: 1,
                    accessibilityLabel: "Espaciado entre líneas"
                )

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Fuente OpenDyslexic")
                            .font(.subheadline.weight(.medium))
                        Text("Optimizada para dislexia")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: prefs.useOpenDyslexic)
                        .labelsHidden()
                        .tint(.clarityTeal)
                        .accessibilityLabel("Usar fuente especializada para dislexia")
                }
            }
        }
    }


    @ViewBuilder
    private func speedCard(prefs: Bindable<AppPreferences>) -> some View {
        GlassCard(title: "Lectura en voz alta") {
            StyledSlider(
                label: "Velocidad: \(speedLabel(prefs.readingSpeed.wrappedValue))",
                value: prefs.readingSpeed,
                range: 0.1...0.6,
                step: 0.05,
                accessibilityLabel: "Velocidad de lectura, \(speedLabel(prefs.readingSpeed.wrappedValue))"
            )
        }
    }


    @ViewBuilder
    private func voiceCard(prefs: AppPreferences) -> some View {
        GlassCard(title: "Voz") {
            HStack(spacing: 14) {
                Image(systemName: "person.wave.2.fill")
                    .font(.title3)
                    .foregroundStyle(Color.clarityTeal)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.clarityTeal.opacity(0.12)))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Mi Voz Personal")
                        .font(.subheadline.weight(.medium))
                    Text(personalVoiceCaption)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Toggle("", isOn: personalVoiceBinding(prefs: prefs))
                    .labelsHidden()
                    .tint(.clarityTeal)
                    .disabled(personalVoiceStatus == .unsupported || personalVoiceStatus == .denied)
                    .accessibilityLabel("Leer con mi Voz Personal")
            }
        }
    }

    private func personalVoiceBinding(prefs: AppPreferences) -> Binding<Bool> {
        Binding(
            get: { prefs.usePersonalVoice },
            set: { enabled in
                guard enabled else {
                    prefs.usePersonalVoice = false
                    return
                }
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                switch personalVoiceStatus {
                case .authorized:
                    prefs.usePersonalVoice = true
                case .notDetermined:
                    Task {
                        let status = await TTSEngine.requestPersonalVoiceAccess()
                        personalVoiceStatus = status
                        prefs.usePersonalVoice = (status == .authorized)
                    }
                default:
                    prefs.usePersonalVoice = false
                }
            }
        )
    }

    private var personalVoiceCaption: String {
        switch personalVoiceStatus {
        case .authorized:
            return TTSEngine.hasPersonalVoice
                ? "Los textos se leerán con tu propia voz"
                : "Primero crea tu voz en Ajustes → Accesibilidad → Voz Personal"
        case .denied:
            return "Permiso denegado. Actívalo en Ajustes → Accesibilidad → Voz Personal"
        case .unsupported:
            return "No disponible en este dispositivo"
        default:
            return "Lee los textos con la voz que creaste en tu iPhone o iPad"
        }
    }


    @ViewBuilder
    private func englishCard(prefs: AppPreferences) -> some View {
        GlassCard(title: "Textos en inglés") {
            VStack(spacing: 10) {
                ForEach(EnglishDefinitionMode.allCases) { mode in
                    let selected = prefs.englishDefinitionMode == mode
                    Button {
                        guard !selected else { return }
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        withAnimation(.spring(duration: 0.35)) {
                            prefs.englishDefinitionMode = mode
                        }
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: mode.icon)
                                .font(.title3)
                                .foregroundStyle(selected ? Color.white : Color.clarityTeal)
                                .frame(width: 40, height: 40)
                                .background(
                                    Circle().fill(selected
                                                  ? Color.clarityTeal
                                                  : Color.clarityTeal.opacity(0.12))
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(mode.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                Text(mode.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.leading)
                            }

                            Spacer()

                            Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(selected ? Color.clarityTeal : Color.secondary.opacity(0.4))
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(selected ? Color.clarityTeal.opacity(0.08) : Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(selected ? Color.clarityTeal.opacity(0.4) : Color.clear, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                    .frame(minHeight: 44)
                    .accessibilityAddTraits(selected ? .isSelected : [])
                    .accessibilityLabel("\(mode.title). \(mode.subtitle)")
                }
            }
        }
    }


    @ViewBuilder
    private func backgroundCard(prefs: AppPreferences) -> some View {
        GlassCard(title: "Color de fondo") {
            HStack(spacing: 14) {
                ForEach(BackgroundOption.allCases) { option in
                    ColorSwatch(
                        option: option,
                        selected: prefs.backgroundColor == option
                    ) {
                        withAnimation(.spring(duration: 0.35)) {
                            prefs.backgroundColor = option
                        }
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                }
                Spacer()
            }
        }
    }


    @ViewBuilder
    private func previewCard(prefs: AppPreferences) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Vista previa")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)

            Text("El texto se verá así cuando leas en ClaRity.")
                .font(.custom(prefs.fontName, size: prefs.fontSize))
                .tracking(prefs.letterSpacing)
                .lineSpacing(prefs.lineSpacing)
                .foregroundStyle(prefs.backgroundColor.textColor)
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(prefs.backgroundColor.color, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
                .padding(.horizontal, 16)
                .accessibilityLabel("Vista previa del texto con la configuración actual")
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


private struct GlassCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            content()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.clarityCardStroke, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 14, y: 4)
    }
}


private struct StyledSlider: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let accessibilityLabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline.weight(.medium))

            HStack(spacing: 10) {
                Slider(value: $value, in: range, step: step)
                    .tint(.clarityTeal)
                    .accessibilityLabel(accessibilityLabel)
            }
        }
    }
}


private struct ColorSwatch: View {
    let option: BackgroundOption
    let selected: Bool
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(option.color)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )

                if selected {
                    Circle()
                        .stroke(Color.clarityTeal, lineWidth: 3)
                        .frame(width: 56, height: 56)

                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.clarityTeal)
                }
            }
            .scaleEffect(selected ? 1.12 : 1.0)
            .animation(reduceMotion ? .none : .spring(duration: 0.35), value: selected)
        }
        .frame(width: 60, height: 60)
        .contentShape(Circle())
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityLabel(option.rawValue + (selected ? ", seleccionado" : ""))
    }
}

#Preview {
    SettingsView()
        .environment(AppPreferences.shared)
}
