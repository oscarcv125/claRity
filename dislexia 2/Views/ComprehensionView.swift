import SwiftUI

struct ComprehensionView: View {
    @State var questions: [ComprehensionQuestion]
    let text: String
    let ai: AIEngine
    @Environment(\.dismiss) private var dismiss

    @State private var summary: String = ""
    @State private var isLoadingSummary = false
    @State private var allAnswered = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    questionsSection
                    if allAnswered {
                        summarySection
                    }
                }
                .padding(.vertical, 24)
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
                withAnimation(.spring(duration: 0.35)) {
                    allAnswered = newVal.allSatisfy { $0.answer != nil } && !newVal.isEmpty
                }
            }
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("¿Entendiste lo que leíste?")
                .font(.title2.bold())
            Text("Responde cada pregunta con Sí o No.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var questionsSection: some View {
        if questions.isEmpty {
            ProgressView("Generando preguntas…")
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
        } else {
            VStack(spacing: 16) {
                ForEach($questions) { $q in
                    QuestionCard(question: $q)
                }
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Resumen")
                    .font(.headline)
                    .padding(.horizontal)

                if isLoadingSummary {
                    HStack {
                        ProgressView()
                        Text("Generando resumen…")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                } else {
                    Text(summary)
                        .font(.body)
                        .padding(.horizontal)
                }
            }
        }
        .task { await loadSummary() }
    }

    // MARK: - Helpers

    private func loadSummary() async {
        guard summary.isEmpty else { return }
        isLoadingSummary = true
        do {
            summary = try await ai.summarize(text: text)
        } catch {
            summary = "No se pudo generar el resumen en este dispositivo."
        }
        isLoadingSummary = false
    }
}

// MARK: - Question card

struct QuestionCard: View {
    @Binding var question: ComprehensionQuestion

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(question.question)
                .font(.body.weight(.medium))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 16) {
                AnswerButton(
                    label: "Sí",
                    selected: question.answer == true,
                    color: .green
                ) {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    question.answer = true
                }

                AnswerButton(
                    label: "No",
                    selected: question.answer == false,
                    color: .red
                ) {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    question.answer = false
                }
            }
        }
        .padding(16)
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Answer button

struct AnswerButton: View {
    let label: String
    let selected: Bool
    let color: Color
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(selected ? color : Color(.systemGray5))
                .foregroundStyle(selected ? Color.white : Color.primary)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .animation(reduceMotion ? .none : .spring(duration: 0.25), value: selected)
        }
        .frame(minHeight: 44)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityLabel(label + (selected ? ", seleccionado" : ""))
    }
}

#Preview {
    ComprehensionView(
        questions: [
            ComprehensionQuestion(question: "¿El texto habla sobre el agua?"),
            ComprehensionQuestion(question: "¿El sol es pequeño y azul?"),
            ComprehensionQuestion(question: "¿Los árboles producen oxígeno?")
        ],
        text: "El agua es un recurso muy valioso.",
        ai: AIEngine()
    )
}
