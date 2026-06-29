//
//  Snapshot.swift
//  FileAtlas
//

import Foundation

/// Ein gespeicherter Zustand des Index zu einem Zeitpunkt.
nonisolated struct Snapshot: Identifiable, Codable, Sendable {
    let id: UUID
    let date: Date
    let rootPaths: [String]
    let entries: [FileEntry]

    init(id: UUID = UUID(), date: Date, rootPaths: [String], entries: [FileEntry]) {
        self.id = id
        self.date = date
        self.rootPaths = rootPaths
        self.entries = entries
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
