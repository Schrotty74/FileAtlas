//
//  AppearanceManager.swift
//  FileAtlas
//
//  Systemunabhängiges Erscheinungsbild (Hell / Dunkel / System), persistiert.
//

import SwiftUI
import AppKit

@Observable
final class AppearanceManager {

    private static let key = "FileAtlas.appearanceMode"

    var mode: AppearanceMode {
        didSet {
            UserDefaults.standard.set(mode.rawValue, forKey: Self.key)
            applyToApp()
        }
    }

    init() {
        let stored = UserDefaults.standard.string(forKey: Self.key)
        self.mode = stored.flatMap(AppearanceMode.init(rawValue:)) ?? .system
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
        let appearance: NSAppearance?
        switch mode {
        case .system: appearance = nil
        case .light:  appearance = NSAppearance(named: .aqua)
        case .dark:   appearance = NSAppearance(named: .darkAqua)
        }
        NSApplication.shared.appearance = appearance
    }
}
