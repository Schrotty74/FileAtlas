//
//  Theme_ProDark.swift
//  FileIndexer Design Exploration — Vorschlag 1 „Pro Dark"
//
//  Vollständig eigenständig. Kein geteilter Code mit anderen Designs.
//

import SwiftUI

/// Design-Tokens für den „Pro Dark"-Entwurf (entspricht der `ThemeDefinition`
/// aus dem Briefing, hier eindeutig benannt, damit es modulweit nicht mit den
/// Tokens der anderen vier Designs kollidiert).
struct ProDarkTheme {

    /// Glas-Ausprägung der Sidebar.
    enum SidebarStyle { case ultraThin, thin, regular, opaque }

    /// Schrift-Charakter über `.fontDesign()`.
    enum FontStyle { case rounded, monospaced, serif, `default` }

    let name: String
    let accentColor: Color
    let secondaryColor: Color
    let sidebarStyle: SidebarStyle
    let fontStyle: FontStyle
    let cornerRadius: CGFloat
    let rowHeight: CGFloat
    let useVibrantLabels: Bool

    /// Konkrete Token-Ausprägung dieses Designs.
    static let theme = ProDarkTheme(
        name: "Pro Dark",
        accentColor: Color(red: 0.16, green: 0.97, blue: 0.74),   // leuchtendes Mint/Cyan
        secondaryColor: Color(red: 0.55, green: 0.60, blue: 0.66),
        sidebarStyle: .opaque,                                     // sehr dunkles Glas, kaum Transparenz
        fontStyle: .monospaced,
        cornerRadius: 6,
        rowHeight: 30,
        useVibrantLabels: false
    )

    // MARK: - Farbpalette

    static let windowBackground = Color(red: 0.05, green: 0.055, blue: 0.065)
    static let surface          = Color(red: 0.085, green: 0.095, blue: 0.11)
    static let surfaceRaised    = Color(red: 0.13, green: 0.145, blue: 0.165)
    static let stroke           = Color(red: 0.20, green: 0.22, blue: 0.25)
    static let textPrimary      = Color(red: 0.90, green: 0.92, blue: 0.94)
    static let textSecondary    = Color(red: 0.50, green: 0.55, blue: 0.60)
}
