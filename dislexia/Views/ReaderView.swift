import SwiftUI
import NaturalLanguage
import SwiftData

struct ReaderView: View {
    let item: LibraryItem

    @Environment(AppPreferences.self) private var prefs

    @State private var tts = TTSEngine()
    @State private var ai = AIEngine()

    // Text display
    @State private var isShowingSimplified = false
    @State private var simplifiedText: String? = nil
    @State private var isSimplifying = false

    // Word definition overlay
    @State private var tappedWord: String? = nil
    @State private var wordDefinition: WordDefinition? = nil
    @State private var isDefining = false

    // Comprehension sheet
    @State private var showComprehension = false
    @State private var comprehensionQuestions: [ComprehensionQuestion] = []
    @State private var isGeneratingQuestions = false

    // Settings sheet
    @State private var showSettings = false

    private var displayText: String {
        isShowingSimplified ? (simplifiedText ?? item.body) : item.body
    }

    var body: some View {
        @Bindable var prefs = prefs

        ZStack(alignment: .bottom) {
            // Background with subtle gradient depth
            ZStack {
                prefs.backgroundColor.color
                    .ignoresSafeArea()
                LinearGradient(
                    colors: [.black.opacity(0.06), .clear, .clear, .black.opacity(0.04)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }

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
                simplifyButton
                settingsButton
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showComprehension) {
            ComprehensionView(
                questions: comprehensionQuestions,
                text: displayText,
                ai: ai
            )
        }
        .onAppear {
            prepareSession(text: item.body)
            LibraryStore.shared.markRead(item)
        }
        .onDisappear {
            tts.stop()
        }
        .onChange(of: isShowingSimplified) { _, showSimplified in
            let text = showSimplified ? (simplifiedText ?? item.body) : item.body
            tts.stop()
            prepareSession(text: text)
        }
    }

    // MARK: - Scroll content

    private var scrollContent: some View {
        ScrollView {
            SyllableTextView(
                text: displayText,
                highlightRange: tts.highlightRange,
                prefs: prefs,
                onWordTap: handleWordTap
            )
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 200)
        }
    }

    // MARK: - Toolbar items

    @ViewBuilder
    private var simplifyButton: some View {
        if isSimplifying {
            ProgressView()
                .scaleEffect(0.75)
                .tint(Color(hex: "#7C3AED"))
        } else {
            Button {
                if isShowingSimplified {
                    withAnimation(.spring(duration: 0.35)) { isShowingSimplified = false }
                } else {
                    Task { await simplifyText() }
                }
            } label: {
                Image(systemName: isShowingSimplified ? "arrow.uturn.left" : "sparkles")
                    .frame(width: 36, height: 36)
            }
            .glassEffect(.regular.interactive(), in: Circle())
            .accessibilityLabel(isShowingSimplified ? "Ver texto original" : "Simplificar texto con IA")
        }
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
                .tint(Color(hex: "#7C3AED"))
            Text("Generando preguntas…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color(hex: "#7C3AED").opacity(0.15), radius: 16)
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }

    // MARK: - Session

    private func prepareSession(text: String) {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text
        tokenizer.setLanguage(.spanish)

        var ranges: [Range<String.Index>] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            ranges.append(range)
            return true
        }

        let syls = ranges.map { SpanishSyllabifier.syllabify(String(text[$0])) }
        tts.load(text: text, wordRanges: ranges, syllables: syls)
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
        tappedWord = word
        wordDefinition = nil
        isDefining = true
        Task {
            do {
                wordDefinition = try await ai.define(word: word, context: context)
            } catch {
                wordDefinition = WordDefinition(
                    word: word,
                    senses: [
                        .init(text: "No se pudo obtener la definición en este dispositivo.", isCurrent: true)
                    ],
                    example: nil
                )
            }
            isDefining = false
        }
    }

    private func dismissDefinition() {
        withAnimation(.spring(duration: 0.35)) {
            tappedWord = nil
        }
    }

    private func simplifyText() async {
        guard simplifiedText == nil else {
            withAnimation(.spring(duration: 0.35)) { isShowingSimplified = true }
            return
        }
        isSimplifying = true
        do {
            simplifiedText = try await ai.simplify(text: item.body)
        } catch {
            simplifiedText = "No se pudo simplificar el texto en este dispositivo."
        }
        isSimplifying = false
        withAnimation(.spring(duration: 0.35)) { isShowingSimplified = true }
    }

    private func handleComplete() {
        tts.stop()
        Task {
            withAnimation { isGeneratingQuestions = true }
            do {
                let texts = try await ai.generateQuestions(for: displayText)
                comprehensionQuestions = texts.map { ComprehensionQuestion(question: $0) }
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
