//
//  BackupEngine.swift
//  FileAtlas
//
//  Führt die eigentlichen Backup-Operationen aus (Index-JSON + Voll-ZIP).
//  Läuft off-main (über Task.detached aus dem BackupManager).
//

import Foundation
import CryptoKit

nonisolated struct BackupArchiveOptions: Sendable, Hashable {
    var compressionEnabled: Bool = true
    var hashManifestEnabled: Bool = false
}

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

    /// Vollständige Metadaten-Liste einer Datei oder eines Ordners.
    static func indexEntries(of location: URL) -> [FileEntry] {
        let scoped = location.startAccessingSecurityScopedResource()
        defer { if scoped { location.stopAccessingSecurityScopedResource() } }

        let keys: [URLResourceKey] = [
            .isDirectoryKey, .fileSizeKey, .creationDateKey,
            .contentModificationDateKey, .nameKey,
        ]

        if let v = try? location.resourceValues(forKeys: Set(keys)),
           v.isDirectory != true {
            return [FileEntry(
                name: v.name ?? location.lastPathComponent,
                path: location,
                size: Int64(v.fileSize ?? 0),
                created: v.creationDate ?? .distantPast,
                modified: v.contentModificationDate ?? .distantPast,
                fileExtension: location.pathExtension,
                isDirectory: false
            )]
        }

        guard let en = FileManager.default.enumerator(
            at: location, includingPropertiesForKeys: keys, options: []
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
        options: BackupArchiveOptions = BackupArchiveOptions(),
        progress: @escaping (_ fraction: Double, _ currentFiles: Int, _ currentPath: URL) -> Void
    ) throws -> URL {
        try writeFullZip(
            sources: [location], destinationDir: destinationDir, timestamp: timestamp,
            password: password, includeSourceDirectory: false,
            shouldCancel: shouldCancel, options: options, progress: progress
        )
    }

    /// Erstellt ein ZIP aus mehreren explizit ausgewählten Dateien und/oder Ordnern.
    static func writeFullZip(
        sources: [URL],
        destinationDir: URL,
        timestamp: String,
        password: String?,
        includeSourceDirectory: Bool = true,
        shouldCancel: @escaping () -> Bool,
        options: BackupArchiveOptions = BackupArchiveOptions(),
        progress: @escaping (_ fraction: Double, _ currentFiles: Int, _ currentPath: URL) -> Void
    ) throws -> URL {
        let total = max(1, ZipArchiver.totalSize(of: sources))

        // Freien Speicherplatz prüfen (grob: unkomprimierte Gesamtgröße als Worst Case).
        if let free = freeSpace(at: destinationDir), free < total {
            throw BackupError.insufficientSpace(needed: total, free: free)
        }

        let sourceName = sources.count == 1 ? sources[0].lastPathComponent : "Selection"
        let name = "FileAtlas_Backup_\(sourceName)_\(timestamp).zip"
        let url = destinationDir.appendingPathComponent(name)

        try ZipArchiver.create(
            sources: sources,
            destination: url,
            password: password,
            options: options,
            includeSourceDirectory: includeSourceDirectory,
            shouldCancel: shouldCancel,
            progress: { bytes, files, currentPath in
                progress(Double(bytes) / Double(total), files, currentPath)
            }
        )
        if options.hashManifestEnabled {
            try writeHashManifest(
                for: sources,
                zipURL: url,
                timestamp: timestamp,
                includeSourceDirectory: includeSourceDirectory,
                shouldCancel: shouldCancel
            )
        }
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

    private static func writeHashManifest(
        for locations: [URL],
        zipURL: URL,
        timestamp: String,
        includeSourceDirectory: Bool,
        shouldCancel: () -> Bool
    ) throws {
        var lines = [
            "# FileAtlas SHA-256 manifest",
            "# Sources: \(locations.map { $0.path(percentEncoded: false) }.joined(separator: ", "))",
            "# Created: \(timestamp)",
            "",
        ]

        for location in locations {
            for file in ZipArchiver.regularFiles(in: location) {
                if shouldCancel() { throw ZipArchiver.ZipError.cancelled }
                guard let hash = sha256(of: file, shouldCancel: shouldCancel) else { continue }
                let relative = ZipArchiver.relativePath(of: file, base: location)
                let archivePath = includeSourceDirectory ? "\(location.lastPathComponent)/\(relative)" : relative
                lines.append("\(hash)  \(archivePath)")
            }
        }

        let manifestURL = zipURL.deletingPathExtension().appendingPathExtension("sha256")
        try lines.joined(separator: "\n").appending("\n").write(to: manifestURL, atomically: true, encoding: .utf8)
    }

    private static func sha256(of url: URL, shouldCancel: () -> Bool) -> String? {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? handle.close() }

        var hasher = SHA256()
        while true {
            if shouldCancel() { return nil }
            guard let data = try? handle.read(upToCount: 8 * 1024 * 1024), !data.isEmpty else { break }
            hasher.update(data: data)
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }
}
