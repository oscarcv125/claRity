import SwiftUI
import NaturalLanguage
import SwiftData

/// Palabra seleccionada con doble toque para la tarjeta de sílabas.
private struct BreakdownTarget: Identifiable {
    let id = UUID()
    let word: String
}

struct ReaderView: View {
    let item: LibraryItem

    @Environment(AppPreferences.self) private var prefs

    @State private var tts = TTSEngine()
    @State private var ai = AIEngine()

    // Idioma del documento (detectado al abrir, ajustable en la barra)
    @State private var language: ReadingLanguage = .spanish

    // Tarjeta de sílabas (doble toque sobre una palabra)
    @State private var breakdownTarget: BreakdownTarget? = nil

    // Word definition overlay
    @State private var tappedWord: String? = nil
    @State private var wordDefinition: WordDefinition? = nil
    @State private var isDefining = false
    @State private var defineTask: Task<Void, Never>? = nil

    // Comprehension sheet
    @State private var showComprehension = false
    @State private var comprehensionQuestions: [ComprehensionQuestion] = []
    @State private var isGeneratingQuestions = false

    // Settings sheet
    @State private var showSettings = false

    var body: some View {
        @Bindable var prefs = prefs

        ZStack(alignment: .bottom) {
            prefs.backgroundColor.color
                .ignoresSafeArea()

            scrollContent

            VStack(spacing: 0) {
                if let word = tappedWord {
                    WordDefinitionCard(
                        word: word,
                        definition: wordDefinition,
                        isLoading: isDefining,
                        onDismiss: dismissDefinition
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                ReadingControlBar(
                    isPlaying: tts.isPlaying,
                    speed: $prefs.readingSpeed,
                    onPlayPause: handlePlayPause,
                    onStop: { tts.stop() },
                    onComplete: handleComplete
                )
            }
            .animation(.spring(duration: 0.35), value: tappedWord != nil)

            if isGeneratingQuestions {
                generatingOverlay
            }
        }
        .navigationTitle(item.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                languageMenu
                settingsButton
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showComprehension) {
            ComprehensionView(
                questions: comprehensionQuestions,
                text: item.body,
                language: language,
                ai: ai
            )
        }
        .sheet(item: $breakdownTarget) { target in
            SyllableBreakdownCard(
                word: target.word,
                language: language,
                tts: tts,
                ai: ai
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            language = ReadingLanguage.detect(from: item.body)
            prepareSession(text: item.body)
            LibraryStore.shared.markRead(item)
            ai.prewarm()
        }
        .onDisappear {
            defineTask?.cancel()
            tts.stop()
        }
        .onChange(of: language) { _, _ in
            tts.stop()
            prepareSession(text: item.body)
        }
        .onChange(of: prefs.readingSpeed) { _, newSpeed in
            tts.setSpeed(newSpeed)
        }
    }

    // MARK: - Scroll content

    private var scrollContent: some View {
        ScrollView {
            SyllableTextView(
                text: item.body,
                highlightRange: tts.highlightRange,
                prefs: prefs,
                onWordTap: handleWordTap,
                dimInactive: tts.isPlaying,
                onWordLongPress: { word in
                    tts.pronounceSlowly(word: word)
                },
                onWordDoubleTap: { word in
                    tts.stop()
                    breakdownTarget = BreakdownTarget(word: word)
                }
            )
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 200)
        }
    }

    // MARK: - Toolbar items

    private var languageMenu: some View {
        Menu {
            ForEach(ReadingLanguage.allCases) { lang in
                Button {
                    guard lang != language else { return }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    language = lang
                } label: {
                    if lang == language {
                        Label(lang.displayName, systemImage: "checkmark")
                    } else {
                        Text(lang.displayName)
                    }
                }
            }
        } label: {
            HStack(spacing: 3) {
                Image(systemName: "globe")
                    .font(.system(size: 13, weight: .semibold))
                Text(language.shortCode)
                    .font(.caption.weight(.bold))
            }
            .foregroundStyle(Color.clarityTeal)
            .frame(height: 36)
            .padding(.horizontal, 10)
        }
        .glassEffect(.regular.interactive(), in: Capsule())
        .accessibilityLabel("Idioma de lectura: \(language.displayName)")
        .accessibilityHint("Cambia el idioma de la voz y las definiciones")
    }

    private var settingsButton: some View {
        Button { showSettings = true } label: {
            Image(systemName: "textformat.size")
                .frame(width: 36, height: 36)
        }
        .glassEffect(.regular.interactive(), in: Circle())
        .accessibilityLabel("Abrir configuración de lectura")
    }

    // MARK: - Generating questions overlay

    private var generatingOverlay: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(.clarityTeal)
            Text("Generando preguntas…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.clarityTeal.opacity(0.15), radius: 16)
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }

    // MARK: - Session

    private func prepareSession(text: String) {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text
        tokenizer.setLanguage(language.nlLanguage)

        var ranges: [Range<String.Index>] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            ranges.append(range)
            return true
        }

        let syls = ranges.map { language.syllabify(String(text[$0])) }
        tts.load(text: text, wordRanges: ranges, syllables: syls, language: language)
    }

    // MARK: - Actions

    private func handlePlayPause() {
        if tts.isPlaying {
            tts.pause()
        } else if tts.currentWordIndex >= 0 {
            tts.resume()
        } else {
            tts.play(speed: prefs.readingSpeed)
        }
    }

    private func handleWordTap(_ word: String, _ context: String) {
        // Cancela cualquier definición en curso para evitar que resultados
        // viejos reemplacen al más reciente (parpadeo de definiciones).
        defineTask?.cancel()
        tappedWord = word
        wordDefinition = nil
        isDefining = true
        defineTask = Task {
            var result: WordDefinition
            do {
                result = try await ai.define(
                    word: word,
                    context: context,
                    language: language,
                    englishMode: prefs.englishDefinitionMode
                )
            } catch {
                result = WordDefinition(
                    word: word,
                    senses: [
                        .init(text: "No se pudo obtener la definición en este dispositivo.", isCurrent: true)
                    ],
                    example: nil
                )
            }
            // Descarta resultados obsoletos: solo aplica si esta sigue siendo
            // la palabra seleccionada y la tarea no fue cancelada.
            guard !Task.isCancelled, tappedWord == word else { return }
            wordDefinition = result
            isDefining = false
        }
    }

    private func dismissDefinition() {
        defineTask?.cancel()
        withAnimation(.spring(duration: 0.35)) {
            tappedWord = nil
        }
    }

    private func handleComplete() {
        tts.stop()
        Task {
            withAnimation { isGeneratingQuestions = true }
            do {
                comprehensionQuestions = try await ai.generateQuestions(
                    for: item.body,
                    language: language,
                    englishMode: prefs.englishDefinitionMode
                )
            } catch {
                comprehensionQuestions = []
            }
            withAnimation { isGeneratingQuestions = false }
            showComprehension = true
        }
    }
}

#Preview {
    NavigationStack {
        ReaderView(
            item: LibraryItem(
                title: "El Sol y la Luna",
                body: """
                El sol es una estrella muy grande y brillante. Durante el día, el sol nos da luz y calor. \
                Sin el sol, las plantas no podrían crecer y los animales no podrían vivir. \
                La luna, en cambio, brilla de noche con la luz que refleja del sol. \
                Juntos, el sol y la luna hacen que los días y las noches sean posibles en nuestro planeta.
                """,
                level: .basic,
                source: .preloaded
            )
        )
        .environment(AppPreferences.shared)
        .modelContainer(LibraryStore.shared.container)
    }
}
