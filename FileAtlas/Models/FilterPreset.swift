//
//  FilterPreset.swift
//  FileAtlas
//

import Foundation

/// Ein gespeichertes Regelset für Ein-/Ausschluss von Dateien.
nonisolated struct FilterPreset: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var name: String
    var includedExtensions: [String]   // leer = alle erlaubt
    var excludedExtensions: [String]   // z. B. ["DS_Store", "log", "tmp"]
    var minSize: Int64?
    var maxSize: Int64?

    init(
        id: UUID = UUID(),
        name: String,
        includedExtensions: [String] = [],
        excludedExtensions: [String] = [],
        minSize: Int64? = nil,
        maxSize: Int64? = nil
    ) {
        self.id = id
        self.name = name
        self.includedExtensions = includedExtensions
        self.excludedExtensions = excludedExtensions
        self.minSize = minSize
        self.maxSize = maxSize
    }

    /// Normalisiert eine Erweiterung (klein, ohne führenden Punkt).
    static func normalize(_ ext: String) -> String {
        var e = ext.trimmingCharacters(in: .whitespaces).lowercased()
        while e.hasPrefix(".") { e.removeFirst() }
        return e
    }

    /// Prüft, ob ein `FileEntry` diesen Filter passiert.
    func allows(_ entry: FileEntry) -> Bool {
        let ext = FilterPreset.normalize(entry.fileExtension)

        if !includedExtensions.isEmpty {
            let included = Set(includedExtensions.map(FilterPreset.normalize))
            // Datei muss eine der eingeschlossenen Erweiterungen haben.
            if !entry.isDirectory && !included.contains(ext) { return false }
        }

        let excluded = Set(excludedExtensions.map(FilterPreset.normalize))
        // Sowohl Erweiterung als auch der „versteckte" Basisname (z. B. .DS_Store) prüfen.
        if excluded.contains(ext) { return false }
        let baseName = FilterPreset.normalize(entry.name)
        if excluded.contains(baseName) { return false }

        if let minSize, entry.size < minSize { return false }
        if let maxSize, entry.size > maxSize { return false }

        return true
    }
}

// MARK: - Standard-Presets

extension FilterPreset {
    /// Mitgelieferte Standard-Presets.
    static let bundled: [FilterPreset] = [
        FilterPreset(
            name: "Nur Bilder",
            includedExtensions: ["jpg", "jpeg", "png", "heic", "gif", "webp", "tiff"]
        ),
        FilterPreset(
            name: "Nur Dokumente",
            includedExtensions: ["pdf", "docx", "pages", "txt", "md", "xlsx"]
        ),
        FilterPreset(
            name: "Systemmüll ausblenden",
            excludedExtensions: ["DS_Store", "localized", "log", "tmp"]
        ),
        FilterPreset(
            name: "Keine RAW-Dateien",
            excludedExtensions: ["raw", "cr2", "cr3", "arw", "nef", "dng"]
        ),
    ]

    /// Häufige Ausschluss-Kandidaten für die Vorschlagsliste.
    static let suggestedExclusions: [String] = [
        "DS_Store", "log", "tmp", "Thumbs.db", "localized",
    ]
}
