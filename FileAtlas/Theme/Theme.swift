//
//  Theme.swift
//  FileAtlas
//
//  Zentrale Design-Definition. Basiert 1:1 auf „Midnight Teal" (Design 4)
//  aus der Design-Exploration; `MidnightTealTheme` → `AppTheme` umbenannt.
//

import SwiftUI
import AppKit

/// Design-Tokens der App. Wird von allen Views konsistent verwendet.
struct AppTheme {

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

    static let theme = AppTheme(
        name: "Midnight Teal",
        accentColor: Color(red: 0.13, green: 0.66, blue: 0.62),    // Teal / Petrol
        secondaryColor: Color(red: 0.50, green: 0.58, blue: 0.66),
        sidebarStyle: .thin,                                       // dunkles Glas mit Teal-Tint
        fontStyle: .default,
        cornerRadius: 8,
        rowHeight: 28,                                             // kompakteste Tabelle
        useVibrantLabels: true
    )

    // MARK: - Farbpalette
    //
    // Der Dunkel-Modus entspricht 1:1 „Midnight Teal". Der Hell-Modus ergänzt
    // eine helle Variante, damit der Hell/Dunkel-Umschalter beide Modi sauber
    // bedient (Akzent-Teal und Gold bleiben in beiden Modi identisch).

    static let windowBackground = Color(
        light: Color(red: 0.96, green: 0.97, blue: 0.98),
        dark:  Color(red: 0.045, green: 0.07, blue: 0.12))   // tiefes Mitternachtsblau
    static let surface = Color(
        light: Color(red: 1.0, green: 1.0, blue: 1.0),
        dark:  Color(red: 0.07, green: 0.10, blue: 0.16))
    static let surfaceRaised = Color(
        light: Color(red: 0.93, green: 0.95, blue: 0.97),
        dark:  Color(red: 0.10, green: 0.14, blue: 0.21))
    static let stroke = Color(
        light: Color(red: 0.80, green: 0.84, blue: 0.88),
        dark:  Color(red: 0.16, green: 0.22, blue: 0.30))
    static let gold = Color(red: 0.85, green: 0.70, blue: 0.36)    // goldene Status-Highlights
    static let textPrimary = Color(
        light: Color(red: 0.12, green: 0.14, blue: 0.17),
        dark:  Color(red: 0.88, green: 0.92, blue: 0.95))
    static let textSecondary = Color(
        light: Color(red: 0.40, green: 0.46, blue: 0.52),
        dark:  Color(red: 0.48, green: 0.56, blue: 0.64))
}

// MARK: - Appearance-adaptive Farbe

extension Color {
    /// Erzeugt eine Farbe, die je nach aktiver Appearance (Hell/Dunkel) auflöst.
    init(light: Color, dark: Color) {
        self = Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            switch appearance.bestMatch(from: [.aqua, .darkAqua]) {
            case .darkAqua: return NSColor(dark)
            default:        return NSColor(light)
            }
        }))
    }
}

// MARK: - Komfort-Zugriff & Helfer

extension AppTheme {
    /// Aktive Theme-Instanz (Single Source of Truth).
    static var current: AppTheme { .theme }

    // Instanz-Spiegel der Paletten-Farben, damit sowohl `AppTheme.surface`
    // als auch `AppTheme.theme.surface` funktionieren.
    var windowBackground: Color { AppTheme.windowBackground }
    var surface: Color { AppTheme.surface }
    var surfaceRaised: Color { AppTheme.surfaceRaised }
    var stroke: Color { AppTheme.stroke }
    var gold: Color { AppTheme.gold }
    var textPrimary: Color { AppTheme.textPrimary }
    var textSecondary: Color { AppTheme.textSecondary }
}

extension ShapeStyle where Self == Color {
    /// `Color.accentTeal` Kurzform für die Theme-Akzentfarbe.
    static var accentTeal: Color { AppTheme.theme.accentColor }
}
