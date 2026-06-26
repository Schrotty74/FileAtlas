//
//  AppEnums.swift
//  FileAtlas
//
//  Gemeinsame Aufzählungstypen.
//

import Foundation

/// Sprachwahl der App.
nonisolated enum AppLanguage: String, CaseIterable, Codable, Sendable {
    case auto
    case de
    case en
}

/// Erscheinungsbild (systemunabhängig umschaltbar).
nonisolated enum AppearanceMode: String, CaseIterable, Codable, Sendable {
    case system
    case light
    case dark
}

/// Sortierbare Spalten der Dateitabelle.
nonisolated enum SortField: String, CaseIterable, Codable, Sendable {
    case name
    case size
    case modified
    case created
    case type
}

/// Sortierrichtung.
nonisolated enum SortDirection: String, Codable, Sendable {
    case ascending
    case descending

    mutating func toggle() {
        self = self == .ascending ? .descending : .ascending
    }
}

/// Änderungsstatus im Snapshot-Vergleich.
nonisolated enum ChangeStatus: String, Codable, Sendable {
    case added       // 🟢 Neu
    case removed     // 🔴 Entfernt
    case changed     // 🟡 Geändert
}

/// Unterstützte Export-Formate.
nonisolated enum ExportFormat: String, CaseIterable, Sendable {
    case xlsx
    case pdf
    case csv

    var fileExtension: String { rawValue }
}

/// Manuelle Labels für Dateien. Eigene Tags werden über ihren Titel gespeichert.
nonisolated struct FileTag: Hashable, Codable, Sendable, Identifiable {
    let title: String

    var id: String { title }
    var rawValue: String { title }

    init(_ title: String) {
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    init(rawValue: String) {
        self.init(rawValue)
    }

    static let important = FileTag("Wichtig")
    static let delete = FileTag("Zu löschen")
    static let checked = FileTag("Geprüft")
    static let favorite = FileTag("Favorit")

    static let predefined: [FileTag] = [.important, .delete, .checked, .favorite]
}

/// Persistente Zeilenhöhe der Dateitabelle.
nonisolated enum FileRowDensity: String, CaseIterable, Codable, Sendable, Identifiable {
    case compact
    case normal
    case large

    var id: String { rawValue }

    var title: String {
        switch self {
        case .compact: return "Kompakt"
        case .normal: return "Normal"
        case .large: return "Groß"
        }
    }

    var rowHeight: CGFloat {
        switch self {
        case .compact: return 24
        case .normal: return 32
        case .large: return 44
        }
    }
}
