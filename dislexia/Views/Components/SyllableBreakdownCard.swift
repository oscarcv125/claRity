import SwiftUI

/// Tarjeta de pronunciación: muestra una palabra dividida en sílabas de
/// colores. Cada sílaba se puede tocar para escucharla, y el botón principal
/// pronuncia la palabra completa despacio, iluminando cada sílaba.
/// Pensada para niños con dislexia o TDAH que están aprendiendo a pronunciar.
struct SyllableBreakdownCard: View {
    let word: String
    let language: ReadingLanguage
    let tts: TTSEngine
    let ai: AIEngine

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(AppPreferences.self) private var prefs

    @State private var syllables: [String] = []
    @State private var activeIndex: Int? = nil
    @State private var isPlayingAll = false
    @State private var playTask: Task<Void, Never>? = nil

    private let chipPalette: [Color] = [
        .clarityTeal, .clarityBlue, .orange, .pink, .purple, .indigo
    ]

    var body: some View {
        VStack(spacing: 28) {
            header

            syllableChips

            Text("Toca una sílaba para escucharla")
                .font(.footnote)
                .foregroundStyle(.secondary)

            playAllButton
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .task { await loadSyllables() }
        .onDisappear {
            playTask?.cancel()
            tts.stop()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 10) {
            Text(word)
                .font(.custom(prefs.fontName, size: 44))
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.4)

            Text(syllables.count == 1
                 ? "1 sílaba"
                 : "\(syllables.count) sílabas")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.clarityTeal)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Palabra \(word), \(syllables.count) sílabas")
    }

    // MARK: - Chips

    private var syllableChips: some View {
        HStack(spacing: 10) {
            ForEach(Array(syllables.enumerated()), id: \.offset) { idx, syl in
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    speakSyllable(at: idx)
                } label: {
                    Text(syl)
                        .font(.custom(prefs.fontName, size: 28))
                        .fontWeight(.semibold)
                        .foregroundStyle(activeIndex == idx ? .white : chipColor(idx))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(activeIndex == idx
                                      ? chipColor(idx)
                                      : chipColor(idx).opacity(0.14))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(chipColor(idx).opacity(0.5), lineWidth: 1.5)
                        )
                        .scaleEffect(activeIndex == idx ? 1.12 : 1.0)
                        .animation(
                            reduceMotion ? .none : .spring(duration: 0.3, bounce: 0.4),
                            value: activeIndex
                        )
                }
                .buttonStyle(.plain)
                .frame(minWidth: 44, minHeight: 44)
                .accessibilityLabel("Sílaba \(syl)")
                .accessibilityHint("Toca para escucharla")
            }
        }
        .frame(maxWidth: .infinity)
        .lineLimit(1)
        .minimumScaleFactor(0.5)
    }

    private func chipColor(_ index: Int) -> Color {
        chipPalette[index % chipPalette.count]
    }

    // MARK: - Play all

    private var playAllButton: some View {
        Button {
            if isPlayingAll {
                stopPlayback()
            } else {
                playAll()
            }
        } label: {
            Label(
                isPlayingAll ? "Detener" : "Escuchar despacio",
                systemImage: isPlayingAll ? "stop.fill" : "speaker.wave.3.fill"
            )
            .font(.headline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 28)
            .padding(.vertical, 15)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.tint(.clarityTeal).interactive(), in: Capsule())
        .frame(minHeight: 44)
        .accessibilityLabel(isPlayingAll ? "Detener pronunciación" : "Escuchar la palabra despacio")
    }

    // MARK: - Logic

    private func loadSyllables() async {
        // 1. Heurística inmediata (siempre hay algo que mostrar).
        syllables = language.syllabify(word)

        // 2. El inglés es irregular: si hay Apple Intelligence, la IA refina.
        guard language == .english, ai.isAvailable else { return }
        if let refined = try? await ai.syllabify(word: word), !refined.isEmpty {
            guard !Task.isCancelled, !isPlayingAll else { return }
            withAnimation(.spring(duration: 0.35)) {
                syllables = refined
            }
        }
    }

    private func speakSyllable(at index: Int) {
        playTask?.cancel()
        isPlayingAll = false
        withAnimation { activeIndex = index }
        tts.speak(fragment: syllables[index], rate: 0.25)

        playTask = Task {
            try? await Task.sleep(for: .seconds(0.8))
            guard !Task.isCancelled else { return }
            withAnimation { activeIndex = nil }
        }
    }

    private func playAll() {
        playTask?.cancel()
        isPlayingAll = true
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        playTask = Task {
            // Sílaba por sílaba, iluminando cada chip.
            for (idx, syl) in syllables.enumerated() {
                guard !Task.isCancelled else { return }
                withAnimation { activeIndex = idx }
                tts.speak(fragment: syl, rate: 0.2)
                try? await Task.sleep(for: .seconds(0.55 + Double(syl.count) * 0.07))
            }
            guard !Task.isCancelled else { return }

            // Pausa breve y luego la palabra completa, fluida.
            withAnimation { activeIndex = nil }
            try? await Task.sleep(for: .seconds(0.4))
            guard !Task.isCancelled else { return }
            tts.speak(fragment: word, rate: 0.35)
            try? await Task.sleep(for: .seconds(0.5 + Double(word.count) * 0.07))

            isPlayingAll = false
        }
    }

    private func stopPlayback() {
        playTask?.cancel()
        tts.stop()
        withAnimation { activeIndex = nil }
        isPlayingAll = false
    }
}

#Preview {
    SyllableBreakdownCard(
        word: "mariposa",
        language: .spanish,
        tts: TTSEngine(),
        ai: AIEngine()
    )
    .environment(AppPreferences.shared)
}
