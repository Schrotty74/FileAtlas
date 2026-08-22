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

nonisolated struct BackupRecord: Codable, Identifiable, Sendable, Hashable {
    let id: UUID
    let date: Date
    let artifactPath: String
    let itemCount: Int
    let archiveSize: Int64
    let isIncremental: Bool

    init(date: Date = Date(), artifactURL: URL, itemCount: Int, archiveSize: Int64, isIncremental: Bool = false) {
        self.id = UUID()
        self.date = date
        self.artifactPath = artifactURL.path(percentEncoded: false)
        self.itemCount = itemCount
        self.archiveSize = archiveSize
        self.isIncremental = isIncremental
    }

    var artifactURL: URL { URL(fileURLWithPath: artifactPath) }

    private enum CodingKeys: String, CodingKey {
        case id, date, artifactPath, itemCount, archiveSize, isIncremental
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        date = try c.decode(Date.self, forKey: .date)
        artifactPath = try c.decode(String.self, forKey: .artifactPath)
        itemCount = try c.decode(Int.self, forKey: .itemCount)
        archiveSize = try c.decode(Int64.self, forKey: .archiveSize)
        isIncremental = try c.decodeIfPresent(Bool.self, forKey: .isIncremental) ?? false
    }
}

/// Persistierte Backup-Konfiguration eines Ortes (Schlüssel = Pfad des Ortes).
nonisolated struct BackupConfig: Codable, Identifiable, Sendable, Hashable {
    var id: String { locationPath }

    let locationPath: String
    var kind: BackupKind = .indexOnly
    var schedule: BackupSchedule = .off
    var passwordEnabled: Bool = false
    var compressionEnabled: Bool = true
    var hashManifestEnabled: Bool = false
    /// Nach einer ersten Vollsicherung werden nur seit der letzten Sicherung geaenderte Dateien gesichert.
    var incrementalEnabled: Bool = false
    /// Optional abweichende Backup-Quelle (Datei oder Ordner).
    var sourceBookmark: Data? = nil
    /// Security-Scoped-Bookmark des Zielordners.
    var destinationBookmark: Data? = nil
    var lastBackupDate: Date? = nil
    /// 0 deaktiviert das automatische Aufräumen alter Sicherungen.
    var retentionCount: Int = 5
    var history: [BackupRecord] = []

    init(locationPath: String) {
        self.locationPath = locationPath
    }

    private enum CodingKeys: String, CodingKey {
        case locationPath, kind, schedule, passwordEnabled, compressionEnabled
        case hashManifestEnabled, incrementalEnabled, sourceBookmark, destinationBookmark, lastBackupDate
        case retentionCount, history
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        locationPath = try c.decode(String.self, forKey: .locationPath)
        kind = try c.decodeIfPresent(BackupKind.self, forKey: .kind) ?? .indexOnly
        schedule = try c.decodeIfPresent(BackupSchedule.self, forKey: .schedule) ?? .off
        passwordEnabled = try c.decodeIfPresent(Bool.self, forKey: .passwordEnabled) ?? false
        compressionEnabled = try c.decodeIfPresent(Bool.self, forKey: .compressionEnabled) ?? true
        hashManifestEnabled = try c.decodeIfPresent(Bool.self, forKey: .hashManifestEnabled) ?? false
        incrementalEnabled = try c.decodeIfPresent(Bool.self, forKey: .incrementalEnabled) ?? false
        sourceBookmark = try c.decodeIfPresent(Data.self, forKey: .sourceBookmark)
        destinationBookmark = try c.decodeIfPresent(Data.self, forKey: .destinationBookmark)
        lastBackupDate = try c.decodeIfPresent(Date.self, forKey: .lastBackupDate)
        retentionCount = max(0, try c.decodeIfPresent(Int.self, forKey: .retentionCount) ?? 5)
        history = try c.decodeIfPresent([BackupRecord].self, forKey: .history) ?? []
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
