import Foundation
import Observation
import FoundationModels
import NaturalLanguage

@Observable
@MainActor
final class AIEngine {

    // prueba
    // docs
    static let multipleChoiceEnabled = true

    enum AIError: LocalizedError {
        case modelUnavailable
        case generationFailed(String)

        var errorDescription: String? {
            switch self {
            case .modelUnavailable:
                return "El modelo de IA no está disponible en este dispositivo. Requiere Apple Intelligence (iPhone con chip A17 Pro o posterior, iOS 18.1+)."
            case .generationFailed(let msg):
                return "Error al generar respuesta: \(msg)"
            }
        }
    }

    var isAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability { return true }
        return false
    }

    // docs
    func prewarm() {
        guard isAvailable else { return }
        LanguageModelSession(model: SystemLanguageModel.default).prewarm()
    }


    // docs
    func simplify(
        text: String,
        language: ReadingLanguage = .spanish,
        onPartial: @escaping (String) -> Void
    ) async throws -> String {
        let session = try makeSession()
        let prompt: String
        switch language {
        case .spanish:
            prompt = """
            Simplifica el siguiente texto para un lector de nivel primaria (6-10 años).
            Usa oraciones muy cortas. Palabras comunes. Máximo 4 oraciones.
            No uses palabras difíciles. Responde SOLO con el texto simplificado, sin explicaciones.

            Texto original:
            \(text.prefix(2000))
            """
        case .english:
            prompt = """
            Simplify the following English text for an elementary school reader (6-10 years old).
            Use very short sentences. Common words. Maximum 4 sentences.
            Keep the answer in English. Reply ONLY with the simplified text, no explanations.

            Original text:
            \(text.prefix(2000))
            """
        }
        var final = ""
        let stream = session.streamResponse(to: prompt)
        for try await partial in stream {
            final = partial.content
            onPartial(final)
        }
        return final.trimmingCharacters(in: .whitespacesAndNewlines)
    }


    // docs
    // error
    // prueba
    func define(
        word: String,
        context: String,
        language: ReadingLanguage = .spanish,
        englishMode: EnglishDefinitionMode = .translate
    ) async throws -> WordDefinition {
        let entry = DictionaryStore.shared.lookup(word, language: language)

        // prueba
        // logica

        // logica
        if let properNoun = properNounDefinition(
                for: word, in: context, language: language, englishMode: englishMode
           ) {
            return properNoun
        }

        // prueba
        guard isAvailable else {
            if let entry { return definition(from: entry, for: word) }
            throw AIError.modelUnavailable
        }

        let session = try makeSession()
        let prompt = definePrompt(
            word: word,
            context: context,
            entry: entry, // logica
            language: language,
            englishMode: englishMode
        )

        do {
            let response = try await session.respond(to: prompt)
            let parsed = parseDefinition(from: response.content, for: word)
            let example = validatedExample(parsed.example, word: word, fallback: entry?.example)
            return WordDefinition(word: parsed.word, senses: parsed.senses, example: example)
        } catch {
            if let entry { return definition(from: entry, for: word) }
            throw error
        }
    }

    // docs
    private func properNounDefinition(
        for word: String,
        in context: String,
        language: ReadingLanguage,
        englishMode: EnglishDefinitionMode
    ) -> WordDefinition? {
        guard let first = word.first, first.isUppercase else { return nil }

        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = context
        guard let range = context.range(of: word) else { return nil }
        let (tag, _) = tagger.tag(
            at: range.lowerBound,
            unit: .word,
            scheme: .nameType
        )
        guard let tag,
              tag == .personalName || tag == .placeName || tag == .organizationName
        else { return nil }

        let inEnglish = language == .english && englishMode == .immersion
        let text: String
        switch tag {
        case .personalName:
            text = inEnglish
                ? "It is a proper noun: the name of a person or character in this text."
                : "Es un nombre propio: así se llama una persona o personaje en este texto."
        case .placeName:
            text = inEnglish
                ? "It is a proper noun: the name of a place in this text."
                : "Es un nombre propio: el nombre de un lugar en este texto."
        default:
            text = inEnglish
                ? "It is a proper noun: the name of an organization or group in this text."
                : "Es un nombre propio: el nombre de una organización o grupo en este texto."
        }
        return WordDefinition(
            word: word,
            senses: [.init(text: text, isCurrent: true)],
            example: nil
        )
    }

    // docs
    private func validatedExample(
        _ example: String?,
        word: String,
        fallback: String?
    ) -> String? {
        if let example, exampleContains(example, word: word) {
            return example
        }
        return fallback
    }

    private func exampleContains(_ example: String, word: String) -> Bool {
        func normalize(_ s: String) -> String {
            s.folding(
                options: [.diacriticInsensitive, .caseInsensitive],
                locale: Locale(identifier: "es")
            )
        }
        let haystack = normalize(example)
        let needle = normalize(word)
        guard !needle.isEmpty else { return false }
        if haystack.contains(needle) { return true }
        // logica
        let stemLength = max(4, needle.count - 2)
        let stem = String(needle.prefix(stemLength))
        return haystack.contains(stem)
    }

    // docs
    // pendiente
    private func definePrompt(
        word: String,
        context: String,
        entry: DictionaryEntry?,
        language: ReadingLanguage,
        englishMode: EnglishDefinitionMode
    ) -> String {
        let format = """
        SIGNIFICADO 1: [...]
        SIGNIFICADO 2: [...] (solo si hay más de un significado)
        SIGNIFICADO 3: [...] (solo si hay tres significados)
        USO_ACTUAL: [número del significado que corresponde al contexto]
        EJEMPLO: [una oración corta de ejemplo usando el significado actual]
        """
        let grounding: String
        if let entry {
            let numbered = entry.definitions.enumerated()
                .map { "\($0.offset + 1). \($0.element)" }
                .joined(separator: "\n")
            grounding = """
            Entrada de diccionario REAL para la palabra "\(word)":
            \(numbered)

            Usa ÚNICAMENTE los significados de esa entrada. NO inventes significados nuevos.
            """
        } else {
            grounding = """
            Considera los significados comunes de la palabra "\(word)".
            """
        }

        switch (language, englishMode) {
        case (.spanish, _):
            return """
            \(grounding)
            Contexto donde se usa: "\(context)"

            Proporciona definiciones claras y objetivas en español, usando lenguaje sencillo pero preciso.
            Las definiciones deben ser informativas y neutral en tono, como las de un diccionario educativo.

            Ejemplo de respuesta correcta para "célula":
            SIGNIFICADO 1: Unidad más pequeña de un ser vivo que puede funcionar por sí sola.
            USO_ACTUAL: 1
            EJEMPLO: Las células forman todos los tejidos del cuerpo humano.

            Responde estrictamente con este formato para "\(word)", sin explicaciones, introducciones ni rodeos:
            \(format)
            """
        case (.english, .translate):
            return """
            La palabra inglesa es "\(word)".
            \(grounding)
            Contexto en inglés donde se usa: "\(context)"

            Proporciona definiciones claras EN ESPAÑOL, usando lenguaje sencillo pero preciso.
            Las definiciones deben ser informativas y neutral en tono, como las de un diccionario educativo.
            Empieza el SIGNIFICADO 1 con la traducción al español entre comillas.

            Ejemplo de respuesta correcta para "cell":
            SIGNIFICADO 1: "célula": Unidad más pequeña de un ser vivo que puede funcionar por sí sola.
            USO_ACTUAL: 1
            EJEMPLO: Cells form all the tissues in the human body.

            Responde estrictamente con este formato para "\(word)", sin explicaciones ni rodeos:
            \(format)
            """
        case (.english, .immersion):
            return """
            The English word is "\(word)".
            \(grounding)
            Context where it is used: "\(context)"

            Provide clear and objective definitions in ENGLISH, using simple but precise language.
            Definitions should be informative and neutral in tone, like those in an educational dictionary.
            Keep the labels exactly as shown (SIGNIFICADO, USO_ACTUAL, EJEMPLO) but write the content in English.

            Example of correct response for "cell":
            SIGNIFICADO 1: The smallest unit of a living thing that can work on its own.
            USO_ACTUAL: 1
            EJEMPLO: Cells form all the tissues in the human body.

            Reply strictly with this format for "\(word)", no explanations or introductions:
            \(format)
            """
        }
    }

    // docs
    private func definition(from entry: DictionaryEntry, for word: String) -> WordDefinition {
        WordDefinition(
            word: word,
            senses: entry.definitions.enumerated().map {
                WordDefinition.Sense(text: $0.element, isCurrent: $0.offset == 0)
            },
            example: entry.example
        )
    }

    private func parseDefinition(from text: String, for word: String) -> WordDefinition {
        var senses: [WordDefinition.Sense] = []
        var useActual: Int = 1
        var example: String? = nil

        let lines = text.components(separatedBy: .newlines)
        var meaningTexts: [Int: String] = [:]

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }

            // logica
            if (trimmed.hasPrefix("SIGNIFICADO") || trimmed.hasPrefix("MEANING")),
               let colonIndex = trimmed.firstIndex(of: ":") {
                let prefix = trimmed[..<colonIndex]
                let content = trimmed[trimmed.index(after: colonIndex)...].trimmingCharacters(in: .whitespaces)

                let numString = prefix.components(separatedBy: .whitespaces).last ?? ""
                if let num = Int(numString) {
                    meaningTexts[num] = content
                }
            } else if (trimmed.hasPrefix("USO_ACTUAL") || trimmed.hasPrefix("CURRENT")),
                      let colonIndex = trimmed.firstIndex(of: ":") {
                let content = trimmed[trimmed.index(after: colonIndex)...].trimmingCharacters(in: .whitespaces)
                useActual = Int(content) ?? 1
            } else if (trimmed.hasPrefix("EJEMPLO") || trimmed.hasPrefix("EXAMPLE")),
                      let colonIndex = trimmed.firstIndex(of: ":") {
                let content = trimmed[trimmed.index(after: colonIndex)...].trimmingCharacters(in: .whitespaces)
                example = content
            }
        }

        let sortedKeys = meaningTexts.keys.sorted()
        for key in sortedKeys {
            if let meaning = meaningTexts[key] {
                senses.append(WordDefinition.Sense(text: meaning, isCurrent: key == useActual))
            }
        }

        // error
        if senses.isEmpty {
            senses.append(WordDefinition.Sense(text: text, isCurrent: true))
        }

        return WordDefinition(word: word, senses: senses, example: example)
    }


    // docs
    func generateQuestions(
        for text: String,
        language: ReadingLanguage = .spanish,
        englishMode: EnglishDefinitionMode = .translate
    ) async throws -> [ComprehensionQuestion] {
        let session = try makeSession()
        let inEnglish = language == .english && englishMode == .immersion
        let prompt: String
        if inEnglish {
            prompt = """
            The user read this text:
            \(text.prefix(1500))

            Generate exactly 3 reading comprehension questions about that text that can be \
            answered with Yes or No. The questions must be simple, for an elementary school \
            child, written in English, and based ONLY on facts stated explicitly in the text. \
            Include at least one question whose correct answer is No.
            """
        } else {
            prompt = """
            El usuario leyó este texto:
            \(text.prefix(1500))

            Genera exactamente 3 preguntas de comprensión lectora sobre ese texto que se \
            respondan con Sí o No. Las preguntas deben ser simples, para un niño de primaria, \
            en español, y basadas SOLO en hechos que el texto dice explícitamente. \
            Incluye al menos una pregunta cuya respuesta correcta sea No.
            """
        }

        let response = try await session.respond(to: prompt, generating: GeneratedQuiz.self)
        let yesNo: [ComprehensionQuestion] = response.content.questions
            .map {
                ComprehensionQuestion(
                    question: $0.text.trimmingCharacters(in: .whitespacesAndNewlines),
                    expectedAnswer: $0.answerIsYes
                )
            }
            .filter { isValidQuestion($0.question) }

        guard !yesNo.isEmpty else {
            throw AIError.generationFailed("No se pudieron interpretar las preguntas.")
        }

        // prueba
        // logica
        // error
        if Self.multipleChoiceEnabled, yesNo.count >= 2 {
            let choice = (try? await generateChoiceQuestions(
                for: text, inEnglish: inEnglish
            )) ?? []
            if !choice.isEmpty {
                return Array(yesNo.prefix(2)) + Array(choice.prefix(2))
            }
        }
        return Array(yesNo.prefix(3))
    }

    // docs
    // El modelo NO genera índices: genera la respuesta correcta + 2 incorrectas.
    // Nosotros insertamos la correcta en una posición aleatoria, así el índice
    // correcto es correcto por construcción y no puede desalinearse.
    private func generateChoiceQuestions(
        for text: String,
        inEnglish: Bool
    ) async throws -> [ComprehensionQuestion] {
        let session = try makeSession()
        let prompt: String
        if inEnglish {
            prompt = """
            The user read this text:
            \(text.prefix(1500))

            Generate exactly 2 multiple-choice reading comprehension questions about that \
            text. For each question, give the correct answer and exactly 2 plausible but \
            incorrect answers. The correct answer MUST be stated explicitly in the text — \
            copy it from the text. The incorrect answers must be clearly false according \
            to the text. Simple language for an elementary school child, in English.
            """
        } else {
            prompt = """
            El usuario leyó este texto:
            \(text.prefix(1500))

            Genera exactamente 2 preguntas de comprensión lectora de opción múltiple sobre \
            ese texto. Para cada pregunta, da la respuesta correcta y exactamente 2 \
            respuestas incorrectas pero creíbles. La respuesta correcta DEBE estar dicha \
            explícitamente en el texto: cópiala del texto. Las respuestas incorrectas \
            deben ser claramente falsas según el texto. Lenguaje simple para un niño de \
            primaria, en español.
            """
        }

        let response = try await session.respond(to: prompt, generating: GeneratedChoiceQuiz.self)
        return response.content.questions.compactMap { q -> ComprehensionQuestion? in
            let question = q.text.trimmingCharacters(in: .whitespacesAndNewlines)
            let correct = q.correctAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
            let wrong = q.wrongAnswers
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty && normalized($0) != normalized(correct) }
            guard isValidQuestion(question),
                  !correct.isEmpty,
                  wrong.count >= 2,
                  answerIsSupported(correct, by: text)
            else { return nil }

            var options = Array(wrong.prefix(2))
            let correctIndex = Int.random(in: 0...options.count)
            options.insert(correct, at: correctIndex)
            return ComprehensionQuestion(
                question: question,
                options: options,
                correctOptionIndex: correctIndex
            )
        }
    }

    // logica
    // Verifica que la respuesta "correcta" del modelo realmente esté respaldada
    // por el texto. Si no aparece (literal o por palabras clave), se descarta la
    // pregunta en lugar de mostrar una respuesta inventada.
    private func answerIsSupported(_ answer: String, by text: String) -> Bool {
        let haystack = normalized(text)
        let needle = normalized(answer)
            .trimmingCharacters(in: CharacterSet.punctuationCharacters.union(.whitespaces))
        guard !needle.isEmpty else { return false }
        if haystack.contains(needle) { return true }
        // Respuestas parafraseadas: todas las palabras significativas deben estar en el texto
        let words = needle
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count >= 4 || Int($0) != nil }
        guard !words.isEmpty else { return false }
        return words.allSatisfy { haystack.contains($0) }
    }

    private func normalized(_ s: String) -> String {
        s.folding(
            options: [.diacriticInsensitive, .caseInsensitive],
            locale: Locale(identifier: "es")
        )
        .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // docs
    private func isValidQuestion(_ question: String) -> Bool {
        guard question.count >= 8 else { return false }
        let normalized = question.lowercased()
            .trimmingCharacters(in: CharacterSet(charactersIn: "¿?¡!. "))
        return normalized != "pregunta" && normalized != "question"
    }


    func summarize(
        text: String,
        language: ReadingLanguage = .spanish,
        englishMode: EnglishDefinitionMode = .translate
    ) async throws -> String {
        let session = try makeSession()
        let prompt: String
        if language == .english && englishMode == .immersion {
            prompt = """
            Summarize the following text in exactly 2 simple sentences, in English.
            For an elementary school reader. No introduction, just the summary.

            Text:
            \(text.prefix(1000))
            """
        } else {
            prompt = """
            Resume el siguiente texto en exactamente 2 oraciones simples, en español.
            Para un lector de primaria. Sin introducción, solo el resumen.

            Texto:
            \(text.prefix(1000))
            """
        }
        let response = try await session.respond(to: prompt)
        return response.content.trimmingCharacters(in: .whitespacesAndNewlines)
    }


    // docs
    // error
    func syllabify(word: String) async throws -> [String] {
        let session = try makeSession()
        let prompt = """
        Divide the English word "\(word)" into syllables.
        Reply ONLY with the word divided by hyphens, nothing else.
        Example: butterfly → but-ter-fly
        """
        let response = try await session.respond(to: prompt)
        let cleaned = response.content
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        let parts = cleaned
            .components(separatedBy: CharacterSet(charactersIn: "-·•"))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let target = word.lowercased().filter { $0.isLetter }
        guard parts.count > 1, parts.joined() == target else {
            throw AIError.generationFailed("La división en sílabas no coincide con la palabra.")
        }
        return parts
    }


    // Chat sobre el texto abierto (Apple Intelligence).
    // Se reutiliza la misma sesión mientras sea el mismo texto/idioma, así el
    // modelo recuerda las preguntas anteriores (conversación multi-turno).
    private var chatSession: LanguageModelSession?
    private var chatContextKey: String?

    func resetChat() {
        chatSession = nil
        chatContextKey = nil
    }

    func ask(
        question: String,
        about text: String,
        language: ReadingLanguage = .spanish,
        englishMode: EnglishDefinitionMode = .translate,
        onPartial: @escaping (String) -> Void
    ) async throws -> String {
        let model = SystemLanguageModel.default
        guard case .available = model.availability else {
            throw AIError.modelUnavailable
        }

        let key = "\(language)|\(englishMode)|\(text.hashValue)"
        if chatSession == nil || chatContextKey != key {
            chatSession = LanguageModelSession(
                model: model,
                instructions: chatInstructions(
                    for: text, language: language, englishMode: englishMode
                )
            )
            chatContextKey = key
        }
        guard let session = chatSession, !session.isResponding else {
            throw AIError.generationFailed("Espera a que termine la respuesta anterior.")
        }

        do {
            var final = ""
            let stream = session.streamResponse(to: question)
            for try await partial in stream {
                final = partial.content
                onPartial(final)
            }
            return final.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            // Si la conversación creció demasiado o falló, se reinicia la sesión
            // para que la siguiente pregunta empiece limpia.
            resetChat()
            throw error
        }
    }

    private func chatInstructions(
        for text: String,
        language: ReadingLanguage,
        englishMode: EnglishDefinitionMode
    ) -> String {
        let inEnglish = language == .english && englishMode == .immersion
        if inEnglish {
            return """
            You are a friendly reading assistant for a person with dyslexia.
            The user is reading this text:
            ---
            \(text.prefix(3000))
            ---
            Answer their questions about the text in English.
            Use short sentences and simple words. Maximum 3 sentences per answer.
            Base every answer ONLY on the text. If the answer is not in the text, \
            say so clearly instead of guessing.
            """
        }
        return """
        Eres un asistente de lectura amable para una persona con dislexia.
        El usuario está leyendo este texto:
        ---
        \(text.prefix(3000))
        ---
        Responde sus preguntas sobre el texto en español.
        Usa oraciones cortas y palabras sencillas. Máximo 3 oraciones por respuesta.
        Basa cada respuesta ÚNICAMENTE en el texto. Si la respuesta no está en el \
        texto, dilo claramente en lugar de adivinar.
        """
    }

    private func makeSession() throws -> LanguageModelSession {
        let model = SystemLanguageModel.default
        guard case .available = model.availability else {
            throw AIError.modelUnavailable
        }
        return LanguageModelSession(model: model)
    }
}


// docs
@Generable
struct GeneratedQuiz {
    @Guide(description: "Exactamente 3 preguntas de comprensión de sí o no sobre el texto leído")
    var questions: [GeneratedQuizQuestion]
}

@Generable
struct GeneratedQuizQuestion {
    @Guide(description: "Una pregunta corta y simple que se responde con sí o no")
    var text: String
    @Guide(description: "true si la respuesta correcta es sí, false si es no")
    var answerIsYes: Bool
}

// prueba
@Generable
struct GeneratedChoiceQuiz {
    @Guide(description: "Exactamente 2 preguntas de opción múltiple sobre el texto leído")
    var questions: [GeneratedChoiceQuestion]
}

@Generable
struct GeneratedChoiceQuestion {
    @Guide(description: "Una pregunta corta y simple sobre el texto")
    var text: String
    @Guide(description: "La respuesta correcta, copiada explícitamente del texto")
    var correctAnswer: String
    @Guide(description: "Exactamente 2 respuestas incorrectas pero creíbles, cortas")
    var wrongAnswers: [String]
}
