//
//  IndexEngine.swift
//  FileAtlas
//
//  Rekursiver, abbrechbarer Ordner-Scanner mit Live-Updates via AsyncStream.
//

import Foundation

/// Ereignisse, die der Scan währenddessen liefert.
nonisolated enum ScanEvent: Sendable {
    case found(FileEntry)
    case progress(currentPath: String, count: Int)
    case failed(path: String, reason: String)
    case finished(total: Int)
}

/// Off-Main-Aktor, der das Dateisystem rekursiv durchläuft.
actor IndexEngine {

    /// Scannt die übergebenen Wurzelpfade und liefert laufend `ScanEvent`s.
    /// Abbruch erfolgt über `Task`-Cancellation (z. B. `task.cancel()`).
    nonisolated func scan(roots: [URL], skippedFolderNames: Set<String> = []) -> AsyncStream<ScanEvent> {
        AsyncStream(bufferingPolicy: .unbounded) { continuation in
            let task = Task.detached(priority: .userInitiated) {
                await IndexEngine.performScan(
                    roots: roots,
                    skippedFolderNames: skippedFolderNames,
                    continuation: continuation)
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private static func performScan(
        roots: [URL],
        skippedFolderNames: Set<String>,
        continuation: AsyncStream<ScanEvent>.Continuation
    ) async {
        let fm = FileManager.default
        let keys: [URLResourceKey] = [
            .isDirectoryKey, .isPackageKey, .fileSizeKey, .creationDateKey,
            .contentModificationDateKey, .nameKey,
        ]
        var count = 0

        for root in roots {
            if Task.isCancelled { break }

            // Security-Scoped-Zugriff (falls aus Bookmark aufgelöst).
            let scoped = root.startAccessingSecurityScopedResource()
            defer { if scoped { root.stopAccessingSecurityScopedResource() } }

            if let values = try? root.resourceValues(forKeys: Set(keys)) {
                let ext = root.pathExtension.lowercased()
                let isSingleEntry = Self.isSingleEntryPackageOrArchive(
                    isDirectory: values.isDirectory ?? false,
                    isPackage: values.isPackage ?? false,
                    pathExtension: ext
                )
                if isSingleEntry {
                    print("FileAtlas scanner skipped descendants for root: \(root.path(percentEncoded: false))")
                    count += 1
                    continuation.yield(.found(Self.packageEntry(for: root, values: values)))
                    continue
                }
            }

            guard let enumerator = fm.enumerator(
                at: root,
                includingPropertiesForKeys: keys,
                // `.skipsPackageDescendants`: Pakete (.app, .bundle, .framework,
                // .xcodeproj …) werden als ein Eintrag geliefert, ohne hineinzugehen.
                options: [.skipsHiddenFiles, .skipsPackageDescendants],
                errorHandler: { url, error in
                    continuation.yield(.failed(path: url.path(percentEncoded: false),
                                               reason: error.localizedDescription))
                    return true  // weiter mit den übrigen Einträgen
                }
            ) else {
                continuation.yield(.failed(path: root.path(percentEncoded: false),
                                           reason: "Ordner nicht lesbar"))
                continue
            }

            while let fileURL = enumerator.nextObject() as? URL {
                if Task.isCancelled { break }

                guard let values = try? fileURL.resourceValues(forKeys: Set(keys)) else { continue }
                let isDir = values.isDirectory ?? false
                let name = values.name ?? fileURL.lastPathComponent
                let ext = fileURL.pathExtension.lowercased()
                let isSingleEntry = Self.isSingleEntryPackageOrArchive(
                    isDirectory: isDir,
                    isPackage: values.isPackage ?? false,
                    pathExtension: ext
                )
                // Präfix-Abgleich: greift auch bei „Firmware.19.0.1.Rebootless" o. Ä.
                let lowerName = name.lowercased()
                let isSkippedFolder = isDir
                    && skippedFolderNames.contains { lowerName.hasPrefix($0) }

                let entry: FileEntry
                if isSkippedFolder {
                    // Konfigurierter Ordnername (z. B. node_modules, .git, Firmware):
                    // als ein Ordner-Eintrag mit Gesamtgröße, ohne hineinzugehen.
                    enumerator.skipDescendants()
                    entry = Self.folderEntry(for: fileURL, values: values)
                } else if isSingleEntry {
                    // Hart abbrechen: nicht in das Paket hineingehen – unabhängig vom
                    // (unzuverlässigen) LaunchServices-Package-Bit, auf jeder Ebene.
                    enumerator.skipDescendants()
                    print("FileAtlas scanner skipped descendants for: \(fileURL.path(percentEncoded: false))")
                    entry = Self.packageEntry(for: fileURL, values: values)
                } else {
                    entry = Self.fileEntry(for: fileURL, values: values, isDirectory: isDir)
                }

                count += 1
                continuation.yield(.found(entry))

                // Fortschritt gedrosselt melden (jede 25. Datei).
                if count % 25 == 0 {
                    continuation.yield(.progress(
                        currentPath: fileURL.path(percentEncoded: false), count: count))
                }
            }
        }

        continuation.yield(.finished(total: count))
        continuation.finish()
    }

    /// Endungen, die wie ein Paket behandelt werden (zusätzlich zum Package-Bit).
    private static let packageExtensions: Set<String> = [
        "app", "bundle", "framework", "xcodeproj", "xcworkspace", "playground",
        "plugin", "kext", "appex", "xpc", "qlgenerator", "prefpane", "component",
        "mdimporter", "photoslibrary", "fcpbundle", "tvlibrary", "rtfd", "scptd",
        "pkg", "mpkg", "dmg", "zip", "ipa", "tar", "gz", "rar", "7z", "docx",
        "xlsx", "pptx",
    ]

    private static let bundleDirectoryExtensions: Set<String> = [
        "app", "bundle", "framework", "xcodeproj", "xcworkspace", "playground",
        "plugin", "kext", "appex", "xpc", "qlgenerator", "prefpane", "component",
        "mdimporter", "photoslibrary", "fcpbundle", "tvlibrary", "rtfd", "scptd",
        "pkg", "mpkg",
    ]

    private static func isSingleEntryPackageOrArchive(
        isDirectory: Bool,
        isPackage: Bool,
        pathExtension ext: String
    ) -> Bool {
        guard packageExtensions.contains(ext) else { return false }
        if isDirectory {
            return isPackage || bundleDirectoryExtensions.contains(ext)
        }
        return true
    }

    /// Ein Paket/Archiv als einzelne „Datei", ohne dessen Inhalt während des Scans zu lesen.
    private static func packageEntry(for url: URL, values: URLResourceValues) -> FileEntry {
        FileEntry(
            name: values.name ?? url.lastPathComponent,
            path: url,
            size: Int64(values.fileSize ?? 0),
            created: values.creationDate ?? .distantPast,
            modified: values.contentModificationDate ?? .distantPast,
            fileExtension: url.pathExtension,
            isDirectory: false
        )
    }

    /// Ein übersprungener Ordner als einzelner Ordner-Eintrag mit Gesamtgröße.
    private static func folderEntry(for url: URL, values: URLResourceValues) -> FileEntry {
        FileEntry(
            name: values.name ?? url.lastPathComponent,
            path: url,
            size: directorySize(of: url),
            created: values.creationDate ?? .distantPast,
            modified: values.contentModificationDate ?? .distantPast,
            fileExtension: url.pathExtension,
            isDirectory: true
        )
    }

    private static func fileEntry(for url: URL, values: URLResourceValues, isDirectory: Bool) -> FileEntry {
        FileEntry(
            name: values.name ?? url.lastPathComponent,
            path: url,
            size: Int64(values.fileSize ?? 0),
            created: values.creationDate ?? .distantPast,
            modified: values.contentModificationDate ?? .distantPast,
            fileExtension: url.pathExtension,
            isDirectory: isDirectory
        )
    }

    /// Summiert die Größe aller Dateien innerhalb eines Pakets/Ordners.
    private static func directorySize(of url: URL) -> Int64 {
        let keys: [URLResourceKey] = [.fileSizeKey, .isRegularFileKey]
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: keys,
            options: []
        ) else { return 0 }

        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            guard let v = try? fileURL.resourceValues(forKeys: Set(keys)),
                  v.isRegularFile == true else { continue }
            total += Int64(v.fileSize ?? 0)
        }
        return total
    }
}
