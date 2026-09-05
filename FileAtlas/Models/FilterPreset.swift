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
    var appliesToAllFolders: Bool
    var scopedFolderPaths: [String]
    var minSize: Int64?
    var maxSize: Int64?

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case includedExtensions
        case excludedExtensions
        case extensionWhitelistEnabled
        case extensionWhitelist
        case appliesToAllFolders
        case scopedFolderPaths
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
        appliesToAllFolders: Bool = true,
        scopedFolderPaths: [String] = [],
        minSize: Int64? = nil,
        maxSize: Int64? = nil
    ) {
        self.id = id
        self.name = name
        self.includedExtensions = includedExtensions
        self.excludedExtensions = excludedExtensions
        self.extensionWhitelistEnabled = extensionWhitelistEnabled
        self.extensionWhitelist = extensionWhitelist.map(FilterPreset.normalize).filter { !$0.isEmpty }
        self.appliesToAllFolders = appliesToAllFolders
        self.scopedFolderPaths = scopedFolderPaths
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
        appliesToAllFolders = try container.decodeIfPresent(Bool.self, forKey: .appliesToAllFolders) ?? true
        scopedFolderPaths = try container.decodeIfPresent([String].self, forKey: .scopedFolderPaths) ?? []
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
            // Der Formatfilter basiert immer auf der letzten Pfadendung. Das gilt
            // auch für macOS-Pakete wie `.app`, die im Dateisystem Verzeichnisse
            // sind, aber vom Scanner als einzelner Indexeintrag erfasst werden.
            if !included.contains(ext) { return false }
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

    /// Prüft, ob dieses Filterset für den ausgewählten Scan-Ort gilt.
    /// Ein aktives, begrenztes Filterset bleibt beim Ortswechsel ausgewählt,
    /// wirkt außerhalb seines Bereichs aber absichtlich nicht.
    func applies(to root: URL) -> Bool {
        guard !appliesToAllFolders else { return true }
        let normalizedRoot = Self.normalizedFolderPath(root.path(percentEncoded: false))
        return scopedFolderPaths.contains {
            Self.normalizedFolderPath($0) == normalizedRoot
        }
    }

    private static func normalizedFolderPath(_ path: String) -> String {
        var normalized = URL(fileURLWithPath: path)
            .standardizedFileURL
            .resolvingSymlinksInPath()
            .path(percentEncoded: false)
        while normalized.count > 1 && normalized.hasSuffix("/") {
            normalized.removeLast()
        }
        return normalized
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
