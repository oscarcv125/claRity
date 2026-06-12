import SwiftUI

/// Typed navigation destinations for NavigationStack.
/// LibraryView owns the NavigationStack; push routes by setting selectedItem.
enum Route: Hashable {
    case reader(LibraryItem)
    case settings
    case comprehension
}
