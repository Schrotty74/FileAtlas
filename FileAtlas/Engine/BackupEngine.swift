//
//  BackupEngine.swift
//  FileAtlas
//
//  Führt die eigentlichen Backup-Operationen aus (Index-JSON + Voll-ZIP).
//  Läuft off-main (über Task.detached aus dem BackupManager).
//

import Foundation

nonisolated struct BackupEngine {

    enum BackupError: Error, Sendable {
        case insufficientSpace(needed: Int64, free: Int64)
        case destinationUnavailable
    }

    // MARK: - Index-Backup (nur Metadaten)

    /// Schreibt die Dateiliste des Ordners als JSON. Klein & schnell.
    static func writeIndex(location: URL, destinationDir: URL, timestamp: String) throws -> URL {
        let entries = indexEntries(of: location)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted]
        let data = try encoder.encode(entries)

        let name = "FileAtlas_Backup_\(location.lastPathComponent)_\(timestamp)_index.json"
        let url = destinationDir.appendingPathComponent(name)
        try data.write(to: url, options: .atomic)
        return url
    }

    /// Vollständige Metadaten-Liste (Dateien + Ordner) eines Ordners.
    static func indexEntries(of folder: URL) -> [FileEntry] {
        let scoped = folder.startAccessingSecurityScopedResource()
        defer { if scoped { folder.stopAccessingSecurityScopedResource() } }

        let keys: [URLResourceKey] = [
            .isDirectoryKey, .fileSizeKey, .creationDateKey,
            .contentModificationDateKey, .nameKey,
        ]
        guard let en = FileManager.default.enumerator(
            at: folder, includingPropertiesForKeys: keys, options: []
        ) else { return [] }

        var result: [FileEntry] = []
        for case let url as URL in en {
            guard let v = try? url.resourceValues(forKeys: Set(keys)) else { continue }
            result.append(FileEntry(
                name: v.name ?? url.lastPathComponent,
                path: url,
                size: Int64(v.fileSize ?? 0),
                created: v.creationDate ?? .distantPast,
                modified: v.contentModificationDate ?? .distantPast,
                fileExtension: url.pathExtension,
                isDirectory: v.isDirectory ?? false
            ))
        }
        return result
    }

    // MARK: - Voll-Backup (ZIP)

    /// Erstellt ein Standard-ZIP des Ordners (optional AES-256-verschlüsselt).
    static func writeFullZip(
        location: URL,
        destinationDir: URL,
        timestamp: String,
        password: String?,
        shouldCancel: @escaping () -> Bool,
        progress: @escaping (_ fraction: Double, _ currentFiles: Int) -> Void
    ) throws -> URL {
        let total = max(1, ZipArchiver.totalSize(of: location))

        // Freien Speicherplatz prüfen (grob: unkomprimierte Gesamtgröße als Worst Case).
        if let free = freeSpace(at: destinationDir), free < total {
            throw BackupError.insufficientSpace(needed: total, free: free)
        }

        let name = "FileAtlas_Backup_\(location.lastPathComponent)_\(timestamp).zip"
        let url = destinationDir.appendingPathComponent(name)

        try ZipArchiver.create(
            sourceFolder: location,
            destination: url,
            password: password,
            shouldCancel: shouldCancel,
            progress: { bytes, files in
                progress(Double(bytes) / Double(total), files)
            }
        )
        return url
    }

    // MARK: - Hilfen

    /// Geschätzte Gesamtgröße des Ordners (Bytes).
    static func estimatedSize(of folder: URL) -> Int64 {
        ZipArchiver.totalSize(of: folder)
    }

    static func freeSpace(at url: URL) -> Int64? {
        let values = try? url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
        return values?.volumeAvailableCapacityForImportantUsage
    }
}
