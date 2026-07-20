//
//  DuplicateDetector.swift
//  FileAtlas
//
//  Zweistufige Duplikaterkennung: Größen-Gruppierung → SHA-256-Hash.
//

import Foundation
import CryptoKit

nonisolated struct DuplicateDetector {

    private struct HashCandidate: Sendable {
        let index: Int
        let size: Int64
        let url: URL
    }

    private struct HashDigest: Sendable {
        let index: Int
        let size: Int64
        let value: String
    }

    private struct DigestKey: Hashable, Sendable {
        let size: Int64
        let value: String
    }

    /// Bounded parallelism keeps fast Apple-silicon CPUs busy without saturating
    /// the storage device or creating an unbounded number of file handles.
    private nonisolated static let maximumHashTasks = min(
        8,
        max(2, ProcessInfo.processInfo.activeProcessorCount / 2)
    )

    /// Markiert Duplikate im übergebenen Array und gibt eine aktualisierte Kopie zurück.
    /// Stufe 1: Gruppierung nach Größe (O(n)). Stufe 2: SHA-256 nur für Kandidaten.
    func markDuplicates(in entries: [FileEntry]) async -> [FileEntry] {
        var result = entries

        // Index der Dateien (keine Ordner) nach Position merken.
        let fileIndices = entries.indices.filter {
            !entries[$0].isDirectory
                && entries[$0].size > 0
                && !Self.nonHashablePackageExtensions.contains(entries[$0].fileExtension.lowercased())
        }

        // Stufe 1: nach Größe gruppieren.
        var bySize: [Int64: [Int]] = [:]
        for i in fileIndices {
            bySize[entries[i].size, default: []].append(i)
        }

        // Stufe 2: nur Kandidaten aus gleichen Größengruppen hashen. Die
        // Warteschlange passt sich an verfügbare Kerne an, bleibt aber begrenzt.
        let candidates = bySize.flatMap { size, indices in
            indices.count > 1
                ? indices.map { HashCandidate(index: $0, size: size, url: entries[$0].path) }
                : []
        }
        let digests = await Self.hash(candidates)
        guard !Task.isCancelled else { return result }

        var byDigest: [DigestKey: [Int]] = [:]
        for digest in digests {
            byDigest[DigestKey(size: digest.size, value: digest.value), default: []].append(digest.index)
        }

        // Gleicher Hash innerhalb derselben Größe → gemeinsame Gruppe.
        for group in byDigest.values where group.count > 1 {
            let groupID = UUID()
            for index in group {
                result[index].isDuplicate = true
                result[index].duplicateGroupID = groupID
            }
        }

        return result
    }

    private static let nonHashablePackageExtensions: Set<String> = [
        "app", "bundle", "framework", "xcodeproj", "xcworkspace", "playground",
        "plugin", "kext", "appex", "xpc", "qlgenerator", "prefpane", "component",
        "mdimporter", "photoslibrary", "fcpbundle", "tvlibrary", "rtfd", "scptd",
        "pkg", "mpkg", "dmg", "zip", "ipa", "tar", "gz", "rar", "7z", "docx",
        "xlsx", "pptx",
    ]

    private static func hash(_ candidates: [HashCandidate]) async -> [HashDigest] {
        guard !candidates.isEmpty else { return [] }
        var results: [HashDigest] = []
        results.reserveCapacity(candidates.count)
        var iterator = candidates.makeIterator()

        await withTaskGroup(of: HashDigest?.self) { group in
            for _ in 0..<min(maximumHashTasks, candidates.count) {
                guard let candidate = iterator.next() else { break }
                group.addTask {
                    guard !Task.isCancelled,
                          let value = Self.sha256(of: candidate.url) else { return nil }
                    return HashDigest(index: candidate.index, size: candidate.size, value: value)
                }
            }

            while let digest = await group.next() {
                if let digest {
                    results.append(digest)
                }
                guard !Task.isCancelled, let candidate = iterator.next() else { continue }
                group.addTask {
                    guard !Task.isCancelled,
                          let value = Self.sha256(of: candidate.url) else { return nil }
                    return HashDigest(index: candidate.index, size: candidate.size, value: value)
                }
            }
        }
        return results
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
            if Task.isCancelled { return nil }
            guard let data = try? handle.read(upToCount: chunkSize), !data.isEmpty else { break }
            hasher.update(data: data)
        }
        let digest = hasher.finalize()
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
