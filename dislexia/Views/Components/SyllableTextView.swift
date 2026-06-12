import SwiftUI


struct TextToken: Identifiable {
    let id = UUID()
    let text: String
    let isWord: Bool
    let range: Range<String.Index>
}


struct WordFlowLayout: Layout {
    var lineSpacing: CGFloat = 8
    var spacing: CGFloat = 3

    struct CacheData {
        var sizes: [CGSize] = []
    }

    func makeCache(subviews: Subviews) -> CacheData { CacheData() }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout CacheData) -> CGSize {
        let containerWidth = proposal.width ?? 375
        cache.sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        var height: CGFloat = 0
        var x: CGFloat = 0
        var rowHeight: CGFloat = 0
        var firstInRow = true

        for size in cache.sizes {
            if !firstInRow && x + size.width > containerWidth {
                height += rowHeight + lineSpacing
                x = 0
                rowHeight = 0
                firstInRow = true
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            firstInRow = false
        }
        height += rowHeight
        return CGSize(width: containerWidth, height: max(height, 0))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout CacheData) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        var firstInRow = true

        for (subview, size) in zip(subviews, cache.sizes) {
            if !firstInRow && x + size.width > bounds.maxX {
                y += rowHeight + lineSpacing
                x = bounds.minX
                rowHeight = 0
                firstInRow = true
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            firstInRow = false
        }
    }
}


struct SyllableTextView: View {
    let text: String
    let highlightRange: Range<String.Index>?
    let prefs: AppPreferences
    let onWordTap: (String, String) -> Void
    // docs
    var dimInactive: Bool = false
    // docs
    var onWordLongPress: (String) -> Void = { _ in }
    // docs
    var onWordDoubleTap: (String) -> Void = { _ in }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var tokens: [TextToken] { tokenize(text) }

    var body: some View {
        WordFlowLayout(lineSpacing: prefs.lineSpacing, spacing: 3) {
            ForEach(tokens) { token in
                if token.isWord {
                    let highlighted = isHighlighted(token)
                    Text(token.text)
                        .font(.custom(prefs.fontName, size: prefs.fontSize))
                        .tracking(prefs.letterSpacing)
                        .foregroundStyle(prefs.backgroundColor.textColor)
                        .padding(.vertical, 2)
                        .padding(.horizontal, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color.azulPrincipal.opacity(highlighted ? 0.22 : 0))
                                .shadow(
                                    color: Color.azulPrincipal.opacity(highlighted ? 0.45 : 0),
                                    radius: 10,
                                    y: 0
                                )
                        )
                        .scaleEffect(highlighted ? 1.06 : 1.0)
                        .opacity(!dimInactive || highlighted ? 1.0 : 0.35)
                        .animation(
                            reduceMotion ? .none : .spring(response: 0.2, dampingFraction: 0.6),
                            value: highlighted
                        )
                        .animation(
                            reduceMotion ? .none : .easeInOut(duration: 0.3),
                            value: dimInactive
                        )
                        .frame(minWidth: 44, minHeight: 44, alignment: .center)
                        .fixedSize()
                        .contentShape(Rectangle())
                        // logica
                        .onTapGesture(count: 2) {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            onWordDoubleTap(token.text)
                        }
                        .onTapGesture {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            onWordTap(token.text, contextAround(token))
                        }
                        .onLongPressGesture(minimumDuration: 0.4) {
                            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                            onWordLongPress(token.text)
                        }
                        .accessibilityAddTraits(.isButton)
                        .accessibilityLabel(token.text)
                        .accessibilityHint("Toca para la definición, dos veces para las sílabas, mantén presionado para escucharla despacio")
                        .accessibilityAction(named: "Ver sílabas") {
                            onWordDoubleTap(token.text)
                        }
                        .accessibilityAction(named: "Escuchar despacio") {
                            onWordLongPress(token.text)
                        }
                } else {
                    Text(token.text)
                        .font(.custom(prefs.fontName, size: prefs.fontSize))
                        .tracking(prefs.letterSpacing)
                        .foregroundStyle(prefs.backgroundColor.textColor)
                        .opacity(dimInactive ? 0.35 : 1.0)
                        .animation(
                            reduceMotion ? .none : .easeInOut(duration: 0.3),
                            value: dimInactive
                        )
                        .fixedSize()
                }
            }
        }
        .accessibilityLabel(text)
        .accessibilityHint("Toca una palabra para ver su definición")
    }


    // docs
    private func contextAround(_ token: TextToken) -> String {
        let contextStart = text.index(
            token.range.lowerBound,
            offsetBy: -min(250, text.distance(from: text.startIndex, to: token.range.lowerBound)),
            limitedBy: text.startIndex
        ) ?? text.startIndex
        let contextEnd = text.index(
            token.range.upperBound,
            offsetBy: min(250, text.distance(from: token.range.upperBound, to: text.endIndex)),
            limitedBy: text.endIndex
        ) ?? text.endIndex
        return String(text[contextStart..<contextEnd])
    }

    private func isHighlighted(_ token: TextToken) -> Bool {
        guard let highlightRange else { return false }
        return token.range.overlaps(highlightRange)
    }

    private func tokenize(_ text: String) -> [TextToken] {
        var tokens: [TextToken] = []
        guard !text.isEmpty else { return tokens }

        var tokenStart = text.startIndex
        var inWord = text[text.startIndex].isLetter || text[text.startIndex].isNumber

        var idx = text.index(after: text.startIndex)
        while idx < text.endIndex {
            let char = text[idx]
            let isWordChar = char.isLetter || char.isNumber || char == "'" || char == "'"
            if isWordChar != inWord {
                tokens.append(TextToken(
                    text: String(text[tokenStart..<idx]),
                    isWord: inWord,
                    range: tokenStart..<idx
                ))
                tokenStart = idx
                inWord = isWordChar
            }
            idx = text.index(after: idx)
        }

        tokens.append(TextToken(
            text: String(text[tokenStart...]),
            isWord: inWord,
            range: tokenStart..<text.endIndex
        ))

        return tokens
    }
}

#Preview {
    ScrollView {
        SyllableTextView(
            text: "El sol brilla de día. La luna brilla de noche. El sol es grande y amarillo.",
            highlightRange: nil,
            prefs: AppPreferences.shared,
            onWordTap: { word, _ in print("Tapped: \(word)") }
        )
        .padding()
    }
}
