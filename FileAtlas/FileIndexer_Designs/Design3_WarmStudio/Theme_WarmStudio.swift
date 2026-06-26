//
//  Theme_WarmStudio.swift
//  FileIndexer Design Exploration — Vorschlag 3 „Warm Studio"
//
//  Vollständig eigenständig. Kein geteilter Code mit anderen Designs.
//

import SwiftUI

/// Design-Tokens für den „Warm Studio"-Entwurf.
struct WarmStudioTheme {

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

    static let theme = WarmStudioTheme(
        name: "Warm Studio",
        accentColor: Color(red: 0.95, green: 0.52, blue: 0.20),    // warmes Orange
        secondaryColor: Color(red: 0.62, green: 0.54, blue: 0.46),
        sidebarStyle: .regular,                                    // mittleres Glas, warm getönt
        fontStyle: .rounded,
        cornerRadius: 16,
        rowHeight: 64,                                             // große Icons/Thumbnails
        useVibrantLabels: true
    )

    // MARK: - Farbpalette (warme Töne)

    static let windowBackground = Color(red: 0.96, green: 0.93, blue: 0.88)   // getöntes Off-White / Sand
    static let surface          = Color(red: 0.98, green: 0.96, blue: 0.92)
    static let surfaceRaised    = Color(red: 1.0, green: 0.99, blue: 0.96)
    static let warmTint         = Color(red: 0.98, green: 0.86, blue: 0.72)
    static let textPrimary      = Color(red: 0.24, green: 0.18, blue: 0.12)
    static let textSecondary    = Color(red: 0.55, green: 0.46, blue: 0.38)
}
