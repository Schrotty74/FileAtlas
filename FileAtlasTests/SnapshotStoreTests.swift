//
//  SnapshotStoreTests.swift
//  FileAtlasTests
//

import Foundation
import Testing
@testable import FileAtlas

struct SnapshotStoreTests {
    @Test
    func storageChannelsKeepDevBetaAndFinalSeparate() {
        #expect(SnapshotStore.storageChannel(for: "app.fileatlas.FileAtlas.dev") == .development)
        #expect(SnapshotStore.storageChannel(for: "app.fileatlas.FileAtlas.beta") == .beta)
        #expect(SnapshotStore.storageChannel(for: "app.fileatlas.FileAtlas") == .final)
        #expect(SnapshotStore.storageChannel(for: "app.fileatlas.FileAtlasTests") == .test)

        #expect(SnapshotStore.StorageChannel.development.applicationSupportFolderName == "FileAtlas-dev")
        #expect(SnapshotStore.StorageChannel.beta.applicationSupportFolderName == "FileAtlas-beta")
        #expect(SnapshotStore.StorageChannel.final.applicationSupportFolderName == "FileAtlas")
        #expect(SnapshotStore.StorageChannel.development.keychainService != SnapshotStore.StorageChannel.beta.keychainService)
        #expect(SnapshotStore.StorageChannel.beta.keychainService != SnapshotStore.StorageChannel.final.keychainService)
    }

    @Test
    func diffIgnoresSubsecondModificationDateDifferences() {
        let path = URL(fileURLWithPath: "/Catalog/Unchanged.zip")
        let baselineDate = Date(timeIntervalSince1970: 1_700_000_000)
        let scannedDate = Date(timeIntervalSince1970: 1_700_000_000.875)
        let baseline = Snapshot(
            date: baselineDate,
            rootPaths: ["/Catalog"],
            entries: [entry(path: path, modified: baselineDate)]
        )

        let diff = SnapshotStore().diff(
            current: [entry(path: path, modified: scannedDate)],
            baseline: baseline
        )

        #expect(diff.isEmpty)
    }

    @Test
    func diffReportsWholeSecondModificationDateChanges() {
        let path = URL(fileURLWithPath: "/Catalog/Changed.zip")
        let baselineDate = Date(timeIntervalSince1970: 1_700_000_000)
        let changedDate = Date(timeIntervalSince1970: 1_700_000_001)
        let baseline = Snapshot(
            date: baselineDate,
            rootPaths: ["/Catalog"],
            entries: [entry(path: path, modified: baselineDate)]
        )

        let diff = SnapshotStore().diff(
            current: [entry(path: path, modified: changedDate)],
            baseline: baseline
        )

        #expect(diff.changed.count == 1)
    }

    @Test
    func automaticSnapshotsKeepOnlyTheTwoNewestForEachLocation() {
        let catalog = "/Catalog"
        let otherCatalog = "/OtherCatalog"
        let earliest = Date(timeIntervalSince1970: 1_700_000_000)
        let middle = Date(timeIntervalSince1970: 1_700_000_100)
        let newest = Date(timeIntervalSince1970: 1_700_000_200)

        let oldestAutomatic = Snapshot(date: earliest, rootPaths: [catalog], entries: [], source: .automatic)
        let middleAutomatic = Snapshot(date: middle, rootPaths: [catalog], entries: [], source: .automatic)
        let newestAutomatic = Snapshot(date: newest, rootPaths: [catalog], entries: [], source: .automatic)
        let otherAutomatic = Snapshot(date: newest, rootPaths: [otherCatalog], entries: [], source: .automatic)
        let manualSnapshot = Snapshot(date: newest, rootPaths: [catalog], entries: [], source: .manual)

        let snapshots = [oldestAutomatic, middleAutomatic, newestAutomatic, otherAutomatic, manualSnapshot]
        let retained = SnapshotStore.automaticSnapshots(matching: [catalog], from: snapshots)
        let toPrune = SnapshotStore.automaticSnapshotsToPrune(matching: [catalog], from: snapshots)

        #expect(retained.map(\.id) == [newestAutomatic.id, middleAutomatic.id, oldestAutomatic.id])
        #expect(toPrune.map(\.id) == [oldestAutomatic.id])
    }

    private func entry(path: URL, modified: Date) -> FileEntry {
        FileEntry(
            name: path.lastPathComponent,
            path: path,
            size: 1_024,
            created: modified,
            modified: modified,
            fileExtension: path.pathExtension,
            isDirectory: false
        )
    }
}
