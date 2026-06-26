//
//  Theme_MidnightTeal.swift
//  FileIndexer Design Exploration — Vorschlag 4 „Midnight Teal"
//
//  Vollständig eigenständig. Kein geteilter Code mit anderen Designs.
//

import SwiftUI

/// Design-Tokens für den „Midnight Teal"-Entwurf.
struct MidnightTealTheme {

    enum SidebarStyle { case ultraThin, thin, regular, opaque }
    enum FontStyle { case rounded, monospaced, serif, `default` }

    let name: String
    let accentColor: Color
    let secondaryColor: Color
    let sidebarStyle: SidebarStyle
    let fontStyle: FontStyle
    let cornerRadius: CGFloat
    let rowHeight: CGFloat
    let useVibrantLabels: Bool

    static let theme = MidnightTealTheme(
        name: "Midnight Teal",
        accentColor: Color(red: 0.13, green: 0.66, blue: 0.62),    // Teal / Petrol
        secondaryColor: Color(red: 0.50, green: 0.58, blue: 0.66),
        sidebarStyle: .thin,                                       // dunkles Glas mit Teal-Tint
        fontStyle: .default,
        cornerRadius: 8,
        rowHeight: 28,                                             // kompakteste Tabelle der 5
        useVibrantLabels: true
    )

    // MARK: - Farbpalette

    static let windowBackground = Color(red: 0.045, green: 0.07, blue: 0.12)   // tiefes Mitternachtsblau
    static let surface          = Color(red: 0.07, green: 0.10, blue: 0.16)
    static let surfaceRaised    = Color(red: 0.10, green: 0.14, blue: 0.21)
    static let stroke           = Color(red: 0.16, green: 0.22, blue: 0.30)
    static let gold             = Color(red: 0.85, green: 0.70, blue: 0.36)    // goldene Status-Highlights
    static let textPrimary      = Color(red: 0.88, green: 0.92, blue: 0.95)
    static let textSecondary    = Color(red: 0.48, green: 0.56, blue: 0.64)
}
