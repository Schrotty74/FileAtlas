//
//  Theme_CleanLight.swift
//  FileIndexer Design Exploration — Vorschlag 2 „Clean Light"
//
//  Vollständig eigenständig. Kein geteilter Code mit anderen Designs.
//

import SwiftUI

/// Design-Tokens für den „Clean Light"-Entwurf.
struct CleanLightTheme {

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

    static let theme = CleanLightTheme(
        name: "Clean Light",
        accentColor: Color(red: 0.36, green: 0.40, blue: 0.78),    // gedämpftes Indigo
        secondaryColor: Color(red: 0.58, green: 0.60, blue: 0.66),
        sidebarStyle: .ultraThin,                                  // maximale Transparenz
        fontStyle: .default,
        cornerRadius: 12,
        rowHeight: 46,                                             // viel Luft
        useVibrantLabels: false
    )

    // MARK: - Farbpalette

    static let windowBackground = Color(red: 0.96, green: 0.97, blue: 0.98)
    static let surface          = Color.white
    static let surfaceSubtle    = Color(red: 0.94, green: 0.95, blue: 0.97)
    static let textPrimary      = Color(red: 0.13, green: 0.14, blue: 0.17)
    static let textSecondary    = Color(red: 0.52, green: 0.55, blue: 0.60)
}
