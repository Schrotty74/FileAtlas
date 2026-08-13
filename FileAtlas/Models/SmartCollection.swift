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
    var maximumSize: Int64?
    var modifiedWithinDays: Int?
    var duplicatesOnly: Bool
    var tagTitles: [String]
    var scopedFolderPaths: [String]
    var excludedExtensions: [String]

    init(
        id: UUID = UUID(),
        name: String,
        extensions: [String] = [],
        minimumSize: Int64? = nil,
        maximumSize: Int64? = nil,
        modifiedWithinDays: Int? = nil,
        duplicatesOnly: Bool = false,
        tagTitles: [String] = [],
        scopedFolderPaths: [String] = [],
        excludedExtensions: [String] = []
    ) {
        self.id = id
        self.name = name
        self.extensions = extensions.map(FilterPreset.normalize).filter { !$0.isEmpty }
        self.minimumSize = minimumSize
        self.maximumSize = maximumSize
        self.modifiedWithinDays = modifiedWithinDays
        self.duplicatesOnly = duplicatesOnly
        self.tagTitles = tagTitles.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        self.scopedFolderPaths = scopedFolderPaths
        self.excludedExtensions = excludedExtensions.map(FilterPreset.normalize).filter { !$0.isEmpty }
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, extensions, minimumSize, maximumSize, modifiedWithinDays
        case duplicatesOnly, tagTitles, scopedFolderPaths, excludedExtensions
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        extensions = (try c.decodeIfPresent([String].self, forKey: .extensions) ?? [])
            .map(FilterPreset.normalize).filter { !$0.isEmpty }
        minimumSize = try c.decodeIfPresent(Int64.self, forKey: .minimumSize)
        maximumSize = try c.decodeIfPresent(Int64.self, forKey: .maximumSize)
        modifiedWithinDays = try c.decodeIfPresent(Int.self, forKey: .modifiedWithinDays)
        duplicatesOnly = try c.decodeIfPresent(Bool.self, forKey: .duplicatesOnly) ?? false
        tagTitles = try c.decodeIfPresent([String].self, forKey: .tagTitles) ?? []
        scopedFolderPaths = try c.decodeIfPresent([String].self, forKey: .scopedFolderPaths) ?? []
        excludedExtensions = (try c.decodeIfPresent([String].self, forKey: .excludedExtensions) ?? [])
            .map(FilterPreset.normalize).filter { !$0.isEmpty }
    }

    func contains(_ entry: FileEntry, tags: Set<FileTag> = [], now: Date = Date()) -> Bool {
        guard !entry.isDirectory else { return false }
        if !extensions.isEmpty,
           !extensions.contains(FilterPreset.normalize(entry.fileExtension)) {
            return false
        }
        if let minimumSize, entry.size < minimumSize { return false }
        if let maximumSize, entry.size > maximumSize { return false }
        if let modifiedWithinDays {
            let cutoff = Calendar.current.date(byAdding: .day, value: -modifiedWithinDays, to: now) ?? now
            if entry.modified < cutoff { return false }
        }
        if duplicatesOnly && !entry.isDuplicate { return false }
        if !excludedExtensions.isEmpty,
           excludedExtensions.contains(FilterPreset.normalize(entry.fileExtension)) { return false }
        if !tagTitles.isEmpty {
            let entryTags = Set(tags.map { $0.title.lowercased() })
            guard tagTitles.contains(where: { entryTags.contains($0.lowercased()) }) else { return false }
        }
        if !scopedFolderPaths.isEmpty,
           !scopedFolderPaths.contains(where: { entry.pathKey == $0 || entry.pathKey.hasPrefix($0 + "/") }) { return false }
        return true
    }
}
