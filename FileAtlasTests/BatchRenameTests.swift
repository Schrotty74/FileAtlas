import Foundation
import Testing
@testable import FileAtlas

struct BatchRenameTests {
    @Test
    func previewPreservesFileExtensionsAndAddsSequentialNumbers() {
        let first = FileEntry(
            name: "Report.pdf",
            path: URL(fileURLWithPath: "/Catalog/Report.pdf"),
            size: 1,
            created: .now,
            modified: .now,
            fileExtension: "pdf",
            isDirectory: false
        )
        let second = FileEntry(
            name: "Photo.jpg",
            path: URL(fileURLWithPath: "/Catalog/Photo.jpg"),
            size: 1,
            created: .now,
            modified: .now,
            fileExtension: "jpg",
            isDirectory: false
        )

        let plans = BatchRenamePlanner.plans(
            for: [first, second],
            prefix: "Archive-",
            suffix: "",
            addsNumber: true,
            startingAt: 4
        )

        #expect(plans.map { $0.destination.lastPathComponent } == ["Archive-Photo - 004.jpg", "Archive-Report - 005.pdf"])
    }

    @Test
    func executorDoesNotOverwriteExistingFiles() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("FileAtlasTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

        let source = root.appendingPathComponent("source.txt")
        let existing = root.appendingPathComponent("target.txt")
        try Data("source".utf8).write(to: source)
        try Data("target".utf8).write(to: existing)

        let result = BatchRenameExecutor.apply([BatchRenamePlan(source: source, destination: existing)])
        #expect(result.renamedCount == 0)
        #expect(result.failures.count == 1)
        #expect(FileManager.default.fileExists(atPath: source.path(percentEncoded: false)))
    }

    @Test
    func executorRenamesAPlannedFile() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("FileAtlasTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

        let source = root.appendingPathComponent("source.txt")
        let destination = root.appendingPathComponent("renamed.txt")
        try Data("source".utf8).write(to: source)

        let result = BatchRenameExecutor.apply([BatchRenamePlan(source: source, destination: destination)])
        #expect(result.renamedCount == 1)
        #expect(result.failures.isEmpty)
        #expect(!FileManager.default.fileExists(atPath: source.path(percentEncoded: false)))
        #expect(FileManager.default.fileExists(atPath: destination.path(percentEncoded: false)))
    }
}
