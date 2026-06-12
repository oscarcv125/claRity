import SwiftUI
import NaturalLanguage
import SwiftData

// docs
private struct BreakdownTarget: Identifiable {
    let id = UUID()
    let word: String
}

struct ReaderView: View {
    let item: LibraryItem

    @Environment(AppPreferences.self) private var prefs

    @State private var tts = TTSEngine()
    @State private var ai = AIEngine()

    // logica
    @State private var language: ReadingLanguage = .spanish

    // logica
    @State private var breakdownTarget: BreakdownTarget? = nil

    @State private var tappedWord: String? = nil
    @State private var wordDefinition: WordDefinition? = nil
    @State private var isDefining = false
    @State private var defineTask: Task<Void, Never>? = nil

    @State private var showComprehension = false
    @State private var comprehensionQuestions: [ComprehensionQuestion] = []
    @State private var isGeneratingQuestions = false

    @State private var showSettings = false
    @State private var showTextChat = false

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
                askAIButton
                settingsButton
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showTextChat) {
            TextChatView(
                title: item.title,
                text: item.body,
                language: language,
                englishMode: prefs.englishDefinitionMode,
                ai: ai,
                tts: tts
            )
            .presentationDragIndicator(.visible)
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

    private var askAIButton: some View {
        Button {
            tts.pause()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            showTextChat = true
        } label: {
            Image(systemName: "sparkles")
                .frame(width: 36, height: 36)
                .foregroundStyle(Color.clarityTeal)
        }
        .glassEffect(.regular.interactive(), in: Circle())
        .accessibilityLabel("Preguntarle a la IA sobre este texto")
        .accessibilityHint("Abre un chat para hacer preguntas sobre el texto abierto")
    }

    private var settingsButton: some View {
        Button { showSettings = true } label: {
            Image(systemName: "textformat.size")
                .frame(width: 36, height: 36)
        }
        .glassEffect(.regular.interactive(), in: Circle())
        .accessibilityLabel("Abrir configuración de lectura")
    }


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
        // logica
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
                let inEnglish = language == .english && prefs.englishDefinitionMode == .immersion
                result = WordDefinition(
                    word: word,
                    senses: [
                        .init(
                            text: inEnglish
                                ? "Couldn't get a definition on this device."
                                : "No se pudo obtener la definición en este dispositivo.",
                            isCurrent: true
                        )
                    ],
                    example: nil
                )
            }
            // logica
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
