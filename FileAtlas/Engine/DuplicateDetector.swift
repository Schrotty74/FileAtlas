//
//  DuplicateDetector.swift
//  FileAtlas
//
//  Zweistufige Duplikaterkennung: Größen-Gruppierung → SHA-256-Hash.
//

import Foundation
import CryptoKit

nonisolated struct DuplicateDetector {

    /// Markiert Duplikate im übergebenen Array und gibt eine aktualisierte Kopie zurück.
    /// Stufe 1: Gruppierung nach Größe (O(n)). Stufe 2: SHA-256 nur für Kandidaten.
    func markDuplicates(in entries: [FileEntry]) async -> [FileEntry] {
        var result = entries

        // Index der Dateien (keine Ordner) nach Position merken.
        let fileIndices = entries.indices.filter { !entries[$0].isDirectory && entries[$0].size > 0 }

        // Stufe 1: nach Größe gruppieren.
        var bySize: [Int64: [Int]] = [:]
        for i in fileIndices {
            bySize[entries[i].size, default: []].append(i)
        }

        // Stufe 2: für jede Größengruppe mit >1 Kandidat den Hash berechnen.
        for (_, indices) in bySize where indices.count > 1 {
            if Task.isCancelled { break }

            var byHash: [String: [Int]] = [:]
            for i in indices {
                guard let hash = Self.sha256(of: entries[i].path) else { continue }
                byHash[hash, default: []].append(i)
            }

            // Gleicher Hash → gemeinsame Gruppe.
            for (_, group) in byHash where group.count > 1 {
                let groupID = UUID()
                for i in group {
                    result[i].isDuplicate = true
                    result[i].duplicateGroupID = groupID
                }
            }
        }

        return result
    }

    /// Streamt die Datei in 1-MB-Blöcken durch SHA-256 (speicherschonend).
    private static func sha256(of url: URL) -> String? {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }

        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? handle.close() }

        var hasher = SHA256()
        let chunkSize = 1024 * 1024
        while true {
            guard let data = try? handle.read(upToCount: chunkSize), !data.isEmpty else { break }
            hasher.update(data: data)
        }
        let digest = hasher.finalize()
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
