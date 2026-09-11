//
//  Snapshot.swift
//  FileAtlas
//

import Foundation

nonisolated enum SnapshotSource: String, Codable, Sendable {
    case automatic
    case manual
}

/// Ein gespeicherter Zustand des Index zu einem Zeitpunkt.
nonisolated struct Snapshot: Identifiable, Codable, Sendable {
    let id: UUID
    let date: Date
    let rootPaths: [String]
    let entries: [FileEntry]
    let source: SnapshotSource

    init(
        id: UUID = UUID(),
        date: Date,
        rootPaths: [String],
        entries: [FileEntry],
        source: SnapshotSource = .manual
    ) {
        self.id = id
        self.date = date
        self.rootPaths = rootPaths
        self.entries = entries
        self.source = source
    }

    private enum CodingKeys: String, CodingKey {
        case id, date, rootPaths, entries, source
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        date = try container.decode(Date.self, forKey: .date)
        rootPaths = try container.decode([String].self, forKey: .rootPaths)
        entries = try container.decode([FileEntry].self, forKey: .entries)
        // Ältere Dateien kennen keine Herkunft und bleiben vorsichtshalber erhalten.
        source = try container.decodeIfPresent(SnapshotSource.self, forKey: .source) ?? .manual
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(date, forKey: .date)
        try container.encode(rootPaths, forKey: .rootPaths)
        try container.encode(entries, forKey: .entries)
        try container.encode(source, forKey: .source)
    }

    var displayName: String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df.string(from: date)
    }

    var fileCount: Int { entries.count }
}

/// Eine einzelne Änderung im Snapshot-Vergleich.
nonisolated struct SnapshotChange: Identifiable, Sendable {
    let id = UUID()
    let status: ChangeStatus
    let entry: FileEntry
    /// Bei `.changed`: die vorherige Variante (für Größen-/Datumsvergleich).
    let previous: FileEntry?

    init(status: ChangeStatus, entry: FileEntry, previous: FileEntry? = nil) {
        self.status = status
        self.entry = entry
        self.previous = previous
    }
}

/// Ergebnis eines Snapshot-Vergleichs.
nonisolated struct SnapshotDiff: Sendable {
    let added: [SnapshotChange]
    let removed: [SnapshotChange]
    let changed: [SnapshotChange]

    var all: [SnapshotChange] { added + changed + removed }
    var isEmpty: Bool { added.isEmpty && removed.isEmpty && changed.isEmpty }
}
