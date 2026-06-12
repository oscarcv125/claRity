import SwiftUI

// Mensaje del chat sobre el texto abierto
struct TextChatMessage: Identifiable, Equatable {
    enum Role { case user, assistant }
    let id = UUID()
    let role: Role
    var text: String
}

// Hoja de chat: hazle preguntas a Apple Intelligence sobre el texto abierto
struct TextChatView: View {
    let title: String
    let text: String
    var language: ReadingLanguage = .spanish
    var englishMode: EnglishDefinitionMode = .translate
    let ai: AIEngine

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var messages: [TextChatMessage] = []
    @State private var input = ""
    @State private var isResponding = false
    @State private var askTask: Task<Void, Never>? = nil
    @FocusState private var inputFocused: Bool

    private var inEnglish: Bool {
        language == .english && englishMode == .immersion
    }

    private var suggestions: [String] {
        inEnglish
            ? ["What is the text about?", "Explain the main idea", "Tell me an important fact"]
            : ["¿De qué trata el texto?", "Explícame la idea principal", "Dime un dato importante"]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    if ai.isAvailable {
                        conversation
                        inputBar
                    } else {
                        unavailableState
                    }
                }
            }
            .navigationTitle("Pregúntale al texto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Cerrar") { dismiss() }
                        .accessibilityLabel("Cerrar preguntas sobre el texto")
                }
            }
            .onDisappear {
                askTask?.cancel()
            }
        }
    }


    private var conversation: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 12) {
                    if messages.isEmpty {
                        emptyState
                            .padding(.top, 40)
                    }
                    ForEach(messages) { message in
                        ChatBubble(message: message)
                            .id(message.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: messages) { _, newValue in
                guard let last = newValue.last else { return }
                if reduceMotion {
                    proxy.scrollTo(last.id, anchor: .bottom)
                } else {
                    withAnimation(.spring(duration: 0.35)) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }


    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles.rectangle.stack")
                .font(.system(size: 44))
                .foregroundStyle(Color.clarityTeal)

            VStack(spacing: 6) {
                Text("Pregunta lo que quieras")
                    .font(.title3.bold())
                Text("La IA responde usando solo «\(title)»")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 10) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button {
                        send(suggestion)
                    } label: {
                        Text(suggestion)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.clarityTeal)
                            .frame(minHeight: 44)
                            .padding(.horizontal, 18)
                    }
                    .glassEffect(.regular.interactive(), in: Capsule())
                    .accessibilityLabel("Preguntar: \(suggestion)")
                }
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
    }


    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField(
                inEnglish ? "Ask about the text…" : "Escribe tu pregunta…",
                text: $input,
                axis: .vertical
            )
            .lineLimit(1...3)
            .focused($inputFocused)
            .submitLabel(.send)
            .onSubmit { send(input) }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .accessibilityLabel("Campo para escribir tu pregunta sobre el texto")

            Button {
                send(input)
            } label: {
                Image(systemName: isResponding ? "ellipsis" : "arrow.up")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .contentTransition(.symbolEffect(.replace))
            }
            .glassEffect(.regular.tint(.clarityTeal).interactive(), in: Circle())
            .disabled(isResponding || input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityLabel("Enviar pregunta")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }


    private var unavailableState: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.bubble")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("Apple Intelligence no está disponible")
                .font(.headline)
            Text("Esta función necesita un dispositivo compatible con Apple Intelligence (iOS 18.1 o posterior).")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }


    private func send(_ question: String) {
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isResponding else { return }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        input = ""
        messages.append(TextChatMessage(role: .user, text: trimmed))
        messages.append(TextChatMessage(role: .assistant, text: ""))
        isResponding = true

        askTask = Task {
            do {
                let final = try await ai.ask(
                    question: trimmed,
                    about: text,
                    language: language,
                    englishMode: englishMode
                ) { partial in
                    updateLastAssistantMessage(with: partial)
                }
                guard !Task.isCancelled else { return }
                updateLastAssistantMessage(with: final)
            } catch {
                guard !Task.isCancelled else { return }
                updateLastAssistantMessage(
                    with: inEnglish
                        ? "Sorry, I couldn't answer that. Try again."
                        : "No pude responder esa pregunta. Intenta de nuevo."
                )
            }
            isResponding = false
        }
    }

    private func updateLastAssistantMessage(with text: String) {
        guard let index = messages.lastIndex(where: { $0.role == .assistant }) else { return }
        messages[index].text = text
    }
}


// Burbuja individual del chat
private struct ChatBubble: View {
    let message: TextChatMessage

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 48) }

            Group {
                if message.role == .assistant && message.text.isEmpty {
                    ProgressView()
                        .tint(.clarityTeal)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                } else {
                    Text(message.text)
                        .font(.body)
                        .foregroundStyle(message.role == .user ? .white : .primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }
            }
            .background {
                if message.role == .user {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.clarityTeal)
                } else {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)
                }
            }

            if message.role == .assistant { Spacer(minLength: 48) }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            message.role == .user
                ? "Tu pregunta: \(message.text)"
                : "Respuesta de la IA: \(message.text.isEmpty ? "pensando" : message.text)"
        )
    }
}

#Preview {
    TextChatView(
        title: "El Sol y la Luna",
        text: """
        El sol es una estrella muy grande y brillante. Durante el día, el sol nos da luz y calor. \
        Sin el sol, las plantas no podrían crecer y los animales no podrían vivir. \
        La luna, en cambio, brilla de noche con la luz que refleja del sol.
        """,
        ai: AIEngine()
    )
    .environment(AppPreferences.shared)
}
