//
//  ScanInsights.swift
//  FileAtlas
//

import Foundation

nonisolated struct ScanChangeSummary: Sendable {
    let diff: SnapshotDiff

    var addedCount: Int { diff.added.count }
    var changedCount: Int { diff.changed.count }
    var removedCount: Int { diff.removed.count }

    var addedBytes: Int64 { diff.added.reduce(0) { $0 + $1.entry.size } }
    var removedBytes: Int64 { diff.removed.reduce(0) { $0 + $1.entry.size } }
    var netBytes: Int64 { addedBytes - removedBytes }
}

nonisolated struct StorageTypeSummary: Identifiable, Sendable {
    let fileExtension: String
    let fileCount: Int
    let totalSize: Int64

    var id: String { fileExtension }
    var displayName: String { fileExtension.isEmpty ? "No extension" : fileExtension.uppercased() }
}
