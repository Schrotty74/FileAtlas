//
//  BackupConfig.swift
//  FileAtlas
//
//  Backup-Einstellungen pro gespeichertem Ort + Persistenz.
//

import Foundation

/// Welche Art von Backup erstellt wird.
nonisolated enum BackupKind: String, Codable, CaseIterable, Sendable {
    case indexOnly      // nur Metadaten (JSON)
    case fullOnly       // echtes ZIP der Dateien
    case both
}

/// Zeitplan für automatische Backups (nur während die App läuft).
nonisolated enum BackupSchedule: String, Codable, CaseIterable, Sendable {
    case off
    case daily
    case weekly

    /// Mindestabstand zwischen zwei automatischen Backups.
    var interval: TimeInterval? {
        switch self {
        case .off:    return nil
        case .daily:  return 24 * 60 * 60
        case .weekly: return 7 * 24 * 60 * 60
        }
    }
}

/// Persistierte Backup-Konfiguration eines Ortes (Schlüssel = Pfad des Ortes).
nonisolated struct BackupConfig: Codable, Identifiable, Sendable, Hashable {
    var id: String { locationPath }

    let locationPath: String
    var kind: BackupKind = .indexOnly
    var schedule: BackupSchedule = .off
    var passwordEnabled: Bool = false
    /// Security-Scoped-Bookmark des Zielordners.
    var destinationBookmark: Data? = nil
    var lastBackupDate: Date? = nil

    init(locationPath: String) {
        self.locationPath = locationPath
    }

    /// Ist gemäß Zeitplan ein automatisches Backup fällig?
    func isDue(now: Date) -> Bool {
        guard schedule != .off, let interval = schedule.interval else { return false }
        guard destinationBookmark != nil else { return false }
        guard let last = lastBackupDate else { return true }
        return now.timeIntervalSince(last) >= interval
    }
}

// MARK: - Persistenz

nonisolated struct BackupConfigStore {

    private var fileURL: URL {
        SnapshotStore.appSupportDirectory.appendingPathComponent("backups.json")
    }

    func loadAll() -> [String: BackupConfig] {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([BackupConfig].self, from: data)
        else { return [:] }
        return Dictionary(decoded.map { ($0.locationPath, $0) }) { a, _ in a }
    }

    func saveAll(_ configs: [String: BackupConfig]) {
        let array = Array(configs.values)
        guard let data = try? JSONEncoder().encode(array) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
