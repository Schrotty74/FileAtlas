import Foundation
import Testing
@testable import FileAtlas

struct FormatFilteringTests {
    @Test
    func scannerAndFormatFiltersRecognizeBundlesAndArchivesByTerminalExtension() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("FileAtlasTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

        let app = root.appendingPathComponent("AppCleaner.app", isDirectory: true)
        try FileManager.default.createDirectory(
            at: app.appendingPathComponent("Contents", isDirectory: true),
            withIntermediateDirectories: true
        )
        try Data("bundle content".utf8).write(to: app.appendingPathComponent("Contents/Info.plist"))

        for name in ["Installer.dmg", "Installer.pkg", "AirScroll.app.zip", "Disk.iso"] {
            try Data("archive".utf8).write(to: root.appendingPathComponent(name))
        }

        let engine = IndexEngine()
        var entries: [FileEntry] = []
        for await event in engine.scan(roots: [root]) {
            if case let .found(entry) = event {
                entries.append(entry)
            }
        }

        #expect(Set(entries.map(\.name)) == Set([
            "AppCleaner.app", "Installer.dmg", "Installer.pkg", "AirScroll.app.zip", "Disk.iso",
        ]))
        #expect(!entries.contains { $0.path.path(percentEncoded: false).contains("AppCleaner.app/Contents") })

        let expectedNames = [
            "app": "AppCleaner.app",
            "dmg": "Installer.dmg",
            "pkg": "Installer.pkg",
            "zip": "AirScroll.app.zip",
            "iso": "Disk.iso",
        ]
        for (extensionName, expectedName) in expectedNames {
            let preset = FilterPreset(name: extensionName, includedExtensions: [extensionName])
            let collection = SmartCollection(name: extensionName, extensions: [extensionName])
            #expect(Set(entries.filter { preset.allows($0) }.map(\.name)) == Set([expectedName]))
            #expect(Set(entries.filter { collection.contains($0) }.map(\.name)) == Set([expectedName]))
        }
    }

    @Test
    func includedExtensionsDoNotPassUnrelatedDirectories() {
        let folder = FileEntry(
            name: "Unrelated Folder",
            path: URL(fileURLWithPath: "/Catalog/Unrelated Folder", isDirectory: true),
            size: 0,
            created: .now,
            modified: .now,
            fileExtension: "",
            isDirectory: true
        )
        let preset = FilterPreset(name: "Apps", includedExtensions: ["app"])

        #expect(!preset.allows(folder))
    }

    @Test
    func archiveFileDoesNotSkipTheNextDirectorysDescendants() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("FileAtlasTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

        try Data("archive".utf8).write(to: root.appendingPathComponent("Before.zip"))
        let installer = root
            .appendingPathComponent("Mail Clients/Thunderbird", isDirectory: true)
            .appendingPathComponent("Thunderbird.pkg")
        try FileManager.default.createDirectory(at: installer.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("installer".utf8).write(to: installer)

        let engine = IndexEngine()
        var names: Set<String> = []
        for await event in engine.scan(roots: [root]) {
            if case let .found(entry) = event {
                names.insert(entry.name)
            }
        }

        #expect(names.contains("Before.zip"))
        #expect(names.contains("Thunderbird.pkg"))
    }
}
