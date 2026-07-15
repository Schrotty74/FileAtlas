//
//  SmartCollection.swift
//  FileAtlas
//

import Foundation

/// Eine gespeicherte dynamische Dateiansicht. Die Dateien bleiben an ihrem Ort.
nonisolated struct SmartCollection: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var name: String
    var extensions: [String]
    var minimumSize: Int64?
    var modifiedWithinDays: Int?
    var duplicatesOnly: Bool

    init(
        id: UUID = UUID(),
        name: String,
        extensions: [String] = [],
        minimumSize: Int64? = nil,
        modifiedWithinDays: Int? = nil,
        duplicatesOnly: Bool = false
    ) {
        self.id = id
        self.name = name
        self.extensions = extensions.map(FilterPreset.normalize).filter { !$0.isEmpty }
        self.minimumSize = minimumSize
        self.modifiedWithinDays = modifiedWithinDays
        self.duplicatesOnly = duplicatesOnly
    }

    func contains(_ entry: FileEntry, now: Date = Date()) -> Bool {
        guard !entry.isDirectory else { return false }
        if !extensions.isEmpty,
           !extensions.contains(FilterPreset.normalize(entry.fileExtension)) {
            return false
        }
        if let minimumSize, entry.size < minimumSize { return false }
        if let modifiedWithinDays {
            let cutoff = Calendar.current.date(byAdding: .day, value: -modifiedWithinDays, to: now) ?? now
            if entry.modified < cutoff { return false }
        }
        if duplicatesOnly && !entry.isDuplicate { return false }
        return true
    }
}
