//
//  IndexViewModel.swift
//  FileAtlas
//
//  Haupt-ViewModel: Scan-Steuerung, Suche, Filter, Sortierung, Presets,
//  Snapshots und Export-Anbindung.
//

import SwiftUI
import AppKit
import CoreServices
import UniformTypeIdentifiers

struct AvailableUpdate: Identifiable, Equatable {
    var id: String { versionTag }
    let versionTag: String
    let releaseURL: URL
}

private struct GitHubReleaseResponse: Decodable {
    let tagName: String
    let htmlURL: String?

    private enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlURL = "html_url"
    }
}

@Observable
@MainActor
final class IndexViewModel {

    // MARK: - Index-Zustand

    private(set) var entries: [FileEntry] = [] {
        didSet {
            guard !isUpdatingSelectionEntries else { return }
            recomputeDisplayedEntries()
        }
    }
    private(set) var displayedEntries: [FileEntry] = []
    var scanRoots: [URL] = []
    private(set) var selectedScanRoot: URL? = nil {
        didSet {
            guard !isUpdatingSelectionEntries else { return }
            activateScopedPresetForSelectedRootIfNeeded()
            recomputeDisplayedEntries()
        }
    }
    private var indexedEntriesByRootPath: [String: [FileEntry]] = [:]
    private var isUpdatingSelectionEntries = false

    // Scan-Fortschritt
    private(set) var isScanning = false
    private(set) var scanProgressCount = 0
    private(set) var currentScanPath = ""
    private(set) var scanErrors: [ScanFailure] = []

    // MARK: - Suche / Filter / Sortierung

    var searchText = "" {
        didSet { scheduleSearchRecompute() }
    }
    var searchAllFolders = false {
        didSet { recomputeDisplayedEntries() }
    }
    var sortField: SortField = .name {
        didSet { recomputeDisplayedEntries() }
    }
    var sortDirection: SortDirection = .ascending {
        didSet { recomputeDisplayedEntries() }
    }
    var showOnlyDuplicates = false {
        didSet { recomputeDisplayedEntries() }
    }
    var dateFrom: Date? = nil {
        didSet { recomputeDisplayedEntries() }
    }
    var dateTo: Date? = nil {
        didSet { recomputeDisplayedEntries() }
    }
    var selectedTagFilter: FileTag? = nil {
        didSet { recomputeDisplayedEntries() }
    }

    var rowDensity: FileRowDensity {
        didSet { UserDefaults.standard.set(rowDensity.rawValue, forKey: Self.rowDensityKey) }
    }
    var iconDisplayMode: IconDisplayMode {
        didSet { UserDefaults.standard.set(iconDisplayMode.rawValue, forKey: Self.iconDisplayModeKey) }
    }
    var autoScanOnLaunchMode: AutoScanOnLaunchMode {
        didSet { UserDefaults.standard.set(autoScanOnLaunchMode.rawValue, forKey: Self.autoScanOnLaunchModeKey) }
    }

    private(set) var recentScanRoots: [URL] = []
    private(set) var extensionTags: [String: Set<FileTag>] = [:] {
        didSet { recomputeDisplayedEntries() }
    }
    private(set) var customTags: [FileTag] = []
    private(set) var lastAutoRescanMessage: String? = nil
    private(set) var autoScanLaunchMessage: String? = nil
    private(set) var availableUpdate: AvailableUpdate? = nil
    private(set) var isCheckingForUpdates = false

    var availableTags: [FileTag] {
        (FileTag.predefined + customTags).uniquedByTitle()
    }

    var knownFilterScopeFolders: [URL] {
        var folders = scanRoots + recentScanRoots
        var seen = Set<String>()
        folders.removeAll { url in
            !seen.insert(Self.normalizedPath(for: url)).inserted
        }
        return folders
    }

    // MARK: - Presets

    private(set) var presets: [FilterPreset] = [] {
        didSet { recomputeDisplayedEntries() }
    }
    var activePresetID: FilterPreset.ID? = nil {
        didSet { recomputeDisplayedEntries() }
    }

    var activePreset: FilterPreset? {
        guard let id = activePresetID else { return nil }
        return presets.first { $0.id == id }
    }

    // MARK: - Übersprungene Ordnernamen

    /// Ordnernamen, die der Scanner als einzelnen Eintrag behandelt (nicht rekursiv).
    var skippedFolderNames: [String] {
        didSet { UserDefaults.standard.set(skippedFolderNames, forKey: Self.skippedFoldersKey) }
    }

    private static let skippedFoldersKey = "FileAtlas.skippedFolders"
    private static let skippedFoldersMigrationKey = "FileAtlas.skippedFoldersMigrationVersion"
    private static let rowDensityKey = "FileAtlas.rowDensity"
    private static let iconDisplayModeKey = "FileAtlas.iconDisplayMode"
    private static let autoScanOnLaunchModeKey = "FileAtlas.autoScanOnLaunchMode"
    private static let cachedRootPathsOnQuitKey = "FileAtlas.cachedRootPathsOnQuit"
    private static let recentScanRootsKey = "FileAtlas.recentScanRoots"
    private static let legacyFileTagsKey = "FileAtlas.fileTags"
    private static let extensionTagsKey = "FileAtlas.extensionTags"
    private static let extensionTagsMigrationKey = "FileAtlas.didMigrateFileTagsToExtensionTagsV1"
    private static let customTagsKey = "FileAtlas.customTags"
    private static let updateLastCheckKey = "FileAtlas.updateLastCheck"
    private static let updateLatestTagKey = "FileAtlas.updateLatestTag"
    private static let updateLatestURLKey = "FileAtlas.updateLatestURL"
    private static let updateCheckInterval: TimeInterval = 24 * 60 * 60
    private static let latestReleaseAPIURL = URL(string: "https://api.github.com/repos/Schrotty74/FileAtlas/releases/latest")!
    private static let latestReleaseWebURL = URL(string: "https://github.com/Schrotty74/FileAtlas/releases/latest")!
    private nonisolated static let searchDebounceDelay: Duration = .milliseconds(150)
    private nonisolated static let scanPublishInterval: Duration = .milliseconds(200)
    private nonisolated static let scanPublishBatchSize = 200
    /// Bei neuen Default-Einträgen erhöhen, damit die Migration erneut läuft.
    private static let skippedFoldersMigrationVersion = 1
    static let defaultSkippedFolders = ["node_modules", ".git", "Firmware", "Cache", "Caches", ".Trashes", "__MACOSX"]

    func addSkippedFolder(_ name: String) {
        let n = name.trimmingCharacters(in: .whitespaces)
        guard !n.isEmpty,
              !skippedFolderNames.contains(where: { $0.caseInsensitiveCompare(n) == .orderedSame })
        else { return }
        skippedFolderNames.append(n)
    }

    func removeSkippedFolder(_ name: String) {
        skippedFolderNames.removeAll { $0 == name }
    }

    /// Öffnet einen Finder-Dialog und übernimmt die **Namen** der gewählten Ordner
    /// (nicht den Pfad) in die Ignored-Liste.
    func addSkippedFoldersViaPanel() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = true
        panel.prompt = NSLocalizedString("Add", comment: "")
        guard panel.runModal() == .OK else { return }
        for url in panel.urls {
            addSkippedFolder(url.lastPathComponent)
        }
    }

    // MARK: - Auswahl

    var selection: Set<FileEntry.ID> = []

    var selectedEntry: FileEntry? {
        displayedEntries.first { selection.contains($0.id) }
            ?? displayedEntries.first { $0.id == selection.first }
    }

    var isSearchAllFoldersActive: Bool {
        searchAllFolders && !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Snapshots / Vergleich

    var currentDiff: SnapshotDiff? = nil

    // MARK: - Abhängigkeiten

    private let engine = IndexEngine()
    private let snapshotStore = SnapshotStore()
    private var searchDebounceTask: Task<Void, Never>? = nil
    private var scanTask: Task<Void, Never>? = nil
    private var autoScanLaunchTask: Task<Void, Never>? = nil
    private var didStartAutoScanOnLaunch = false
    private var didScheduleUpdateCheckOnLaunch = false
    private var folderMonitor: FolderChangeMonitor? = nil
    private var pendingAutoRescanTask: Task<Void, Never>? = nil
    private var suppressAutoRescanUntil: Date? = nil

    // MARK: - Init

    init() {
        let defaults = UserDefaults.standard
        self.rowDensity = defaults.string(forKey: Self.rowDensityKey).flatMap(FileRowDensity.init(rawValue:)) ?? .normal
        self.iconDisplayMode = defaults.string(forKey: Self.iconDisplayModeKey)
            .flatMap(IconDisplayMode.init(rawValue:)) ?? .real
        self.autoScanOnLaunchMode = defaults.string(forKey: Self.autoScanOnLaunchModeKey)
            .flatMap(AutoScanOnLaunchMode.init(rawValue:)) ?? .off

        if let stored = defaults.stringArray(forKey: Self.skippedFoldersKey) {
            // Einmalige Migration: fehlende Default-Einträge ergänzen.
            if defaults.integer(forKey: Self.skippedFoldersMigrationKey) < Self.skippedFoldersMigrationVersion {
                var merged = stored
                for def in Self.defaultSkippedFolders
                where !merged.contains(where: { $0.caseInsensitiveCompare(def) == .orderedSame }) {
                    merged.append(def)
                }
                self.skippedFolderNames = merged
                defaults.set(merged, forKey: Self.skippedFoldersKey)
                defaults.set(Self.skippedFoldersMigrationVersion, forKey: Self.skippedFoldersMigrationKey)
            } else {
                self.skippedFolderNames = stored
            }
        } else {
            // Erstinstallation: Defaults setzen, Migration als erledigt markieren.
            self.skippedFolderNames = Self.defaultSkippedFolders
            defaults.set(Self.skippedFoldersMigrationVersion, forKey: Self.skippedFoldersMigrationKey)
        }

        // Bestehende Liste bereinigen: trimmen, Leereinträge & Duplikate entfernen.
        let cleaned = Self.sanitize(skippedFolderNames)
        if cleaned != skippedFolderNames {
            skippedFolderNames = cleaned                 // löst didSet → persistiert
        }

        loadPresets()
        restoreSavedLocations()
        loadRecentScanRoots()
        loadCustomTags()
        loadExtensionTags()
        loadCachedUpdateResult()
    }

    /// Trimmt Einträge, verwirft Leere und entfernt case-insensitive Duplikate.
    private static func sanitize(_ names: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for raw in names {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            let key = trimmed.lowercased()
            if seen.insert(key).inserted {
                result.append(trimmed)
            }
        }
        return result
    }

    // MARK: - Update-Prüfung

    func scheduleUpdateCheckOnLaunch() {
        guard !didScheduleUpdateCheckOnLaunch else { return }
        didScheduleUpdateCheckOnLaunch = true

        Task { [weak self] in
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            await self?.checkForUpdates(force: false)
        }
    }

    func checkForUpdates(force: Bool) async {
        if !force, !shouldRunAutomaticUpdateCheck() {
            return
        }

        isCheckingForUpdates = true
        defer { isCheckingForUpdates = false }

        do {
            var request = URLRequest(url: Self.latestReleaseAPIURL)
            request.setValue("FileAtlas", forHTTPHeaderField: "User-Agent")
            request.timeoutInterval = 10

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode)
            else { return }

            let release = try JSONDecoder().decode(GitHubReleaseResponse.self, from: data)
            let releaseURL = release.htmlURL.flatMap(URL.init(string:)) ?? Self.latestReleaseWebURL
            updateCachedRelease(tag: release.tagName, releaseURL: releaseURL)
        } catch {
            // Netzwerkfehler und Rate Limits bewusst still ignorieren.
            return
        }
    }

    func openAvailableUpdate() {
        NSWorkspace.shared.open(availableUpdate?.releaseURL ?? Self.latestReleaseWebURL)
    }

    private func shouldRunAutomaticUpdateCheck() -> Bool {
        let lastCheck = UserDefaults.standard.object(forKey: Self.updateLastCheckKey) as? Date
        guard let lastCheck else { return true }
        return Date().timeIntervalSince(lastCheck) >= Self.updateCheckInterval
    }

    private func loadCachedUpdateResult() {
        let defaults = UserDefaults.standard
        guard let tag = defaults.string(forKey: Self.updateLatestTagKey) else { return }
        let releaseURL = defaults.string(forKey: Self.updateLatestURLKey).flatMap(URL.init(string:)) ?? Self.latestReleaseWebURL
        if Self.isVersion(tag, newerThan: Self.currentAppVersion()) {
            availableUpdate = AvailableUpdate(versionTag: tag, releaseURL: releaseURL)
        }
    }

    private func updateCachedRelease(tag: String, releaseURL: URL) {
        let defaults = UserDefaults.standard
        defaults.set(Date(), forKey: Self.updateLastCheckKey)
        defaults.set(tag, forKey: Self.updateLatestTagKey)
        defaults.set(releaseURL.absoluteString, forKey: Self.updateLatestURLKey)

        if Self.isVersion(tag, newerThan: Self.currentAppVersion()) {
            availableUpdate = AvailableUpdate(versionTag: tag, releaseURL: releaseURL)
        } else {
            availableUpdate = nil
        }
    }

    private nonisolated static func currentAppVersion() -> String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        return version ?? build ?? "0"
    }

    private nonisolated static func isVersion(_ candidate: String, newerThan current: String) -> Bool {
        let lhs = versionComponents(candidate)
        let rhs = versionComponents(current)
        let count = max(lhs.count, rhs.count)

        for index in 0..<count {
            let left = index < lhs.count ? lhs[index] : 0
            let right = index < rhs.count ? rhs[index] : 0
            if left != right {
                return left > right
            }
        }
        return false
    }

    private nonisolated static func versionComponents(_ version: String) -> [Int] {
        version
            .trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
            .split { !$0.isNumber }
            .compactMap { Int($0) }
    }

    // MARK: - Abgeleitete Liste (gefiltert + sortiert)

    private func scheduleSearchRecompute() {
        searchDebounceTask?.cancel()
        searchDebounceTask = Task { [weak self] in
            try? await Task.sleep(for: Self.searchDebounceDelay)
            guard !Task.isCancelled else { return }
            self?.recomputeDisplayedEntries()
        }
    }

    private func recomputeDisplayedEntries() {
        let trimmed = searchText.trimmingCharacters(in: .whitespaces)
        let shouldSearchAllFolders = searchAllFolders && !trimmed.isEmpty
        var list = shouldSearchAllFolders ? entriesAcrossIndexedRoots() : entries

        if let selectedScanRoot, !shouldSearchAllFolders {
            list = list.filter { Self.isPath($0.path, inside: selectedScanRoot) }
        }

        if let preset = activePreset, activePresetAppliesToCurrentFolder(preset) {
            list = list.filter { preset.allows($0) }
        }
        if showOnlyDuplicates {
            list = list.filter { $0.isDuplicate }
        }
        if let selectedTagFilter {
            list = list.filter { tags(for: $0).contains(selectedTagFilter) }
        }

        if !trimmed.isEmpty {
            if let q = SizeQuery.parse(trimmed) {
                list = list.filter { q.matches($0.size) }
            } else {
                let needle = trimmed.lowercased()
                let ext = FilterPreset.normalize(trimmed)
                list = list.filter {
                    $0.name.lowercased().contains(needle)
                        || FilterPreset.normalize($0.fileExtension) == ext
                }
            }
        }

        if let from = dateFrom {
            list = list.filter { $0.modified >= from }
        }
        if let to = dateTo {
            list = list.filter { $0.modified <= to }
        }

        displayedEntries = list.sorted(by: comparator)
    }

    private func entriesAcrossIndexedRoots() -> [FileEntry] {
        var seen = Set<String>()
        var result: [FileEntry] = []

        for cachedEntries in indexedEntriesByRootPath.values {
            for entry in cachedEntries where seen.insert(Self.normalizedPath(for: entry.path)).inserted {
                result.append(entry)
            }
        }

        for entry in entries where seen.insert(Self.normalizedPath(for: entry.path)).inserted {
            result.append(entry)
        }

        return result
    }

    func searchLocationDescription(for entry: FileEntry) -> String? {
        guard isSearchAllFoldersActive else { return nil }

        let entryPath = Self.normalizedPath(for: entry.path)
        guard let rootPath = indexedSearchRootPaths()
            .sorted(by: { $0.count > $1.count })
            .first(where: { Self.normalizedPath(entryPath, isInsideNormalizedPath: $0) })
        else { return nil }

        let rootName = URL(fileURLWithPath: rootPath).lastPathComponent
        let relativePath = entryPath == rootPath
            ? ""
            : String(entryPath.dropFirst(rootPath.count + 1))
        let folderPath = (relativePath as NSString).deletingLastPathComponent

        if folderPath.isEmpty || folderPath == "." {
            return rootName
        }
        return "\(rootName)/\(folderPath)"
    }

    private func indexedSearchRootPaths() -> [String] {
        var paths = Array(indexedEntriesByRootPath.keys)
        paths.append(contentsOf: scanRoots.map { Self.normalizedPath(for: $0) })
        paths.append(contentsOf: recentScanRoots.map { Self.normalizedPath(for: $0) })
        if let selectedScanRoot {
            paths.append(Self.normalizedPath(for: selectedScanRoot))
        }

        var seen = Set<String>()
        return paths.filter { seen.insert($0).inserted }
    }

    private var comparator: (FileEntry, FileEntry) -> Bool {
        let asc = sortDirection == .ascending
        switch sortField {
        case .name:     return { asc ? $0.name.localizedStandardCompare($1.name) == .orderedAscending : $0.name.localizedStandardCompare($1.name) == .orderedDescending }
        case .size:     return { asc ? $0.size < $1.size : $0.size > $1.size }
        case .modified: return { asc ? $0.modified < $1.modified : $0.modified > $1.modified }
        case .created:  return { asc ? $0.created < $1.created : $0.created > $1.created }
        case .type:     return { asc ? $0.fileExtension < $1.fileExtension : $0.fileExtension > $1.fileExtension }
        }
    }

    /// Klick auf eine Spalte: gleiche Spalte → Richtung umkehren, sonst neue Spalte aufsteigend.
    func toggleSort(_ field: SortField) {
        if sortField == field {
            sortDirection.toggle()
        } else {
            sortField = field
            sortDirection = .ascending
        }
    }

    // MARK: - Statistik

    var totalSize: Int64 { displayedEntries.reduce(0) { $0 + $1.size } }
    var duplicateCount: Int { entries.filter { $0.isDuplicate }.count }
    var displayedDuplicateCount: Int { displayedEntries.filter { $0.isDuplicate }.count }
    var hasExportableContent: Bool { currentDiff != nil || !entries.isEmpty }
    var hasActiveDisplayFilter: Bool {
        if let preset = activePreset, activePresetAppliesToCurrentFolder(preset) {
            return true
        }
        return showOnlyDuplicates
            || selectedTagFilter != nil
            || !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || dateFrom != nil
            || dateTo != nil
    }

    // MARK: - Ordnerauswahl

    func addFolders() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = true
        panel.prompt = NSLocalizedString("Add", comment: "")
        guard panel.runModal() == .OK else { return }

        for url in panel.urls where !scanRoots.contains(where: { sameFilePath($0, url) }) {
            scanRoots.append(url)
            storeBookmark(for: url)
        }
    }

    func removeRoot(_ url: URL) {
        scanRoots.removeAll { sameFilePath($0, url) }
        if selectedScanRoot.map({ sameFilePath($0, url) }) == true {
            selectedScanRoot = nil
        }
        indexedEntriesByRootPath.removeValue(forKey: Self.normalizedPath(for: url))
        persistCachedRootPathsForAutoScan()
        removeRecentScanRoot(url)
        removeBookmark(for: url)
    }

    func stats(for root: URL) -> (count: Int, size: Int64)? {
        if selectedScanRoot.map({ sameFilePath($0, root) }) == true {
            return (displayedEntries.count, displayedEntries.reduce(0) { $0 + $1.size })
        }

        if selectedScanRoot == nil {
            let rootPath = Self.displayPath(for: root)
            let visibleMatches = displayedEntries.filter { Self.path($0.pathKey, isInsidePath: rootPath) }
            return (visibleMatches.count, visibleMatches.reduce(0) { $0 + $1.size })
        }

        let key = Self.normalizedPath(for: root)
        guard let matches = indexedEntriesByRootPath[key], !matches.isEmpty else { return nil }
        return (matches.count, matches.reduce(0) { $0 + $1.size })
    }

    func tags(for entry: FileEntry) -> Set<FileTag> {
        guard let key = Self.extensionKey(for: entry) else { return [] }
        return extensionTags[key] ?? []
    }

    func hasTag(_ tag: FileTag, for entry: FileEntry) -> Bool {
        tags(for: entry).contains(tag)
    }

    func toggleTag(_ tag: FileTag, for entry: FileEntry) {
        guard let key = Self.extensionKey(for: entry) else { return }
        var tags = extensionTags[key] ?? []
        if tags.contains(tag) {
            tags.remove(tag)
        } else {
            tags.insert(tag)
        }
        if tags.isEmpty {
            extensionTags.removeValue(forKey: key)
        } else {
            extensionTags[key] = tags
        }
        persistExtensionTags()
    }

    func addCustomTag(_ title: String) {
        let tag = FileTag(title)
        guard !tag.title.isEmpty,
              !availableTags.contains(where: { $0.title.caseInsensitiveCompare(tag.title) == .orderedSame })
        else { return }
        customTags.append(tag)
        persistCustomTags()
    }

    func removeCustomTag(_ tag: FileTag) {
        customTags.removeAll { $0 == tag }
        if selectedTagFilter == tag { selectedTagFilter = nil }
        persistCustomTags()

        let currentExtensionTags = extensionTags
        Task.detached(priority: .userInitiated) { [weak self] in
            var updatedExtensionTags = currentExtensionTags
            var didChange = false

            for key in currentExtensionTags.keys {
                guard var tags = updatedExtensionTags[key],
                      tags.remove(tag) != nil else { continue }
                if tags.isEmpty {
                    updatedExtensionTags.removeValue(forKey: key)
                } else {
                    updatedExtensionTags[key] = tags
                }
                didChange = true
            }

            guard didChange else { return }
            await MainActor.run { [weak self] in
                self?.extensionTags = updatedExtensionTags
                self?.persistExtensionTags()
            }
        }
    }

    func openSelectedEntry() {
        guard let selectedEntry else { return }
        NSWorkspace.shared.open(selectedEntry.path)
    }

    func revealSelectedEntryInFinder() {
        guard let selectedEntry else { return }
        NSWorkspace.shared.activateFileViewerSelecting([selectedEntry.path])
    }

    func quickLookSelectedEntry() {
        guard let selectedEntry else { return }
        suppressAutoRescanForPreview()
        QuickLookPresenter.shared.present(selectedEntry.path, accessURL: securityScopedAccessRoot(for: selectedEntry.path))
    }

    func startRecentScan(root: URL) {
        let scopedRoot = scanRoots.first { sameFilePath($0, root) } ?? root
        selectOrScanRoot(scopedRoot)
    }

    func selectOrScanRoot(_ root: URL) {
        let key = Self.normalizedPath(for: root)
        if let cachedEntries = indexedEntriesByRootPath[key], !cachedEntries.isEmpty {
            showIndexedEntries(cachedEntries, for: root)
        } else {
            let currentEntries = indexedEntries(for: root)
            if currentEntries.isEmpty {
                startScan(roots: [root])
            } else {
                indexedEntriesByRootPath[key] = currentEntries
                showIndexedEntries(currentEntries, for: root)
            }
        }
    }

    private func showIndexedEntries(_ indexedEntries: [FileEntry], for root: URL) {
        isUpdatingSelectionEntries = true
        entries = indexedEntries
        selectedScanRoot = root
        isUpdatingSelectionEntries = false
        selection = []
        currentDiff = nil
        activateScopedPresetForSelectedRootIfNeeded()
        recomputeDisplayedEntries()
    }

    func rescanSelectedRoot() {
        if let selectedScanRoot {
            startScan(roots: [selectedScanRoot])
        } else {
            startScan()
        }
    }

    func addRecentScanRoot(_ root: URL) {
        rememberRecentScanRoots([root])
    }

    func isRecentScanRoot(_ root: URL) -> Bool {
        recentScanRoots.contains { sameFilePath($0, root) }
    }

    func removeRecentScanRoot(_ root: URL) {
        recentScanRoots.removeAll { sameFilePath($0, root) }
        persistRecentScanRoots()
        if !scanRoots.contains(where: { sameFilePath($0, root) }) {
            removeBookmark(for: root)
        }
    }

    func clearAutoRescanMessage() {
        lastAutoRescanMessage = nil
    }

    func clearIndexCache() {
        indexedEntriesByRootPath.removeAll()
        isUpdatingSelectionEntries = true
        entries = []
        selectedScanRoot = nil
        displayedEntries = []
        isUpdatingSelectionEntries = false
        selection = []
        currentDiff = nil
        persistCachedRootPathsForAutoScan()
    }

    private func rememberRecentScanRoots(_ roots: [URL]) {
        var combined = roots + recentScanRoots
        var seen = Set<String>()
        combined.removeAll { url in
            let key = Self.normalizedPath(for: url)
            return !seen.insert(key).inserted
        }
        recentScanRoots = Array(combined.prefix(5))
        persistRecentScanRoots()
    }

    private func sameFilePath(_ lhs: URL, _ rhs: URL) -> Bool {
        Self.normalizedPath(for: lhs) == Self.normalizedPath(for: rhs)
    }

    private nonisolated static func normalizedPath(for url: URL) -> String {
        var path = url.standardizedFileURL.resolvingSymlinksInPath().path(percentEncoded: false)
        while path.count > 1 && path.hasSuffix("/") {
            path.removeLast()
        }
        return path
    }

    private static func displayPath(for url: URL) -> String {
        var path = url.path(percentEncoded: false)
        while path.count > 1 && path.hasSuffix("/") {
            path.removeLast()
        }
        return path
    }

    private func indexedEntries(for root: URL) -> [FileEntry] {
        let key = Self.normalizedPath(for: root)
        if let cachedEntries = indexedEntriesByRootPath[key], !cachedEntries.isEmpty {
            return cachedEntries
        }
        if let cachedEntries = indexedEntriesFromCoveringRoot(for: root, normalizedPath: key) {
            return cachedEntries
        }
        return entries.filter { Self.isPath($0.path, inside: root) }
    }

    private func indexedEntriesFromCoveringRoot(for root: URL, normalizedPath rootPath: String) -> [FileEntry]? {
        let displayRootPath = Self.displayPath(for: root)
        let coveringCaches = indexedEntriesByRootPath
            .filter { cachedRootPath, cachedEntries in
                !cachedEntries.isEmpty && Self.normalizedPath(rootPath, isInsideNormalizedPath: cachedRootPath)
            }
            .sorted { $0.key.count > $1.key.count }

        for (_, cachedEntries) in coveringCaches {
            let matchingEntries = cachedEntries.filter {
                Self.path($0.pathKey, isInsidePath: displayRootPath)
            }
            if !matchingEntries.isEmpty {
                return matchingEntries
            }
        }

        return nil
    }

    private static func isPath(_ url: URL, inside root: URL) -> Bool {
        let path = normalizedPath(for: url)
        let rootPath = normalizedPath(for: root)
        return normalizedPath(path, isInsideNormalizedPath: rootPath)
    }

    private static func normalizedPath(_ path: String, isInsideNormalizedPath rootPath: String) -> Bool {
        return path == rootPath || path.hasPrefix(rootPath + "/")
    }

    private static func path(_ path: String, isInsidePath rootPath: String) -> Bool {
        return path == rootPath || path.hasPrefix(rootPath + "/")
    }

    func filterScopePath(for url: URL) -> String {
        Self.normalizedPath(for: url)
    }

    func securityScopedAccessRoot(for url: URL) -> URL {
        scanRoots.first { Self.isPath(url, inside: $0) } ?? url
    }

    private func activePresetAppliesToCurrentFolder(_ preset: FilterPreset) -> Bool {
        guard !preset.appliesToAllFolders else { return true }
        guard let selectedScanRoot else { return false }
        return scopedPreset(preset, appliesTo: selectedScanRoot)
    }

    private func activateScopedPresetForSelectedRootIfNeeded() {
        guard let selectedScanRoot else { return }

        if let activePreset {
            if activePreset.appliesToAllFolders || scopedPreset(activePreset, appliesTo: selectedScanRoot) {
                return
            }
        }

        if let scopedPreset = presets.first(where: {
            !$0.appliesToAllFolders && scopedPreset($0, appliesTo: selectedScanRoot)
        }) {
            activePresetID = scopedPreset.id
        } else if activePreset?.appliesToAllFolders == false {
            activePresetID = nil
        }
    }

    private func scopedPreset(_ preset: FilterPreset, appliesTo root: URL) -> Bool {
        preset.scopedFolderPaths.contains(Self.normalizedPath(for: root))
    }

    private func loadRecentScanRoots() {
        let paths = UserDefaults.standard.stringArray(forKey: Self.recentScanRootsKey) ?? []
        recentScanRoots = paths.map { URL(fileURLWithPath: $0) }
    }

    private func persistRecentScanRoots() {
        UserDefaults.standard.set(recentScanRoots.map { $0.path(percentEncoded: false) }, forKey: Self.recentScanRootsKey)
    }

    private func loadCustomTags() {
        let raw = UserDefaults.standard.stringArray(forKey: Self.customTagsKey) ?? []
        let loaded = raw.map { FileTag($0) }.filter { !$0.title.isEmpty }
        customTags = loaded.uniquedByTitle()
    }

    private func persistCustomTags() {
        UserDefaults.standard.set(customTags.map(\.title), forKey: Self.customTagsKey)
    }

    private func loadExtensionTags() {
        let defaults = UserDefaults.standard
        let storedExtensionTags = defaults.dictionary(forKey: Self.extensionTagsKey) as? [String: [String]] ?? [:]

        if defaults.bool(forKey: Self.extensionTagsMigrationKey) {
            extensionTags = Self.loadedExtensionTags(from: storedExtensionTags)
        } else {
            let legacyFileTags = defaults.dictionary(forKey: Self.legacyFileTagsKey) as? [String: [String]] ?? [:]
            extensionTags = Self.migratedExtensionTags(
                fromLegacyFileTags: legacyFileTags,
                existingExtensionTags: storedExtensionTags
            )
            persistExtensionTags()
            defaults.removeObject(forKey: Self.legacyFileTagsKey)
            defaults.set(true, forKey: Self.extensionTagsMigrationKey)
        }

        let tagsFromFiles = extensionTags.values.flatMap { $0 }
        let migratedCustomTags = tagsFromFiles.filter { tag in
            !FileTag.predefined.contains { predefined in
                predefined.title.caseInsensitiveCompare(tag.title) == .orderedSame
            }
        }
        customTags = (customTags + migratedCustomTags).uniquedByTitle()
        persistCustomTags()
    }

    private func persistExtensionTags() {
        let raw = extensionTags.mapValues { $0.map(\.rawValue) }
        UserDefaults.standard.set(raw, forKey: Self.extensionTagsKey)
    }

    private nonisolated static func loadedExtensionTags(from raw: [String: [String]]) -> [String: Set<FileTag>] {
        var loadedTags: [String: Set<FileTag>] = [:]
        for (rawExtension, storedTags) in raw {
            let key = FilterPreset.normalize(rawExtension)
            guard !key.isEmpty else { continue }
            loadedTags[key, default: []].formUnion(storedTags.map { FileTag(rawValue: $0) })
        }
        return loadedTags
    }

    private nonisolated static func migratedExtensionTags(
        fromLegacyFileTags legacyFileTags: [String: [String]],
        existingExtensionTags: [String: [String]]
    ) -> [String: Set<FileTag>] {
        var migratedTags = loadedExtensionTags(from: existingExtensionTags)
        for (path, storedTags) in legacyFileTags {
            let key = FilterPreset.normalize(URL(fileURLWithPath: path).pathExtension)
            guard !key.isEmpty else { continue }
            migratedTags[key, default: []].formUnion(storedTags.map { FileTag(rawValue: $0) })
        }
        return migratedTags
    }

    private nonisolated static func extensionKey(for entry: FileEntry) -> String? {
        let key = FilterPreset.normalize(entry.fileExtension)
        return key.isEmpty ? nil : key
    }

    // MARK: - Scannen

    func startAutoScanOnLaunchIfNeeded() {
        guard !didStartAutoScanOnLaunch else { return }
        didStartAutoScanOnLaunch = true

        let roots = autoScanLaunchRoots()
        guard autoScanOnLaunchMode != .off, !roots.isEmpty else { return }

        autoScanLaunchTask?.cancel()
        autoScanLaunchTask = Task { [weak self] in
            guard let self else { return }
            let total = roots.count

            for (index, root) in roots.enumerated() {
                guard !Task.isCancelled else { break }

                while self.isScanning && !Task.isCancelled {
                    try? await Task.sleep(for: .milliseconds(200))
                }
                guard !Task.isCancelled else { break }

                self.autoScanLaunchMessage = String(
                    format: NSLocalizedString("Scanning folder %lld of %lld…", comment: "Progress message while automatically scanning folders on launch."),
                    index + 1,
                    total
                )
                self.startScan(roots: [root])

                while self.isScanning && !Task.isCancelled {
                    try? await Task.sleep(for: .milliseconds(200))
                }
            }

            guard !Task.isCancelled else { return }
            self.autoScanLaunchMessage = nil
            self.autoScanLaunchTask = nil
        }
    }

    func persistCachedRootPathsForAutoScan() {
        let paths = Array(indexedEntriesByRootPath.keys).sorted()
        UserDefaults.standard.set(paths, forKey: Self.cachedRootPathsOnQuitKey)
    }

    private func autoScanLaunchRoots() -> [URL] {
        switch autoScanOnLaunchMode {
        case .off:
            return []
        case .allSavedAndRecent:
            return deduplicatedRoots(scanRoots + recentScanRoots)
        case .restoreCached:
            let storedPaths = UserDefaults.standard.stringArray(forKey: Self.cachedRootPathsOnQuitKey) ?? []
            return deduplicatedRoots(storedPaths.map { urlForStoredRootPath($0) })
        }
    }

    private func urlForStoredRootPath(_ path: String) -> URL {
        let storedURL = URL(fileURLWithPath: path)
        let knownRoots = scanRoots + recentScanRoots
        return knownRoots.first { sameFilePath($0, storedURL) } ?? storedURL
    }

    private func deduplicatedRoots(_ roots: [URL]) -> [URL] {
        var seen = Set<String>()
        return roots.filter { seen.insert(Self.normalizedPath(for: $0)).inserted }
    }

    /// Scannt entweder die übergebenen Orte oder – falls `nil` – alle gespeicherten Orte.
    func startScan(roots: [URL]? = nil, rememberInQuickAccess: Bool = false) {
        let roots = roots ?? scanRoots
        guard !roots.isEmpty, !isScanning else { return }
        cancelScan()
        selectedScanRoot = roots.count == 1 ? roots[0] : nil

        if rememberInQuickAccess {
            rememberRecentScanRoots(roots)
        }
        restartFolderMonitor()
        isScanning = true
        scanProgressCount = 0
        currentScanPath = ""
        scanErrors = []
        currentDiff = nil
        entries = []
        selection = []
        // Robust gegen Leerzeichen/Leereinträge: trimmen, leere verwerfen.
        let skipped = Set(
            skippedFolderNames
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
                .filter { !$0.isEmpty }
        )
        let engine = engine
        scanTask = Task.detached(priority: .userInitiated) { [weak self] in
            var buffer: [FileEntry] = []
            var pendingFailures: [ScanFailure] = []
            var latestPath = ""
            var latestCount = 0
            var lastPublishCount = 0
            var lastPublish = ContinuousClock.now

            func publishIfNeeded(force: Bool = false) async {
                guard force
                    || buffer.count - lastPublishCount >= Self.scanPublishBatchSize
                    || lastPublish.duration(to: .now) >= Self.scanPublishInterval
                else { return }

                let failures = pendingFailures
                pendingFailures.removeAll(keepingCapacity: true)
                lastPublishCount = buffer.count
                lastPublish = .now

                await MainActor.run { [weak self] in
                    guard let self, self.isScanning else { return }
                    self.currentScanPath = latestPath
                    self.scanProgressCount = latestCount
                    if !failures.isEmpty {
                        self.scanErrors.append(contentsOf: failures)
                    }
                }
            }

            let scopedRoots = roots.map { ($0, $0.startAccessingSecurityScopedResource()) }
            defer {
                for (url, scoped) in scopedRoots where scoped {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            for await event in engine.scan(roots: roots, skippedFolderNames: skipped) {
                if Task.isCancelled { break }
                switch event {
                case .found(let entry):
                    buffer.append(entry)
                    latestPath = entry.path.path(percentEncoded: false)
                    latestCount = buffer.count
                    await publishIfNeeded()
                case .progress(let path, let count):
                    latestPath = path
                    latestCount = count
                    await publishIfNeeded()
                case .failed(let path, let reason):
                    pendingFailures.append(ScanFailure(path: path, reason: reason))
                    await publishIfNeeded()
                case .finished(let total):
                    latestCount = total
                    await publishIfNeeded(force: true)
                }
            }

            guard !Task.isCancelled else { return }
            let detector = DuplicateDetector()
            let marked = await detector.markDuplicates(in: buffer)
            guard !Task.isCancelled else { return }

            await MainActor.run { [weak self] in
                guard let self else { return }
                self.entries = marked
                self.scanProgressCount = marked.count
                if !pendingFailures.isEmpty {
                    self.scanErrors.append(contentsOf: pendingFailures)
                }
                self.storeIndexedEntries(for: roots, entries: marked)
                self.isScanning = false
                self.scanTask = nil
            }
        }
    }

    func cancelScan() {
        scanTask?.cancel()
        scanTask = nil
        isScanning = false
    }

    private func restartFolderMonitor() {
        folderMonitor?.stop()
        folderMonitor = nil
        guard !scanRoots.isEmpty else { return }
        folderMonitor = FolderChangeMonitor(roots: scanRoots) { [weak self] in
            Task { @MainActor [weak self] in
                self?.scheduleAutoRescan()
            }
        }
        folderMonitor?.start()
    }

    private func scheduleAutoRescan() {
        guard !isScanning, !scanRoots.isEmpty else { return }
        if let suppressAutoRescanUntil, Date() < suppressAutoRescanUntil {
            return
        }
        pendingAutoRescanTask?.cancel()
        pendingAutoRescanTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard let self, !self.isScanning else { return }
                if let suppressAutoRescanUntil = self.suppressAutoRescanUntil,
                   Date() < suppressAutoRescanUntil {
                    return
                }
                self.lastAutoRescanMessage = "Folder changed — rescanning…"
                self.startScan()
            }
        }
    }

    private func suppressAutoRescanForPreview() {
        suppressAutoRescanUntil = Date().addingTimeInterval(5)
        pendingAutoRescanTask?.cancel()
        pendingAutoRescanTask = nil
    }

    private func storeIndexedEntries(for roots: [URL], entries: [FileEntry]) {
        for root in roots {
            let rootEntries = entries.filter { Self.isPath($0.path, inside: root) }
            if !rootEntries.isEmpty {
                indexedEntriesByRootPath[Self.normalizedPath(for: root)] = rootEntries
            }
        }
        persistCachedRootPathsForAutoScan()
    }

    // MARK: - Presets

    func applyPreset(_ preset: FilterPreset) {
        activePresetID = preset.id
    }

    func clearPreset() {
        activePresetID = nil
    }

    func savePreset(_ preset: FilterPreset) {
        if let idx = presets.firstIndex(where: { $0.id == preset.id }) {
            presets[idx] = preset
        } else {
            presets.append(preset)
        }
        persistPresets()
    }

    func deletePreset(_ preset: FilterPreset) {
        presets.removeAll { $0.id == preset.id }
        if activePresetID == preset.id { activePresetID = nil }
        persistPresets()
    }

    private var presetsURL: URL {
        SnapshotStore.appSupportDirectory.appendingPathComponent("presets.json")
    }

    private func loadPresets() {
        if let data = try? Data(contentsOf: presetsURL),
           let saved = try? JSONDecoder().decode([FilterPreset].self, from: data),
           !saved.isEmpty {
            presets = saved
        } else {
            presets = FilterPreset.bundled
            persistPresets()
        }
    }

    private func persistPresets() {
        guard let data = try? JSONEncoder().encode(presets) else { return }
        try? data.write(to: presetsURL, options: .atomic)
    }

    // MARK: - Snapshots

    func saveSnapshot() {
        let snapshot = Snapshot(
            date: Date(),
            rootPaths: scanRoots.map { $0.path(percentEncoded: false) },
            entries: entries
        )
        _ = try? snapshotStore.save(snapshot)
    }

    func availableSnapshots() -> [Snapshot] {
        snapshotStore.loadAll()
    }

    func deleteSnapshot(_ snapshot: Snapshot) {
        try? snapshotStore.delete(snapshot)
        if currentDiff != nil {
            currentDiff = nil
        }
    }

    func compare(with snapshot: Snapshot) {
        currentDiff = snapshotStore.diff(current: entries, baseline: snapshot)
    }

    func clearDiff() {
        currentDiff = nil
    }

    // MARK: - Export

    func export(format: ExportFormat) {
        let preservedState = makeIndexStateSnapshot()
        defer { restoreIndexState(from: preservedState) }

        do {
            if let diff = currentDiff {
                let data = try ExportManager.exportDiff(diff, format: format)
                presentSavePanel(data: data, format: format)
            } else {
                guard let options = presentExportSavePanel(format: format) else { return }
                restoreIndexState(from: preservedState)
                let exportEntries = options.visibleEntriesOnly ? displayedEntries : entries
                let data = try ExportManager.export(exportEntries, format: format, roots: scanRoots)
                writeExportData(data, to: options.url)
            }
        } catch {
            presentError(error.localizedDescription)
        }
    }

    private struct IndexStateSnapshot {
        let entries: [FileEntry]
        let displayedEntries: [FileEntry]
        let selectedScanRoot: URL?
        let selection: Set<FileEntry.ID>
        let currentDiff: SnapshotDiff?
    }

    private func makeIndexStateSnapshot() -> IndexStateSnapshot {
        IndexStateSnapshot(
            entries: entries,
            displayedEntries: displayedEntries,
            selectedScanRoot: selectedScanRoot,
            selection: selection,
            currentDiff: currentDiff
        )
    }

    private func restoreIndexState(from snapshot: IndexStateSnapshot) {
        isUpdatingSelectionEntries = true
        entries = snapshot.entries
        selectedScanRoot = snapshot.selectedScanRoot
        displayedEntries = snapshot.displayedEntries
        isUpdatingSelectionEntries = false
        selection = snapshot.selection
        currentDiff = snapshot.currentDiff
    }

    private func presentSavePanel(data: Data, format: ExportFormat) {
        let panel = configuredSavePanel(format: format)
        guard panel.runModal() == .OK, let url = panel.url else { return }
        writeExportData(data, to: url)
    }

    private func presentExportSavePanel(format: ExportFormat) -> (url: URL, visibleEntriesOnly: Bool)? {
        let panel = configuredSavePanel(format: format)
        let visibleOnlyCheckbox = NSButton(
            checkboxWithTitle: NSLocalizedString("Visible entries only", comment: "Export option to include only currently displayed entries."),
            target: nil,
            action: nil
        )
        visibleOnlyCheckbox.state = .on
        panel.accessoryView = visibleOnlyCheckbox
        guard panel.runModal() == .OK, let url = panel.url else { return nil }
        return (url, visibleOnlyCheckbox.state == .on)
    }

    private func configuredSavePanel(format: ExportFormat) -> NSSavePanel {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = ExportManager.suggestedFilename(format: format)
        if let type = UTType(filenameExtension: format.fileExtension) {
            panel.allowedContentTypes = [type]
        }
        return panel
    }

    private func writeExportData(_ data: Data, to url: URL) {
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            presentError(error.localizedDescription)
        }
    }

    private func presentError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Export failed", comment: "")
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.runModal()
    }

    // MARK: - Security-Scoped Bookmarks

    private static let bookmarksKey = "FileAtlas.bookmarks"

    private func storeBookmark(for url: URL) {
        guard let data = try? url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        ) else { return }
        var all = UserDefaults.standard.array(forKey: Self.bookmarksKey) as? [Data] ?? []
        all.append(data)
        UserDefaults.standard.set(all, forKey: Self.bookmarksKey)
    }

    private func removeBookmark(for url: URL) {
        let all = UserDefaults.standard.array(forKey: Self.bookmarksKey) as? [Data] ?? []
        let filtered = all.filter { data in
            var stale = false
            let resolved = try? URL(
                resolvingBookmarkData: data,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &stale
            )
            guard let resolved else { return true }
            return !sameFilePath(resolved, url)
        }
        UserDefaults.standard.set(filtered, forKey: Self.bookmarksKey)
    }

    private func restoreSavedLocations() {
        let all = UserDefaults.standard.array(forKey: Self.bookmarksKey) as? [Data] ?? []
        var refreshed: [Data] = []
        var changed = false

        for data in all {
            var stale = false
            guard let url = try? URL(
                resolvingBookmarkData: data,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &stale
            ) else {
                // Nicht mehr auflösbar → verwerfen.
                changed = true
                continue
            }

            if stale {
                // macOS hat das Bookmark als veraltet markiert: erneuern, solange
                // der Sicherheitsbereich noch gewährt ist.
                let scoped = url.startAccessingSecurityScopedResource()
                defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                if let fresh = try? url.bookmarkData(
                    options: .withSecurityScope,
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                ) {
                    refreshed.append(fresh)
                    changed = true
                } else {
                    refreshed.append(data)
                }
            } else {
                refreshed.append(data)
            }

            if !scanRoots.contains(where: { sameFilePath($0, url) }) {
                scanRoots.append(url)
            }
        }

        if changed {
            UserDefaults.standard.set(refreshed, forKey: Self.bookmarksKey)
        }
    }
}

// MARK: - Hilfstypen

/// Ein während des Scans übersprungener Pfad.
nonisolated struct ScanFailure: Identifiable, Sendable {
    let id = UUID()
    let path: String
    let reason: String
}

/// Parser für Größenausdrücke wie „> 10 MB" oder „< 500 KB".
nonisolated struct SizeQuery: Sendable {
    enum Op { case greater, less }
    let op: Op
    let bytes: Int64

    func matches(_ size: Int64) -> Bool {
        switch op {
        case .greater: return size > bytes
        case .less:    return size < bytes
        }
    }

    static func parse(_ text: String) -> SizeQuery? {
        let pattern = #"^\s*([<>])\s*([0-9]+(?:[.,][0-9]+)?)\s*(B|KB|MB|GB|TB)?\s*$"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: range) else { return nil }

        func group(_ i: Int) -> String? {
            guard let r = Range(match.range(at: i), in: text) else { return nil }
            return String(text[r])
        }

        guard let opStr = group(1),
              let numStr = group(2)?.replacingOccurrences(of: ",", with: "."),
              let value = Double(numStr) else { return nil }

        let unit = (group(3) ?? "B").uppercased()
        let multiplier: Double
        switch unit {
        case "KB": multiplier = 1024
        case "MB": multiplier = 1024 * 1024
        case "GB": multiplier = 1024 * 1024 * 1024
        case "TB": multiplier = 1024 * 1024 * 1024 * 1024
        default:   multiplier = 1
        }

        return SizeQuery(op: opStr == ">" ? .greater : .less, bytes: Int64(value * multiplier))
    }
}

private extension Array where Element == FileTag {
    func uniquedByTitle() -> [FileTag] {
        var seen = Set<String>()
        var result: [FileTag] = []
        for tag in self where !tag.title.isEmpty {
            let key = tag.title.lowercased()
            if seen.insert(key).inserted {
                result.append(tag)
            }
        }
        return result
    }
}

private final class FolderChangeMonitor {
    private let roots: [URL]
    private let onChange: @MainActor () -> Void
    private var stream: FSEventStreamRef?
    private let queue = DispatchQueue(label: "FileAtlas.FolderChangeMonitor")

    init(roots: [URL], onChange: @escaping @MainActor () -> Void) {
        self.roots = roots
        self.onChange = onChange
    }

    @MainActor
    deinit { stop() }

    func start() {
        stop()
        let paths = roots.map { $0.path(percentEncoded: false) } as CFArray
        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )
        let callback: FSEventStreamCallback = { _, info, _, _, _, _ in
            guard let info else { return }
            let monitor = Unmanaged<FolderChangeMonitor>.fromOpaque(info).takeUnretainedValue()
            Task { @MainActor in monitor.onChange() }
        }
        stream = FSEventStreamCreate(
            kCFAllocatorDefault,
            callback,
            &context,
            paths,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            1.0,
            FSEventStreamCreateFlags(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagWatchRoot)
        )
        guard let stream else { return }
        FSEventStreamSetDispatchQueue(stream, queue)
        FSEventStreamStart(stream)
    }

    func stop() {
        guard let stream else { return }
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
        self.stream = nil
    }
}
