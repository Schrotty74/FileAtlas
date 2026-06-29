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
    var extensionWhitelistEnabled: Bool
    var extensionWhitelist: [String]
    var minSize: Int64?
    var maxSize: Int64?

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case includedExtensions
        case excludedExtensions
        case extensionWhitelistEnabled
        case extensionWhitelist
        case minSize
        case maxSize
    }

    init(
        id: UUID = UUID(),
        name: String,
        includedExtensions: [String] = [],
        excludedExtensions: [String] = [],
        extensionWhitelistEnabled: Bool = false,
        extensionWhitelist: [String] = [],
        minSize: Int64? = nil,
        maxSize: Int64? = nil
    ) {
        self.id = id
        self.name = name
        self.includedExtensions = includedExtensions
        self.excludedExtensions = excludedExtensions
        self.extensionWhitelistEnabled = extensionWhitelistEnabled
        self.extensionWhitelist = extensionWhitelist.map(FilterPreset.normalize).filter { !$0.isEmpty }
        self.minSize = minSize
        self.maxSize = maxSize
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        includedExtensions = try container.decodeIfPresent([String].self, forKey: .includedExtensions) ?? []
        excludedExtensions = try container.decodeIfPresent([String].self, forKey: .excludedExtensions) ?? []
        extensionWhitelistEnabled = try container.decodeIfPresent(Bool.self, forKey: .extensionWhitelistEnabled) ?? false
        let whitelist = try container.decodeIfPresent([String].self, forKey: .extensionWhitelist) ?? []
        extensionWhitelist = whitelist.map(FilterPreset.normalize).filter { !$0.isEmpty }
        minSize = try container.decodeIfPresent(Int64.self, forKey: .minSize) ?? nil
        maxSize = try container.decodeIfPresent(Int64.self, forKey: .maxSize) ?? nil
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

        if extensionWhitelistEnabled {
            let whitelisted = Set(extensionWhitelist.map(FilterPreset.normalize))
            if !whitelisted.isEmpty && !whitelisted.contains(ext) { return false }
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
