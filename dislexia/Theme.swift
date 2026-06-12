import SwiftUI

/// Paleta central de ClaRity — actualizada con los colores de marca solicitados.
extension Color {
    // Colores principales
    static let menta = Color(hex: "#36D1B4")
    static let azulPrincipal = Color(hex: "#3B82F6")
    static let azulClaro = Color(hex: "#60A5FA")
    static let moradoPrincipal = Color(hex: "#8B5CF6")
    static let moradoSuave = Color(hex: "#C4B5FD")
    
    // Neutros / Fondos
    static let blancoPrincipal = Color(hex: "#FAFAFF")
    static let grisClaro = Color(hex: "#F4F4F8")
    static let lavandaClara = Color(hex: "#EDE9FE")
    
    // Texto
    static let textoPrincipal = Color(hex: "#1F2937")
    static let textoSecundario = Color(hex: "#6B7280")
    
    // Alias temporales para retrocompatibilidad
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
    /// Borde sutil para tarjetas glass — se adapta a light/dark mode.
    static var clarityCardStroke: Color { Color.primary.opacity(0.08) }
}
