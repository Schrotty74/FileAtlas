import Foundation
import Testing
@testable import FileAtlas

struct RegressionWorkflowTests {
    @Test
    func scopedFilterRemainsActiveButOnlyAppliesToItsConfiguredLocation() {
        let macSoftware = URL(fileURLWithPath: "/Catalog/MacSoftware", isDirectory: true)
        let series = URL(fileURLWithPath: "/Catalog/Series", isDirectory: true)
        let appsOnly = FilterPreset(
            name: "Apps",
            includedExtensions: ["app", "pkg"],
            appliesToAllFolders: false,
            scopedFolderPaths: [macSoftware.path(percentEncoded: false)]
        )

        #expect(appsOnly.applies(to: macSoftware))
        #expect(!appsOnly.applies(to: series))
        #expect(appsOnly.allows(entry(named: "AppCleaner.app", in: macSoftware)))
        #expect(!appsOnly.allows(entry(named: "Episode.mkv", in: macSoftware)))
    }

    @Test
    func cacheRestoreUsesNewestSnapshotForTheMatchingLocationOnly() {
        let target = URL(fileURLWithPath: "/Catalog/MacSoftware", isDirectory: true)
        let other = URL(fileURLWithPath: "/Catalog/Series", isDirectory: true)
        let earlier = Date(timeIntervalSince1970: 1_700_000_000)
        let later = Date(timeIntervalSince1970: 1_700_000_100)
        let oldestTargetSnapshot = Snapshot(date: earlier, rootPaths: [target.path(percentEncoded: false)], entries: [])
        let newestTargetSnapshot = Snapshot(date: later, rootPaths: [target.path(percentEncoded: false)], entries: [])
        let otherSnapshot = Snapshot(date: Date(timeIntervalSince1970: 1_700_000_200), rootPaths: [other.path(percentEncoded: false)], entries: [])

        #expect(SnapshotStore.latestSnapshot(for: target, from: [oldestTargetSnapshot, otherSnapshot, newestTargetSnapshot])?.id == newestTargetSnapshot.id)
        #expect(SnapshotStore.latestSnapshot(for: other, from: [oldestTargetSnapshot, newestTargetSnapshot]) == nil)
    }

    @Test
    func folderMonitorReportsFilesystemChanges() async throws {
        let root = try temporaryDirectory(named: "FolderMonitor")
        defer { try? FileManager.default.removeItem(at: root) }

        let signal = ChangeSignal()
        let monitor = FolderChangeMonitor(roots: [root]) {
            signal.markChanged()
        }
        defer { monitor.stop() }
        monitor.start()

        try Data("changed".utf8).write(to: root.appendingPathComponent("new-file.txt"))
        #expect(await waitForChange(signal, timeout: .seconds(5)))
    }

    @Test
    func scannerIndexesEveryEntryInALargeSyntheticCatalog() async throws {
        let root = try temporaryDirectory(named: "LargeCatalog")
        defer { try? FileManager.default.removeItem(at: root) }

        let expectedCount = 2_000
        for index in 0..<expectedCount {
            let name = String(format: "Item-%04d.zip", index)
            FileManager.default.createFile(atPath: root.appendingPathComponent(name).path(percentEncoded: false), contents: Data())
        }

        let engine = IndexEngine()
        var foundCount = 0
        for await event in engine.scan(roots: [root]) {
            if case .found = event {
                foundCount += 1
            }
        }

        #expect(foundCount == expectedCount)
    }

    private func entry(named name: String, in root: URL) -> FileEntry {
        let url = root.appendingPathComponent(name)
        return FileEntry(
            name: name,
            path: url,
            size: 1,
            created: .now,
            modified: .now,
            fileExtension: url.pathExtension,
            isDirectory: false
        )
    }

    private func temporaryDirectory(named name: String) throws -> URL {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("FileAtlasTests-\(name)-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    private func waitForChange(_ signal: ChangeSignal, timeout: Duration) async -> Bool {
        let clock = ContinuousClock()
        let deadline = clock.now + timeout
        while clock.now < deadline {
            if signal.changed { return true }
            try? await Task.sleep(for: .milliseconds(50))
        }
        return signal.changed
    }
}

private final class ChangeSignal: @unchecked Sendable {
    private let lock = NSLock()
    private var didChange = false

    var changed: Bool {
        lock.lock()
        defer { lock.unlock() }
        return didChange
    }

    func markChanged() {
        lock.lock()
        didChange = true
        lock.unlock()
    }
}
