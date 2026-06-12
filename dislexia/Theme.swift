import SwiftUI

extension Color {
    static let menta = Color(hex: "#36D1B4")
    static let azulPrincipal = Color(hex: "#3B82F6")
    static let azulClaro = Color(hex: "#60A5FA")
    static let moradoPrincipal = Color(hex: "#8B5CF6")
    static let moradoSuave = Color(hex: "#C4B5FD")
    
    static let blancoPrincipal = Color(hex: "#FAFAFF")
    static let grisClaro = Color(hex: "#F4F4F8")
    static let lavandaClara = Color(hex: "#EDE9FE")
    
    static let textoPrincipal = Color(hex: "#1F2937")
    static let textoSecundario = Color(hex: "#6B7280")
    
    static let clarityTeal = menta
    static let clarityBlue = azulPrincipal
    static let clarityCyan = azulClaro
}

extension LinearGradient {
    static let clarityGradient = LinearGradient(
        colors: [
            Color.menta,
            Color.azulPrincipal,
            Color.moradoPrincipal
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
}

extension ShapeStyle where Self == Color {
    static var clarityCardStroke: Color { Color.primary.opacity(0.08) }
}

// Fuente global de la interfaz: respeta la opción "OpenDyslexic en toda la app".
// Las vistas usan .font(.app(.headline)) en lugar de .font(.headline) para que
// la tipografía accesible se aplique a todo, no solo al texto de lectura.
extension Font {

    @MainActor
    static func app(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        guard AppPreferences.shared.useOpenDyslexic,
              AppPreferences.shared.dyslexicFontEverywhere,
              UIFont(name: "OpenDyslexic", size: 17) != nil else {
            return .system(style).weight(weight)
        }
        let name = Self.isBold(weight) ? "OpenDyslexic-Bold" : "OpenDyslexic"
        // OpenDyslexic dibuja más grande que la fuente del sistema: se compensa
        let size = UIFont.preferredFont(forTextStyle: style.uiKitStyle).pointSize * 0.92
        return .custom(name, size: size, relativeTo: style)
    }

    @MainActor
    static func app(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        guard AppPreferences.shared.useOpenDyslexic,
              AppPreferences.shared.dyslexicFontEverywhere,
              UIFont(name: "OpenDyslexic", size: 17) != nil else {
            return .system(size: size, weight: weight)
        }
        let name = Self.isBold(weight) ? "OpenDyslexic-Bold" : "OpenDyslexic"
        return .custom(name, size: size * 0.92)
    }

    private static func isBold(_ weight: Font.Weight) -> Bool {
        switch weight {
        case .semibold, .bold, .heavy, .black: return true
        default: return false
        }
    }
}

private extension Font.TextStyle {
    var uiKitStyle: UIFont.TextStyle {
        switch self {
        case .largeTitle:  return .largeTitle
        case .title:       return .title1
        case .title2:      return .title2
        case .title3:      return .title3
        case .headline:    return .headline
        case .subheadline: return .subheadline
        case .body:        return .body
        case .callout:     return .callout
        case .footnote:    return .footnote
        case .caption:     return .caption1
        case .caption2:    return .caption2
        @unknown default:  return .body
        }
    }
}
