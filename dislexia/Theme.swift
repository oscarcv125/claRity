import SwiftUI

/// Paleta central de ClaRity — derivada del mesh azul-teal del hero.
/// Regla de diseño: el ÚNICO gradiente de la app vive en el hero de LibraryView.
/// Todo lo demás usa estos colores sólidos.
extension Color {
    /// Color de marca principal (teal).
    static let clarityTeal = Color(hex: "#0D9488")
    /// Azul de apoyo para iconografía secundaria.
    static let clarityBlue = Color(hex: "#0284C7")
    /// Acento claro para detalles pequeños.
    static let clarityCyan = Color(hex: "#2DD4BF")
}

extension ShapeStyle where Self == Color {
    /// Borde sutil para tarjetas glass — se adapta a light/dark mode.
    static var clarityCardStroke: Color { Color.primary.opacity(0.08) }
}
