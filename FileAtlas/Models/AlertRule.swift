//
//  AlertRule.swift
//  FileAtlas
//

import Foundation

/// Eine lokale Regel, die nach einem Scan passende Dateien meldet.
nonisolated struct AlertRule: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var name: String
    var extensions: [String]
    var minimumSize: Int64?
    var olderThanDays: Int?
    var isEnabled: Bool

    init(
        id: UUID = UUID(),
        name: String,
        extensions: [String] = [],
        minimumSize: Int64? = nil,
        olderThanDays: Int? = nil,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.extensions = extensions.map(FilterPreset.normalize).filter { !$0.isEmpty }
        self.minimumSize = minimumSize
        self.olderThanDays = olderThanDays
        self.isEnabled = isEnabled
    }

    func matches(_ entry: FileEntry, now: Date = Date()) -> Bool {
        guard !entry.isDirectory, isEnabled else { return false }
        guard !extensions.isEmpty || minimumSize != nil || olderThanDays != nil else { return false }

        if !extensions.isEmpty,
           !extensions.contains(FilterPreset.normalize(entry.fileExtension)) {
            return false
        }
        if let minimumSize, entry.size < minimumSize { return false }
        if let olderThanDays {
            let cutoff = Calendar.current.date(byAdding: .day, value: -olderThanDays, to: now) ?? now
            if entry.modified > cutoff { return false }
        }
        return true
    }
}

nonisolated struct AlertRuleMatch: Identifiable, Sendable {
    let rule: AlertRule
    let entries: [FileEntry]

    var id: AlertRule.ID { rule.id }
}
