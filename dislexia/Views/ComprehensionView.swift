import SwiftUI

struct ComprehensionView: View {
    @State var questions: [ComprehensionQuestion]
    let text: String
    let ai: AIEngine
    @Environment(\.dismiss) private var dismiss

    @State private var summary: String = ""
    @State private var isLoadingSummary = false
    @State private var allAnswered = false
    @State private var appeared = false

    private var score: Int {
        questions.filter { $0.answer == true }.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        progressDots
                        headerSection
                        questionsSection
                        if allAnswered {
                            completionBanner
                            summarySection
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 24)
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
                withAnimation(.spring(duration: 0.35)) {
                    allAnswered = newVal.allSatisfy { $0.answer != nil } && !newVal.isEmpty
                }
            }
            .onAppear { appeared = true }
        }
    }

    // MARK: - Progress Dots

    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(Array(questions.enumerated()), id: \.offset) { idx, q in
                Circle()
                    .fill(q.answer != nil
                          ? LinearGradient(colors: [Color(hex: "#7C3AED"), Color(hex: "#EC4899")],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                          : LinearGradient(colors: [Color(.systemGray4), Color(.systemGray4)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 10, height: 10)
                    .animation(.spring(duration: 0.35), value: q.answer != nil)
            }
            Spacer()
            if !questions.isEmpty {
                Text("\(questions.filter { $0.answer != nil }.count)/\(questions.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("¿Entendiste lo que leíste?")
                .font(.title2.bold())
            Text("Responde cada pregunta con Sí o No.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Questions

    @ViewBuilder
    private var questionsSection: some View {
        if questions.isEmpty {
            ProgressView("Generando preguntas…")
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
        } else {
            VStack(spacing: 14) {
                ForEach(Array(questions.enumerated()), id: \.element.id) { idx, _ in
                    QuestionCard(question: $questions[idx])
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

    // MARK: - Completion Banner

    private var completionBanner: some View {
        HStack(spacing: 14) {
            Text("🎉")
                .font(.largeTitle)
            VStack(alignment: .leading, spacing: 2) {
                Text("¡Muy bien!")
                    .font(.headline.bold())
                Text("\(score) de \(questions.count) correctas")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color(hex: "#7C3AED").opacity(0.5), Color(hex: "#EC4899").opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: Color(hex: "#7C3AED").opacity(0.12), radius: 16, y: 4)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Completado. \(score) de \(questions.count) correctas.")
    }

    // MARK: - Summary

    @ViewBuilder
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Resumen")
                .font(.headline.weight(.semibold))

            if isLoadingSummary {
                HStack(spacing: 10) {
                    ProgressView()
                        .tint(Color(hex: "#7C3AED"))
                    Text("Generando resumen…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text(summary)
                    .font(.body)
                    .foregroundStyle(.primary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 12, y: 4)
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

// MARK: - Question Card

struct QuestionCard: View {
    @Binding var question: ComprehensionQuestion

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(question.question)
                .font(.body.weight(.medium))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                GlassAnswerButton(
                    label: "Sí",
                    selected: question.answer == true,
                    tint: .green
                ) {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    withAnimation(.spring(duration: 0.3)) { question.answer = true }
                }

                GlassAnswerButton(
                    label: "No",
                    selected: question.answer == false,
                    tint: .red
                ) {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    withAnimation(.spring(duration: 0.3)) { question.answer = false }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.4), .white.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.06), radius: 14, y: 4)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Glass Answer Button

struct GlassAnswerButton: View {
    let label: String
    let selected: Bool
    let tint: Color
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.headline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
        }
        .buttonStyle(.plain)
        .glassEffect(selected ? .regular.tint(tint) : .regular.interactive(),
                     in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .frame(minHeight: 44)
        .scaleEffect(selected ? 1.02 : 1.0)
        .animation(reduceMotion ? .none : .spring(duration: 0.25), value: selected)
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
