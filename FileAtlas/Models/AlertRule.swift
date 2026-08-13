//
//  AlertRule.swift
//  FileAtlas
//

import Foundation

nonisolated enum AlertRuleAction: String, Codable, CaseIterable, Sendable, Identifiable {
    case notify
    case addToCleanupQueue

    var id: String { rawValue }
}

/// Eine lokale Regel, die nach einem Scan passende Dateien meldet.
nonisolated struct AlertRule: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var name: String
    var extensions: [String]
    var minimumSize: Int64?
    var olderThanDays: Int?
    var isEnabled: Bool
    var action: AlertRuleAction

    init(
        id: UUID = UUID(),
        name: String,
        extensions: [String] = [],
        minimumSize: Int64? = nil,
        olderThanDays: Int? = nil,
        isEnabled: Bool = true,
        action: AlertRuleAction = .notify
    ) {
        self.id = id
        self.name = name
        self.extensions = extensions.map(FilterPreset.normalize).filter { !$0.isEmpty }
        self.minimumSize = minimumSize
        self.olderThanDays = olderThanDays
        self.isEnabled = isEnabled
        self.action = action
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, extensions, minimumSize, olderThanDays, isEnabled, action
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        extensions = (try c.decodeIfPresent([String].self, forKey: .extensions) ?? [])
            .map(FilterPreset.normalize).filter { !$0.isEmpty }
        minimumSize = try c.decodeIfPresent(Int64.self, forKey: .minimumSize)
        olderThanDays = try c.decodeIfPresent(Int.self, forKey: .olderThanDays)
        isEnabled = try c.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
        action = try c.decodeIfPresent(AlertRuleAction.self, forKey: .action) ?? .notify
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
