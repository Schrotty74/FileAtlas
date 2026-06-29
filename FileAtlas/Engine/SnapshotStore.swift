//
//  SnapshotStore.swift
//  FileAtlas
//
//  Persistenz von Snapshots (max. 10) + Vergleichslogik.
//

import Foundation

nonisolated struct SnapshotStore {

    private static let maxSnapshots = 10

    // MARK: - Speicherorte

    /// `~/Library/Application Support/FileAtlas/`
    static var appSupportDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("FileAtlas", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// `~/Library/Application Support/FileAtlas/snapshots/`
    static var snapshotsDirectory: URL {
        let dir = appSupportDirectory.appendingPathComponent("snapshots", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    // MARK: - Persistenz

    private static var encoder: JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted]
        return e
    }

    private static var decoder: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }

    /// Speichert einen Snapshot und löscht den ältesten, falls > 10 vorhanden.
    @discardableResult
    func save(_ snapshot: Snapshot) throws -> URL {
        let url = Self.snapshotsDirectory
            .appendingPathComponent("\(snapshot.id.uuidString).json")
        let data = try Self.encoder.encode(snapshot)
        try data.write(to: url, options: .atomic)
        pruneOldSnapshots()
        return url
    }

    func delete(_ snapshot: Snapshot) throws {
        let url = Self.snapshotsDirectory
            .appendingPathComponent("\(snapshot.id.uuidString).json")
        try FileManager.default.removeItem(at: url)
    }

    /// Lädt alle Snapshots, neueste zuerst.
    func loadAll() -> [Snapshot] {
        let fm = FileManager.default
        guard let urls = try? fm.contentsOfDirectory(
            at: Self.snapshotsDirectory,
            includingPropertiesForKeys: nil
        ) else { return [] }

        let snapshots = urls
            .filter { $0.pathExtension == "json" }
            .compactMap { try? Self.decoder.decode(Snapshot.self, from: Data(contentsOf: $0)) }
        return snapshots.sorted { $0.date > $1.date }
    }

    private func pruneOldSnapshots() {
        let all = loadAll()
        guard all.count > Self.maxSnapshots else { return }
        for old in all.dropFirst(Self.maxSnapshots) {
            let url = Self.snapshotsDirectory
                .appendingPathComponent("\(old.id.uuidString).json")
            try? FileManager.default.removeItem(at: url)
        }
    }

    // MARK: - Vergleich

    /// Vergleicht `current` gegen einen gespeicherten `baseline`-Snapshot.
    func diff(current: [FileEntry], baseline: Snapshot) -> SnapshotDiff {
        let currentByPath = Dictionary(current.map { ($0.pathKey, $0) }) { a, _ in a }
        let baselineByPath = Dictionary(baseline.entries.map { ($0.pathKey, $0) }) { a, _ in a }

        var added: [SnapshotChange] = []
        var removed: [SnapshotChange] = []
        var changed: [SnapshotChange] = []

        // Neu + geändert.
        for (key, entry) in currentByPath {
            if let old = baselineByPath[key] {
                if old.size != entry.size || old.modified != entry.modified {
                    changed.append(SnapshotChange(status: .changed, entry: entry, previous: old))
                }
            } else {
                added.append(SnapshotChange(status: .added, entry: entry))
            }
        }

        // Entfernt.
        for (key, old) in baselineByPath where currentByPath[key] == nil {
            removed.append(SnapshotChange(status: .removed, entry: old))
        }

        let byName: (SnapshotChange, SnapshotChange) -> Bool = { $0.entry.name < $1.entry.name }
        return SnapshotDiff(
            added: added.sorted(by: byName),
            removed: removed.sorted(by: byName),
            changed: changed.sorted(by: byName)
        )
    }
}
