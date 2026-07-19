import Foundation
import Testing
@testable import FileAtlas

struct BackupEngineTests {
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
}
