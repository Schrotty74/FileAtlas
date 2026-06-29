//
//  Theme_FrostedVivid.swift
//  FileIndexer Design Exploration — Vorschlag 5 „Frosted Vivid"
//
//  Vollständig eigenständig. Kein geteilter Code mit anderen Designs.
//

import SwiftUI

/// Design-Tokens für den „Frosted Vivid"-Entwurf.
struct FrostedVividTheme {

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

    static let theme = FrostedVividTheme(
        name: "Frosted Vivid",
        accentColor: Color(red: 0.55, green: 0.30, blue: 0.96),    // leuchtendes Purple
        secondaryColor: Color(red: 0.30, green: 0.55, blue: 0.98), // Electric Blue (Sekundär-Glow)
        sidebarStyle: .ultraThin,                                  // maximales Frosted Glass
        fontStyle: .default,
        cornerRadius: 18,
        rowHeight: 52,
        useVibrantLabels: true
    )

    // MARK: - Farbpalette (neutral, damit der Akzent knallt)

    static let windowBackground = Color(red: 0.10, green: 0.10, blue: 0.13)
    static let surface          = Color(red: 0.13, green: 0.13, blue: 0.17)
    static let surfaceRaised    = Color(red: 0.17, green: 0.17, blue: 0.22)
    static let textPrimary      = Color(red: 0.95, green: 0.95, blue: 0.98)
    static let textSecondary    = Color(red: 0.62, green: 0.63, blue: 0.70)

    /// Lebendiger Hintergrund-Verlauf, damit das Frosted Glass sichtbar wird.
    static let wallpaper = LinearGradient(
        colors: [
            Color(red: 0.42, green: 0.20, blue: 0.85),
            Color(red: 0.20, green: 0.32, blue: 0.92),
            Color(red: 0.55, green: 0.22, blue: 0.70),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
