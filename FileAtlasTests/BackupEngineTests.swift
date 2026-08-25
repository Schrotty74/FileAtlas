import Foundation
import Testing
@testable import FileAtlas

struct BackupEngineTests {
    @Test
    func legacyBackupConfigGetsSafeHistoryDefaults() throws {
        let data = Data(#"{"locationPath":"/Example"}"#.utf8)
        let config = try JSONDecoder().decode(BackupConfig.self, from: data)

        #expect(config.retentionCount == 5)
        #expect(config.history.isEmpty)
    }

    @Test
    func smartCollectionCanCombineTagFolderAndMaximumSize() {
        let entry = FileEntry(
            name: "Installer.dmg",
            path: URL(fileURLWithPath: "/Catalog/Installer.dmg"),
            size: 50_000_000,
            created: .now,
            modified: .now,
            fileExtension: "dmg",
            isDirectory: false
        )
        let collection = SmartCollection(
            name: "Small installers",
            extensions: ["dmg"],
            maximumSize: 100_000_000,
            tagTitles: ["Checked"],
            scopedFolderPaths: ["/Catalog"]
        )

        #expect(collection.contains(entry, tags: [FileTag("Checked")]))
        #expect(!collection.contains(entry, tags: []))
    }

    @Test
    func indexBackupReportsTheIndexedItemCount() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("FileAtlasTests-\(UUID().uuidString)", isDirectory: true)
        let source = root.appendingPathComponent("Source", isDirectory: true)
        let destination = root.appendingPathComponent("Destination", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        try Data("first".utf8).write(to: source.appendingPathComponent("one.txt"))
        try Data("second".utf8).write(to: source.appendingPathComponent("two.txt"))

        let result = try BackupEngine.writeIndex(
            location: source,
            destinationDir: destination,
            timestamp: "test"
        )

        #expect(result.itemCount == 2)
        #expect(FileManager.default.fileExists(atPath: result.url.path(percentEncoded: false)))
    }

    @Test
    func archiveInspectorVerifiesTheContentsAgainstTheHashManifest() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("FileAtlasTests-\(UUID().uuidString)", isDirectory: true)
        let source = root.appendingPathComponent("Source", isDirectory: true)
        let destination = root.appendingPathComponent("Destination", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        try Data("verified contents".utf8).write(to: source.appendingPathComponent("one.txt"))

        let archive = try BackupEngine.writeFullZip(
            location: source,
            destinationDir: destination,
            timestamp: "test",
            password: nil,
            shouldCancel: { false },
            options: BackupArchiveOptions(hashManifestEnabled: true),
            progress: { _, _, _ in }
        )

        let inspection = ArchiveInspector.inspect(archive)
        #expect(inspection.isValid)
        #expect(inspection.hashManifestVerification == .verified(fileCount: 1))

        let manifest = archive.deletingPathExtension().appendingPathExtension("sha256")
        let invalid = "# FileAtlas SHA-256 manifest\n" + String(repeating: "0", count: 64) + "  one.txt\n"
        try invalid.write(to: manifest, atomically: true, encoding: .utf8)

        let tamperedInspection = ArchiveInspector.inspect(archive)
        if case .failed = tamperedInspection.hashManifestVerification {
            #expect(Bool(true))
        } else {
            Issue.record("An altered SHA-256 manifest must fail verification.")
        }
    }
}
