import Foundation
import Testing
@testable import FileAtlas

struct DuplicateDetectorTests {
    @Test
    func doesNotMarkCopiesInDifferentScanRootsAsDuplicates() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("FileAtlasTests-\(UUID().uuidString)", isDirectory: true)
        let cloud = root.appendingPathComponent("Cloud", isDirectory: true)
        let localBackup = root.appendingPathComponent("Local Backup", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: cloud, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: localBackup, withIntermediateDirectories: true)

        let cloudCopy = cloud.appendingPathComponent("document.pdf")
        let localCopy = localBackup.appendingPathComponent("document.pdf")
        try Data("same-data".utf8).write(to: cloudCopy)
        try Data("same-data".utf8).write(to: localCopy)

        let now = Date()
        let entries = [
            FileEntry(name: "document.pdf", path: cloudCopy, size: 9, created: now, modified: now, fileExtension: "pdf", isDirectory: false),
            FileEntry(name: "document.pdf", path: localCopy, size: 9, created: now, modified: now, fileExtension: "pdf", isDirectory: false),
        ]

        let marked = await DuplicateDetector().markDuplicates(in: entries, within: [cloud, localBackup])

        #expect(!marked[0].isDuplicate)
        #expect(!marked[1].isDuplicate)
    }

    @Test
    func marksOnlyFilesWithTheSameContentAsDuplicates() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("FileAtlasTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

        let first = root.appendingPathComponent("first.bin")
        let second = root.appendingPathComponent("second.bin")
        let different = root.appendingPathComponent("different.bin")
        try Data("same-data".utf8).write(to: first)
        try Data("same-data".utf8).write(to: second)
        try Data("otherdata".utf8).write(to: different)

        let now = Date()
        let entries = [
            FileEntry(name: "first.bin", path: first, size: 9, created: now, modified: now, fileExtension: "bin", isDirectory: false),
            FileEntry(name: "second.bin", path: second, size: 9, created: now, modified: now, fileExtension: "bin", isDirectory: false),
            FileEntry(name: "different.bin", path: different, size: 9, created: now, modified: now, fileExtension: "bin", isDirectory: false),
        ]

        let marked = await DuplicateDetector().markDuplicates(in: entries)

        #expect(marked[0].isDuplicate)
        #expect(marked[1].isDuplicate)
        #expect(marked[0].duplicateGroupID == marked[1].duplicateGroupID)
        #expect(!marked[2].isDuplicate)
    }
}
