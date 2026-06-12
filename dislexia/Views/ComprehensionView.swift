import SwiftUI

struct ComprehensionView: View {
    @State var questions: [ComprehensionQuestion]
    let text: String
    var language: ReadingLanguage = .spanish
    let ai: AIEngine
    @Environment(\.dismiss) private var dismiss
    @Environment(AppPreferences.self) private var prefs

    @State private var summary: String = ""
    @State private var isLoadingSummary = false
    @State private var allAnswered = false
    @State private var appeared = false
    @State private var showConfetti = false
    @State private var isRetrying = false

    private var score: Int {
        questions.filter { $0.isCorrect == true }.count
    }

    private var answeredCount: Int {
        questions.filter { $0.isAnswered }.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        if !questions.isEmpty {
                            headerSection
                            progressBar
                        }
                        questionsSection
                        if allAnswered {
                            completionBanner
                            summarySection
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 24)
                }

                if showConfetti {
                    ConfettiView()
                }
            }
            .navigationTitle("Comprensión")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Cerrar") { dismiss() }
                        .accessibilityLabel("Cerrar comprensión")
                }
            }
            .onChange(of: questions) { _, newVal in
                let done = newVal.allSatisfy { $0.isAnswered } && !newVal.isEmpty
                withAnimation(.spring(duration: 0.35)) {
                    allAnswered = done
                }
                if done && !showConfetti {
                    showConfetti = true
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            }
            .onAppear { appeared = true }
        }
    }


    private var progressBar: some View {
        HStack(spacing: 12) {
            GeometryReader { geo in
                let fraction = questions.isEmpty
                    ? 0 : CGFloat(answeredCount) / CGFloat(questions.count)
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.systemGray5))
                    Capsule()
                        .fill(Color.clarityTeal)
                        .frame(width: max(geo.size.width * fraction, fraction > 0 ? 12 : 0))
                        .animation(.spring(duration: 0.4), value: answeredCount)
                }
            }
            .frame(height: 10)

            Text("\(answeredCount) de \(questions.count)")
                .font(.app(.caption, weight: .bold))
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progreso: \(answeredCount) de \(questions.count) preguntas respondidas")
    }


    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("¿Entendiste lo que leíste?")
                .font(.app(.title2, weight: .bold))
            Text("Responde cada pregunta. ¡Tú puedes!")
                .font(.app(.subheadline))
                .foregroundStyle(.secondary)
        }
    }


    @ViewBuilder
    private var questionsSection: some View {
        if questions.isEmpty {
            if ai.isAvailable {
                // logica
                ContentUnavailableView {
                    Label("No se pudieron crear las preguntas", systemImage: "questionmark.bubble")
                } description: {
                    Text("Hubo un problema al generar las preguntas esta vez. ¡Pero ya terminaste tu lectura!")
                } actions: {
                    Button {
                        Task { await retryQuestions() }
                    } label: {
                        if isRetrying {
                            ProgressView()
                                .tint(.white)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 12)
                        } else {
                            Label("Reintentar", systemImage: "arrow.clockwise")
                                .font(.app(.headline, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                        }
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.regular.tint(.clarityTeal).interactive(), in: Capsule())
                    .frame(minHeight: 44)
                    .disabled(isRetrying)
                    .accessibilityLabel("Reintentar generar preguntas")
                }
                .padding(.top, 40)
            } else {
                // logica
                ContentUnavailableView {
                    Label("IA no disponible", systemImage: "wand.and.stars.inverse")
                } description: {
                    Text("Este dispositivo no tiene Apple Intelligence activado, así que no se pudieron generar preguntas. ¡Pero ya terminaste tu lectura!")
                }
                .padding(.top, 40)
            }
        } else {
            VStack(spacing: 14) {
                ForEach(Array(questions.enumerated()), id: \.element.id) { idx, _ in
                    QuestionCard(number: idx + 1, question: $questions[idx])
                        .opacity(appeared ? 1 : 0)
                        .offset(x: appeared ? 0 : 40)
                        .animation(
                            .spring(duration: 0.45, bounce: 0.2).delay(Double(idx) * 0.09),
                            value: appeared
                        )
                }
            }
        }
    }


    private var completionBanner: some View {
        HStack(spacing: 14) {
            Image(systemName: score == questions.count ? "trophy.fill" : "party.popper.fill")
                .font(.largeTitle)
                .foregroundStyle(score == questions.count ? Color.moradoPrincipal : Color.clarityTeal)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(score == questions.count ? "¡Perfecto!" : "¡Muy bien!")
                    .font(.app(.headline, weight: .bold))
                Text("\(score) de \(questions.count) correctas")
                    .font(.app(.subheadline))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.clarityTeal.opacity(0.4), lineWidth: 1.5)
        )
        .shadow(color: Color.clarityTeal.opacity(0.12), radius: 16, y: 4)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Completado. \(score) de \(questions.count) correctas.")
    }


    @ViewBuilder
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Resumen")
                .font(.app(.headline, weight: .semibold))

            if isLoadingSummary {
                HStack(spacing: 10) {
                    ProgressView()
                        .tint(.clarityTeal)
                    Text("Generando resumen…")
                        .font(.app(.subheadline))
                        .foregroundStyle(.secondary)
                }
            } else {
                Text(summary)
                    .font(.app(.body))
                    .foregroundStyle(.primary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.clarityCardStroke, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 12, y: 4)
        .task { await loadSummary() }
    }


    private func loadSummary() async {
        guard summary.isEmpty else { return }
        isLoadingSummary = true
        do {
            summary = try await ai.summarize(
                text: text,
                language: language,
                englishMode: prefs.englishDefinitionMode
            )
        } catch {
            summary = "No se pudo generar el resumen en este dispositivo."
        }
        isLoadingSummary = false
    }

    private func retryQuestions() async {
        guard !isRetrying else { return }
        isRetrying = true
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        do {
            let regenerated = try await ai.generateQuestions(
                for: text,
                language: language,
                englishMode: prefs.englishDefinitionMode
            )
            withAnimation(.spring(duration: 0.35)) {
                questions = regenerated
            }
            if !questions.isEmpty {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        } catch {
            // logica
        }
        isRetrying = false
    }
}


struct QuestionCard: View {
    let number: Int
    @Binding var question: ComprehensionQuestion

    private let optionLetters = ["A", "B", "C"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Text("\(number)")
                    .font(.app(.subheadline, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(Color.clarityTeal))
                    .accessibilityHidden(true)

                Text(question.question)
                    .font(.app(.body, weight: .semibold))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if question.isMultipleChoice {
                choiceOptions
            } else {
                yesNoButtons
            }

            if let correct = question.isCorrect {
                Label(
                    correct ? "¡Correcto!" : incorrectFeedback,
                    systemImage: correct ? "checkmark.seal.fill" : "lightbulb.fill"
                )
                .font(.app(.caption, weight: .semibold))
                .foregroundStyle(correct ? Color.menta : Color.moradoPrincipal)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(strokeColor, lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.06), radius: 14, y: 4)
    }


    private var yesNoButtons: some View {
        HStack(spacing: 12) {
            SolidAnswerButton(
                label: "Sí",
                icon: "hand.thumbsup.fill",
                selected: question.answer == true,
                tint: .menta
            ) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                withAnimation(.spring(duration: 0.3)) { question.answer = true }
            }

            SolidAnswerButton(
                label: "No",
                icon: "hand.thumbsdown.fill",
                selected: question.answer == false,
                tint: .moradoPrincipal
            ) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                withAnimation(.spring(duration: 0.3)) { question.answer = false }
            }
        }
    }


    private var choiceOptions: some View {
        VStack(spacing: 10) {
            ForEach(Array(question.options.enumerated()), id: \.offset) { idx, option in
                ChoiceOptionRow(
                    letter: optionLetters.indices.contains(idx) ? optionLetters[idx] : "•",
                    text: option,
                    selected: question.selectedOptionIndex == idx
                ) {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    withAnimation(.spring(duration: 0.3)) {
                        question.selectedOptionIndex = idx
                    }
                }
            }
        }
    }

    private var incorrectFeedback: String {
        if question.isMultipleChoice {
            if let correctIdx = question.correctOptionIndex,
               question.options.indices.contains(correctIdx) {
                let letter = optionLetters.indices.contains(correctIdx)
                    ? optionLetters[correctIdx] : "•"
                return "La respuesta era \(letter): \(question.options[correctIdx])"
            }
            return "Esa no era la respuesta."
        }
        return "La respuesta era \(question.expectedAnswer == true ? "Sí" : "No")"
    }

    private var strokeColor: Color {
        switch question.isCorrect {
        case .some(true):  return Color.menta.opacity(0.45)
        case .some(false): return Color.moradoPrincipal.opacity(0.45)
        case .none:        return .clarityCardStroke
        }
    }
}


// docs
private struct SolidAnswerButton: View {
    let label: String
    let icon: String
    let selected: Bool
    let tint: Color
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                Text(label)
                    .font(.app(.headline, weight: .semibold))
            }
            .foregroundStyle(selected ? Color.white : tint)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 48)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(selected ? tint : tint.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(tint.opacity(selected ? 0 : 0.35), lineWidth: 1.5)
            )
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .scaleEffect(selected && !reduceMotion ? 1.03 : 1.0)
        .animation(reduceMotion ? .none : .spring(duration: 0.25), value: selected)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityLabel(label + (selected ? ", seleccionado" : ""))
    }
}


private struct ChoiceOptionRow: View {
    let letter: String
    let text: String
    let selected: Bool
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(letter)
                    .font(.app(.subheadline, weight: .bold))
                    .foregroundStyle(selected ? Color.white : Color.clarityTeal)
                    .frame(width: 30, height: 30)
                    .background(
                        Circle().fill(selected ? Color.clarityTeal : Color.clarityTeal.opacity(0.12))
                    )

                Text(text)
                    .font(.app(.subheadline, weight: .medium))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.clarityTeal)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(minHeight: 48)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(selected ? Color.clarityTeal.opacity(0.14) : Color(.tertiarySystemFill))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        selected ? Color.clarityTeal.opacity(0.5) : Color.clear,
                        lineWidth: 1.5
                    )
            )
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .animation(reduceMotion ? .none : .spring(duration: 0.25), value: selected)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityLabel("Opción \(letter): \(text)" + (selected ? ", seleccionada" : ""))
    }
}

#Preview {
    ComprehensionView(
        questions: [
            ComprehensionQuestion(question: "¿El texto habla sobre el agua?", expectedAnswer: true),
            ComprehensionQuestion(question: "¿El sol es pequeño y azul?", expectedAnswer: false),
            ComprehensionQuestion(
                question: "¿De qué color es el agua del mar?",
                options: ["Azul", "Roja", "Verde"],
                correctOptionIndex: 0
            )
        ],
        text: "El agua es un recurso muy valioso.",
        language: .spanish,
        ai: AIEngine()
    )
    .environment(AppPreferences.shared)
}
