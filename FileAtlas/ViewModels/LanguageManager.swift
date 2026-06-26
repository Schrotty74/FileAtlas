//
//  LanguageManager.swift
//  FileAtlas
//
//  Sprachsteuerung mit DACH-Regel und manuellem Override, persistiert.
//

import SwiftUI

@Observable
final class LanguageManager {

    private static let key = "FileAtlas.language"

    var language: AppLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: Self.key) }
    }

    init() {
        let stored = UserDefaults.standard.string(forKey: Self.key)
        self.language = stored.flatMap(AppLanguage.init(rawValue:)) ?? .auto
    }

    /// Tatsächlich angewandte Sprache nach Auflösung von `.auto`.
    ///
    /// DACH-Regel: System-Region `DE`, `AT` oder `CH` → Deutsch, sonst Englisch.
    var effectiveLanguage: AppLanguage {
        switch language {
        case .de: return .de
        case .en: return .en
        case .auto:
            let region = Locale.current.region?.identifier ?? ""
            return ["DE", "AT", "CH"].contains(region) ? .de : .en
        }
    }

    /// Locale, das die Views über `\.locale` erhalten.
    var locale: Locale {
        Locale(identifier: effectiveLanguage == .de ? "de" : "en")
    }
}
