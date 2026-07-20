//
//  Theme.swift
//  FileAtlas
//
//  Zentrale, zur Laufzeit waehlbare Farbpaletten.
//

import SwiftUI
import AppKit

/// Design-Tokens der App. Die Palette wird durch `AppearanceManager` gespeichert;
/// ihre hellen und dunklen Werte folgen weiterhin der gewaehlten Appearance.
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

    private struct Palette {
        let name: String
        let accentColor: Color
        let secondaryColor: Color
        let windowBackground: Color
        let surface: Color
        let surfaceRaised: Color
        let stroke: Color
        let gold: Color
        let textPrimary: Color
        let textSecondary: Color

        var appTheme: AppTheme {
            AppTheme(
                name: name,
                accentColor: accentColor,
                secondaryColor: secondaryColor,
                sidebarStyle: .thin,
                fontStyle: .default,
                cornerRadius: 8,
                rowHeight: 28,
                useVibrantLabels: true
            )
        }
    }

    private static var selectedTheme: ColorTheme {
        guard let rawValue = UserDefaults.standard.string(forKey: AppearanceManager.colorThemeKey),
              let theme = ColorTheme(rawValue: rawValue) else {
            return .midnightTeal
        }
        return theme
    }

    private static var palette: Palette {
        switch selectedTheme {
        case .midnightTeal:
            Palette(
                name: "Midnight Teal",
                accentColor: Color(red: 0.13, green: 0.66, blue: 0.62),
                secondaryColor: Color(red: 0.50, green: 0.58, blue: 0.66),
                windowBackground: Color(light: Color(red: 0.96, green: 0.97, blue: 0.98), dark: Color(red: 0.045, green: 0.07, blue: 0.12)),
                surface: Color(light: .white, dark: Color(red: 0.07, green: 0.10, blue: 0.16)),
                surfaceRaised: Color(light: Color(red: 0.93, green: 0.95, blue: 0.97), dark: Color(red: 0.10, green: 0.14, blue: 0.21)),
                stroke: Color(light: Color(red: 0.80, green: 0.84, blue: 0.88), dark: Color(red: 0.16, green: 0.22, blue: 0.30)),
                gold: Color(red: 0.85, green: 0.70, blue: 0.36),
                textPrimary: Color(light: Color(red: 0.12, green: 0.14, blue: 0.17), dark: Color(red: 0.88, green: 0.92, blue: 0.95)),
                textSecondary: Color(light: Color(red: 0.40, green: 0.46, blue: 0.52), dark: Color(red: 0.48, green: 0.56, blue: 0.64))
            )
        case .retro:
            Palette(
                name: "Retro",
                accentColor: Color(red: 0.78, green: 0.48, blue: 0.18),
                secondaryColor: Color(red: 0.43, green: 0.56, blue: 0.43),
                windowBackground: Color(light: Color(red: 0.96, green: 0.95, blue: 0.89), dark: Color(red: 0.10, green: 0.11, blue: 0.08)),
                surface: Color(light: Color(red: 1.0, green: 0.99, blue: 0.94), dark: Color(red: 0.14, green: 0.14, blue: 0.10)),
                surfaceRaised: Color(light: Color(red: 0.91, green: 0.90, blue: 0.81), dark: Color(red: 0.20, green: 0.19, blue: 0.13)),
                stroke: Color(light: Color(red: 0.72, green: 0.70, blue: 0.59), dark: Color(red: 0.31, green: 0.29, blue: 0.20)),
                gold: Color(red: 0.86, green: 0.63, blue: 0.22),
                textPrimary: Color(light: Color(red: 0.16, green: 0.18, blue: 0.12), dark: Color(red: 0.93, green: 0.91, blue: 0.79)),
                textSecondary: Color(light: Color(red: 0.35, green: 0.40, blue: 0.28), dark: Color(red: 0.62, green: 0.66, blue: 0.51))
            )
        case .graphiteLime:
            Palette(
                name: "Graphite Lime",
                accentColor: Color(red: 0.62, green: 0.86, blue: 0.20),
                secondaryColor: Color(red: 0.47, green: 0.57, blue: 0.48),
                windowBackground: Color(light: Color(red: 0.94, green: 0.95, blue: 0.93), dark: Color(red: 0.055, green: 0.065, blue: 0.055)),
                surface: Color(light: Color(red: 0.99, green: 0.99, blue: 0.98), dark: Color(red: 0.09, green: 0.10, blue: 0.09)),
                surfaceRaised: Color(light: Color(red: 0.88, green: 0.90, blue: 0.86), dark: Color(red: 0.15, green: 0.17, blue: 0.15)),
                stroke: Color(light: Color(red: 0.72, green: 0.75, blue: 0.70), dark: Color(red: 0.25, green: 0.29, blue: 0.24)),
                gold: Color(red: 0.87, green: 0.72, blue: 0.24),
                textPrimary: Color(light: Color(red: 0.13, green: 0.15, blue: 0.13), dark: Color(red: 0.90, green: 0.93, blue: 0.88)),
                textSecondary: Color(light: Color(red: 0.34, green: 0.39, blue: 0.34), dark: Color(red: 0.56, green: 0.64, blue: 0.55))
            )
        case .autumn:
            Palette(
                name: "Autumn",
                accentColor: Color(red: 0.78, green: 0.28, blue: 0.16),
                secondaryColor: Color(red: 0.57, green: 0.49, blue: 0.25),
                windowBackground: Color(light: Color(red: 0.98, green: 0.94, blue: 0.90), dark: Color(red: 0.12, green: 0.07, blue: 0.055)),
                surface: Color(light: Color(red: 1.0, green: 0.98, blue: 0.96), dark: Color(red: 0.17, green: 0.10, blue: 0.075)),
                surfaceRaised: Color(light: Color(red: 0.94, green: 0.86, blue: 0.79), dark: Color(red: 0.25, green: 0.14, blue: 0.10)),
                stroke: Color(light: Color(red: 0.78, green: 0.65, blue: 0.55), dark: Color(red: 0.38, green: 0.22, blue: 0.16)),
                gold: Color(red: 0.91, green: 0.62, blue: 0.15),
                textPrimary: Color(light: Color(red: 0.22, green: 0.12, blue: 0.08), dark: Color(red: 0.96, green: 0.89, blue: 0.82)),
                textSecondary: Color(light: Color(red: 0.46, green: 0.29, blue: 0.20), dark: Color(red: 0.70, green: 0.52, blue: 0.41))
            )
        case .winter:
            Palette(
                name: "Winter",
                accentColor: Color(red: 0.25, green: 0.63, blue: 0.82),
                secondaryColor: Color(red: 0.47, green: 0.57, blue: 0.70),
                windowBackground: Color(light: Color(red: 0.94, green: 0.97, blue: 0.99), dark: Color(red: 0.04, green: 0.09, blue: 0.14)),
                surface: Color(light: Color(red: 0.99, green: 1.0, blue: 1.0), dark: Color(red: 0.07, green: 0.13, blue: 0.19)),
                surfaceRaised: Color(light: Color(red: 0.87, green: 0.93, blue: 0.97), dark: Color(red: 0.11, green: 0.20, blue: 0.28)),
                stroke: Color(light: Color(red: 0.69, green: 0.79, blue: 0.87), dark: Color(red: 0.19, green: 0.31, blue: 0.40)),
                gold: Color(red: 0.75, green: 0.84, blue: 0.93),
                textPrimary: Color(light: Color(red: 0.10, green: 0.18, blue: 0.25), dark: Color(red: 0.88, green: 0.95, blue: 0.99)),
                textSecondary: Color(light: Color(red: 0.34, green: 0.47, blue: 0.59), dark: Color(red: 0.52, green: 0.68, blue: 0.79))
            )
        case .glass:
            Palette(
                name: "Glass",
                accentColor: Color(red: 0.13, green: 0.66, blue: 0.62),
                secondaryColor: Color(red: 0.52, green: 0.66, blue: 0.76),
                windowBackground: Color(light: Color.white.opacity(0.34), dark: Color(red: 0.05, green: 0.10, blue: 0.16).opacity(0.48)),
                surface: Color(light: Color.white.opacity(0.42), dark: Color(red: 0.08, green: 0.14, blue: 0.21).opacity(0.54)),
                surfaceRaised: Color(light: Color.white.opacity(0.56), dark: Color(red: 0.14, green: 0.22, blue: 0.30).opacity(0.64)),
                stroke: Color(light: Color.white.opacity(0.68), dark: Color.white.opacity(0.20)),
                gold: Color(red: 0.85, green: 0.70, blue: 0.36),
                textPrimary: Color(light: Color(red: 0.025, green: 0.07, blue: 0.12), dark: Color(red: 0.96, green: 0.98, blue: 1.0)),
                textSecondary: Color(light: Color(red: 0.12, green: 0.27, blue: 0.40), dark: Color(red: 0.70, green: 0.82, blue: 0.90))
            )
        }
    }

    static var usesWindowGlass: Bool { selectedTheme == .glass }
    static var theme: AppTheme { palette.appTheme }
    static var windowBackground: Color { palette.windowBackground }
    static var surface: Color { palette.surface }
    static var surfaceRaised: Color { palette.surfaceRaised }
    static var stroke: Color { palette.stroke }
    static var gold: Color { palette.gold }
    static var textPrimary: Color { palette.textPrimary }
    static var textSecondary: Color { palette.textSecondary }
}

// MARK: - Appearance-adaptive color

extension Color {
    /// Creates a color that resolves for the currently active light or dark app appearance.
    init(light: Color, dark: Color) {
        self = Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            switch appearance.bestMatch(from: [.aqua, .darkAqua]) {
            case .darkAqua: return NSColor(dark)
            default: return NSColor(light)
            }
        }))
    }
}

// MARK: - Convenience accessors

extension AppTheme {
    static var current: AppTheme { theme }

    var windowBackground: Color { AppTheme.windowBackground }
    var surface: Color { AppTheme.surface }
    var surfaceRaised: Color { AppTheme.surfaceRaised }
    var stroke: Color { AppTheme.stroke }
    var gold: Color { AppTheme.gold }
    var textPrimary: Color { AppTheme.textPrimary }
    var textSecondary: Color { AppTheme.textSecondary }
}

extension ShapeStyle where Self == Color {
    static var accentTeal: Color { AppTheme.theme.accentColor }
}
