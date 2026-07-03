//
//  FileEntry.swift
//  FileAtlas
//

import Foundation

/// Eine im Index erfasste Datei oder ein Ordner.
nonisolated struct FileEntry: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let name: String
    let path: URL
    let size: Int64           // Bytes
    let created: Date
    let modified: Date
    let fileExtension: String
    let isDirectory: Bool
    var isDuplicate: Bool = false
    var duplicateGroupID: UUID? = nil

    init(
        id: UUID = UUID(),
        name: String,
        path: URL,
        size: Int64,
        created: Date,
        modified: Date,
        fileExtension: String,
        isDirectory: Bool,
        isDuplicate: Bool = false,
        duplicateGroupID: UUID? = nil
    ) {
        self.id = id
        self.name = name
        self.path = path
        self.size = size
        self.created = created
        self.modified = modified
        self.fileExtension = fileExtension
        self.isDirectory = isDirectory
        self.isDuplicate = isDuplicate
        self.duplicateGroupID = duplicateGroupID
    }

    /// Menschen-lesbare Größe (z. B. „4,2 MB").
    /// Ordner ohne bekannte Größe zeigen „—"; übersprungene Ordner mit
    /// berechneter Gesamtgröße zeigen diese an.
    var formattedSize: String {
        if isDirectory && size == 0 { return "—" }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    /// Gleichheit über den absoluten Pfad (für Snapshot-Diffs).
    var pathKey: String { path.path(percentEncoded: false) }

}
