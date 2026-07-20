//
//  AppearanceManager.swift
//  FileAtlas
//
//  Systemunabhängiges Erscheinungsbild (Hell / Dunkel / System), persistiert.
//

import SwiftUI
import AppKit

@Observable
@MainActor
final class AppearanceManager {

    private static let key = "FileAtlas.appearanceMode"
    nonisolated static let colorThemeKey = "FileAtlas.colorTheme"
    private let defaults: UserDefaults
    private let appliesToApplication: Bool

    var mode: AppearanceMode {
        didSet {
            defaults.set(mode.rawValue, forKey: Self.key)
            applyToApp()
        }
    }

    var colorTheme: ColorTheme {
        didSet {
            defaults.set(colorTheme.rawValue, forKey: Self.colorThemeKey)
        }
    }

    init(defaults: UserDefaults = .standard, appliesToApplication: Bool = true) {
        self.defaults = defaults
        self.appliesToApplication = appliesToApplication
        let stored = defaults.string(forKey: Self.key)
        self.mode = stored.flatMap(AppearanceMode.init(rawValue:)) ?? .system
        let storedTheme = defaults.string(forKey: Self.colorThemeKey)
        self.colorTheme = storedTheme.flatMap(ColorTheme.init(rawValue:)) ?? .midnightTeal
        applyToApp()
    }

    /// `nil` = dem System folgen.
    var colorScheme: ColorScheme? {
        switch mode {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }

    /// Setzt die Appearance fensterübergreifend auf `NSApplication`.
    ///
    /// Notwendig, weil `.preferredColorScheme` auf dem WindowGroup-Inhalt die
    /// Sidebar-Spalte einer `NavigationSplitView` auf macOS nicht zuverlässig
    /// mit umschaltet — die App-Appearance dagegen erfasst das gesamte Fenster.
    func applyToApp() {
        guard appliesToApplication else { return }
        let appearance: NSAppearance?
        switch mode {
        case .system: appearance = nil
        case .light:  appearance = NSAppearance(named: .aqua)
        case .dark:   appearance = NSAppearance(named: .darkAqua)
        }
        NSApplication.shared.appearance = appearance
    }
}
