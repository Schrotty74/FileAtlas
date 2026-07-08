//
//  SavedLocationsSection.swift
//  FileAtlas
//

import SwiftUI

struct SavedLocationsSection: View {
    @Environment(IndexViewModel.self) private var vm
    @Environment(BackupManager.self) private var backup
    @Environment(UIState.self) private var ui
    @State private var expandedPaths: Set<String> = []
    @State private var childrenByPath: [String: [URL]] = [:]
    @State private var loadingPaths: Set<String> = []
    @State private var hoveredPath: String?

    var body: some View {
        Section {
            ForEach(nodes) { node in
                LocationTreeRow(
                    url: node.url,
                    level: node.level,
                    isSavedRoot: node.isSavedRoot,
                    kind: .savedLocation,
                    accessRoot: node.accessRoot,
                    expandedPaths: $expandedPaths,
                    childrenByPath: $childrenByPath,
                    loadingPaths: $loadingPaths,
                    hoveredPath: $hoveredPath
                )
            }

            Button {
                vm.addFolders()
            } label: {
                Label("Add Folder…", systemImage: "plus")
            }
            .buttonStyle(.plain)
            .foregroundStyle(AppTheme.theme.accentColor)
        } header: {
            Text("Locations")
        }
    }

    private var nodes: [LocationTreeNode] {
        vm.scanRoots.flatMap { nodes(for: $0, level: 0, isSavedRoot: true, accessRoot: $0) }
    }

    private func nodes(for url: URL, level: Int, isSavedRoot: Bool, accessRoot: URL) -> [LocationTreeNode] {
        let key = pathKey(for: url)
        var nodes = [
            LocationTreeNode(
                id: key,
                url: url,
                level: level,
                isSavedRoot: isSavedRoot,
                accessRoot: accessRoot
            )
        ]

        guard expandedPaths.contains(key),
              let children = childrenByPath[key] else { return nodes }

        for child in children {
            nodes.append(contentsOf: self.nodes(for: child, level: level + 1, isSavedRoot: false, accessRoot: accessRoot))
        }

        return nodes
    }

    private func pathKey(for url: URL) -> String {
        url.path(percentEncoded: false)
    }
}

struct LocationTreeNode: Identifiable {
    let id: String
    let url: URL
    let level: Int
    let isSavedRoot: Bool
    let accessRoot: URL
}

enum LocationTreeRowKind {
    case savedLocation
    case quickAccess
}

struct LocationTreeRow: View {
    @Environment(IndexViewModel.self) private var vm
    @Environment(BackupManager.self) private var backup
    @Environment(UIState.self) private var ui

    let url: URL
    let level: Int
    let isSavedRoot: Bool
    let kind: LocationTreeRowKind
    let accessRoot: URL
    @Binding var expandedPaths: Set<String>
    @Binding var childrenByPath: [String: [URL]]
    @Binding var loadingPaths: Set<String>
    @Binding var hoveredPath: String?

    private var pathKey: String {
        url.path(percentEncoded: false)
    }

    private var isExpanded: Bool {
        expandedPaths.contains(pathKey)
    }

    private var children: [URL]? {
        childrenByPath[pathKey]
    }

    private var isLoadingChildren: Bool {
        loadingPaths.contains(pathKey)
    }

    var body: some View {
        row
    }

    private var row: some View {
        HStack(spacing: 6) {
            disclosureControl

            HStack(spacing: 8) {
                Image(systemName: rowIconName)
                    .foregroundStyle(AppTheme.theme.accentColor)
                VStack(alignment: .leading, spacing: 1) {
                    Text(url.lastPathComponent)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    if kind == .quickAccess && isSavedRoot {
                        Text(url.deletingLastPathComponent().path(percentEncoded: false))
                            .font(.caption2)
                            .foregroundStyle(AppTheme.theme.textSecondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    } else if let stats = vm.stats(for: url) {
                        Text("\(stats.count) Dateien · \(ByteCountFormatter.string(fromByteCount: stats.size, countStyle: .file))")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.theme.textSecondary)
                    }
                    if isSavedRoot && kind == .savedLocation, let last = backup.lastBackup(for: url) {
                        Text("Backup: \(last.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.theme.textSecondary)
                    }
                }
                Spacer(minLength: 0)
                if isSavedRoot && kind == .savedLocation && backup.config(for: url).schedule != .off {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.theme.textSecondary)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                vm.selectOrScanRoot(url)
            }
            .disabled(vm.isScanning)

            if hoveredPath == pathKey {
                hoverAction
            }
        }
        .padding(.leading, CGFloat(level) * 16)
        .onHover { inside in hoveredPath = inside ? pathKey : nil }
        .contextMenu { contextMenu }
    }

    private var rowIconName: String {
        kind == .quickAccess && isSavedRoot ? "clock.fill" : "folder.fill"
    }

    private var disclosureIcon: String {
        if let children, children.isEmpty {
            return "chevron.right"
        }
        return isExpanded ? "chevron.down" : "chevron.right"
    }

    @ViewBuilder
    private var disclosureControl: some View {
        if isLoadingChildren {
            ProgressView()
                .controlSize(.mini)
                .frame(width: 18, height: 22)
        } else {
            Image(systemName: disclosureIcon)
                .font(.caption2)
                .frame(width: 18, height: 22)
                .contentShape(Rectangle())
                .highPriorityGesture(TapGesture().onEnded {
                    toggleExpanded()
                })
                .foregroundStyle(AppTheme.theme.textSecondary)
        }
    }

    @ViewBuilder
    private var hoverAction: some View {
        if isSavedRoot && kind == .savedLocation {
            Button(role: .destructive) {
                vm.removeRoot(url)
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .foregroundStyle(AppTheme.theme.textSecondary)
            .help("Remove Location")
        } else if isSavedRoot && kind == .quickAccess {
            Button {
                vm.removeRecentScanRoot(url)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .foregroundStyle(AppTheme.theme.textSecondary)
            .help("Remove from Quick Access")
        }
    }

    @ViewBuilder
    private var contextMenu: some View {
        switch kind {
        case .savedLocation:
            if vm.isRecentScanRoot(url) {
                Button {
                } label: {
                    Label("Already in Quick Access", systemImage: "bookmark.fill")
                }
                .disabled(true)
            } else {
                Button {
                    vm.addRecentScanRoot(url)
                } label: {
                    Label("Add to Quick Access", systemImage: "bookmark")
                }
            }
            if isSavedRoot {
                Button {
                    ui.backupLocation = url
                    ui.showBackupSettings = true
                } label: {
                    Label("Backup Settings…", systemImage: "arrow.down.doc")
                }
                Divider()
                Button(role: .destructive) {
                    vm.removeRoot(url)
                } label: {
                    Label("Remove Location", systemImage: "minus.circle")
                }
            }
        case .quickAccess:
            if isSavedRoot {
                Button(role: .destructive) {
                    vm.removeRecentScanRoot(url)
                } label: {
                    Label("Remove from Quick Access", systemImage: "xmark.circle")
                }
            } else if vm.isRecentScanRoot(url) {
                Button {
                } label: {
                    Label("Already in Quick Access", systemImage: "bookmark.fill")
                }
                .disabled(true)
            } else {
                Button {
                    vm.addRecentScanRoot(url)
                } label: {
                    Label("Add to Quick Access", systemImage: "bookmark")
                }
            }
        }
    }

    private func toggleExpanded() {
        if isExpanded {
            expandedPaths.remove(pathKey)
        } else {
            expandedPaths.insert(pathKey)
            loadChildrenIfNeeded()
        }
    }

    private func loadChildrenIfNeeded() {
        guard childrenByPath[pathKey] == nil,
              !loadingPaths.contains(pathKey) else { return }
        loadingPaths.insert(pathKey)

        let url = url
        let accessRoot = accessRoot
        let pathKey = pathKey
        let skippedFolderNames = vm.skippedFolderNames.map { $0.lowercased() }
        let keys: [URLResourceKey] = [.isDirectoryKey, .isHiddenKey, .nameKey]

        Task.detached(priority: .userInitiated) {
            let scoped = accessRoot.startAccessingSecurityScopedResource()
            defer { if scoped { accessRoot.stopAccessingSecurityScopedResource() } }

            let urls = (try? FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: keys,
                options: [.skipsHiddenFiles]
            )) ?? []

            let children = urls
                .filter { child in
                    guard let values = try? child.resourceValues(forKeys: Set(keys)),
                          values.isDirectory == true,
                          values.isHidden != true else { return false }
                    let name = values.name ?? child.lastPathComponent
                    let lowerName = name.lowercased()
                    return !skippedFolderNames.contains { lowerName.hasPrefix($0) }
                }
                .sorted {
                    $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending
                }

            await MainActor.run {
                childrenByPath[pathKey] = children
                loadingPaths.remove(pathKey)
            }
        }
    }
}
