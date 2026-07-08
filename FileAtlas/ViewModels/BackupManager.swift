//
//  BackupManager.swift
//  FileAtlas
//
//  Verwaltet Backup-Konfigurationen pro Ort, führt manuelle und geplante
//  Backups aus und hält den Lauf-/Statuszustand für die UI.
//

import SwiftUI
import AppKit

@Observable
@MainActor
final class BackupManager {

    private var configs: [String: BackupConfig]
    private let store = BackupConfigStore()

    // Laufzustand (für UI)
    private(set) var activeBackupLocation: String? = nil
    private(set) var progressFraction: Double = 0
    private(set) var progressLabel: String = ""
    private(set) var activeSourceName: String = ""
    private(set) var currentItemName: String = ""
    var statusMessage: String? = nil
    private var backupTask: Task<Void, Error>? = nil

    var isBackingUp: Bool { activeBackupLocation != nil }

    init() {
        configs = store.loadAll()
    }

    // MARK: - Konfiguration

    func config(for location: URL) -> BackupConfig {
        configs[location.path(percentEncoded: false)] ?? BackupConfig(locationPath: location.path(percentEncoded: false))
    }

    func saveConfig(_ config: BackupConfig) {
        configs[config.locationPath] = config
        store.saveAll(configs)
    }

    func lastBackup(for location: URL) -> Date? {
        config(for: location).lastBackupDate
    }

    func destinationDisplayName(for location: URL) -> String? {
        resolveDestination(config(for: location))?.lastPathComponent
    }

    func sourceDisplayName(for location: URL) -> String {
        resolveSource(config(for: location), fallback: location).lastPathComponent
    }

    // MARK: - Passwort (Keychain)

    func setPassword(_ password: String, for location: URL) {
        KeychainStore.setPassword(password, for: location.path(percentEncoded: false))
    }

    func clearPassword(for location: URL) {
        KeychainStore.deletePassword(for: location.path(percentEncoded: false))
    }

    func hasPassword(for location: URL) -> Bool {
        KeychainStore.hasPassword(for: location.path(percentEncoded: false))
    }

    // MARK: - Zielordner wählen

    func chooseDestination(for location: URL) {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = NSLocalizedString("Choose", comment: "")
        guard panel.runModal() == .OK, let url = panel.url else { return }

        var config = config(for: location)
        config.destinationBookmark = try? url.bookmarkData(
            options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
        saveConfig(config)
    }

    func chooseSource(for location: URL) {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.prompt = NSLocalizedString("Choose", comment: "")
        guard panel.runModal() == .OK, let url = panel.url else { return }

        var config = config(for: location)
        config.sourceBookmark = try? url.bookmarkData(
            options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
        saveConfig(config)
    }

    // MARK: - Größe / Vorbedingungen

    func estimatedSize(of location: URL) -> Int64 {
        BackupEngine.estimatedSize(of: resolveSource(config(for: location), fallback: location))
    }

    // MARK: - Backup ausführen

    func runBackup(for location: URL) async {
        guard activeBackupLocation == nil else { return }

        var config = config(for: location)
        guard let destDir = resolveDestination(config) else {
            statusMessage = NSLocalizedString("No backup destination chosen.", comment: "")
            return
        }

        let locationPath = config.locationPath
        let source = resolveSource(config, fallback: location)
        activeBackupLocation = locationPath
        activeSourceName = source.lastPathComponent
        currentItemName = ""
        progressFraction = 0
        progressLabel = NSLocalizedString("Preparing…", comment: "")
        statusMessage = nil

        let password = config.passwordEnabled ? KeychainStore.password(for: locationPath) : nil
        let kind = config.kind
        let compressionEnabled = config.compressionEnabled
        let hashManifestEnabled = config.hashManifestEnabled
        let timestamp = Self.timestamp()

        let destScoped = destDir.startAccessingSecurityScopedResource()
        let sourceScoped = source.startAccessingSecurityScopedResource()

        let task = Task.detached(priority: .utility) { [weak self] () throws -> Void in
            try Task.checkCancellation()

            if kind == .indexOnly || kind == .both {
                try Task.checkCancellation()
                _ = try BackupEngine.writeIndex(location: source, destinationDir: destDir, timestamp: timestamp)
            }

            try Task.checkCancellation()

            if kind == .fullOnly || kind == .both {
                try Task.checkCancellation()
                var lastPct = -1.0
                _ = try BackupEngine.writeFullZip(
                    location: source, destinationDir: destDir, timestamp: timestamp,
                    password: password, shouldCancel: { Task.isCancelled },
                    options: BackupArchiveOptions(
                        compressionEnabled: compressionEnabled,
                        hashManifestEnabled: hashManifestEnabled
                    ),
                    progress: { fraction, files, currentPath in
                        let pct = (fraction * 100).rounded()
                        let itemName = currentPath.lastPathComponent
                        guard pct != lastPct || !itemName.isEmpty else { return }
                        lastPct = pct
                        let label = String(format: NSLocalizedString("%lld files", comment: ""), files)
                        Task { @MainActor [weak self] in
                            self?.progressFraction = fraction
                            self?.progressLabel = label
                            self?.currentItemName = itemName
                        }
                    })
            }
        }
        backupTask = task
        let result = await task.result
        backupTask = nil
        if destScoped { destDir.stopAccessingSecurityScopedResource() }
        if sourceScoped { source.stopAccessingSecurityScopedResource() }

        switch result {
        case .success:
            config.lastBackupDate = Date()
            saveConfig(config)
            statusMessage = NSLocalizedString("Backup completed.", comment: "")
        case .failure(let error):
            statusMessage = Self.message(for: error)
        }
        backupTask = nil
        activeBackupLocation = nil
        activeSourceName = ""
        currentItemName = ""
        progressFraction = 0
        progressLabel = ""
    }

    func cancelBackup() {
        guard isBackingUp else { return }
        backupTask?.cancel()
        progressLabel = NSLocalizedString("Cancelling…", comment: "")
    }

    /// Beim App-Start: für alle Orte fällige geplante Backups nacheinander ausführen.
    func runScheduledIfDue(locations: [URL]) async {
        let now = Date()
        for location in locations {
            let config = config(for: location)
            if config.isDue(now: now) {
                await runBackup(for: location)
            }
        }
    }

    // MARK: - Helpers

    private func resolveDestination(_ config: BackupConfig) -> URL? {
        guard let data = config.destinationBookmark else { return nil }
        var stale = false
        return try? URL(resolvingBookmarkData: data, options: .withSecurityScope,
                        relativeTo: nil, bookmarkDataIsStale: &stale)
    }

    private func resolveSource(_ config: BackupConfig, fallback: URL) -> URL {
        guard let data = config.sourceBookmark else { return fallback }
        var stale = false
        return (try? URL(resolvingBookmarkData: data, options: .withSecurityScope,
                         relativeTo: nil, bookmarkDataIsStale: &stale)) ?? fallback
    }

    private static func timestamp() -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd_HH-mm"
        return df.string(from: Date())
    }

    private static func message(for error: Error) -> String {
        if error is CancellationError {
            return NSLocalizedString("Backup cancelled.", comment: "")
        }
        if case ZipArchiver.ZipError.cancelled = error {
            return NSLocalizedString("Backup cancelled.", comment: "")
        }
        if case BackupEngine.BackupError.insufficientSpace(let needed, let free) = error {
            let n = ByteCountFormatter.string(fromByteCount: needed, countStyle: .file)
            let f = ByteCountFormatter.string(fromByteCount: free, countStyle: .file)
            return String(format: NSLocalizedString("Not enough free space: %@ needed, %@ available.", comment: ""), n, f)
        }
        return String(format: NSLocalizedString("Backup failed: %@", comment: ""), error.localizedDescription)
    }
}
