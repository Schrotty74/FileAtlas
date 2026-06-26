//
//  SavedLocationsSection.swift
//  FileAtlas
//

import SwiftUI

struct SavedLocationsSection: View {
    @Environment(IndexViewModel.self) private var vm
    @Environment(BackupManager.self) private var backup
    @Environment(UIState.self) private var ui
    @State private var hoveredRoot: URL?

    var body: some View {
        Section {
            ForEach(vm.scanRoots, id: \.self) { url in
                HStack(spacing: 6) {
                    Button {
                        // Klick auf einen Ort lädt gezielt dessen Inhalt.
                        vm.startScan(roots: [url])
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "folder.fill")
                                .foregroundStyle(AppTheme.theme.accentColor)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(url.lastPathComponent)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                if let stats = vm.stats(for: url) {
                                    Text("\(stats.count) Dateien · \(ByteCountFormatter.string(fromByteCount: stats.size, countStyle: .file))")
                                        .font(.caption2)
                                        .foregroundStyle(AppTheme.theme.textSecondary)
                                }
                                if let last = backup.lastBackup(for: url) {
                                    Text("Backup: \(last.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.caption2)
                                        .foregroundStyle(AppTheme.theme.textSecondary)
                                }
                            }
                            Spacer(minLength: 0)
                            if backup.config(for: url).schedule != .off {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.caption2)
                                    .foregroundStyle(AppTheme.theme.textSecondary)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(vm.isScanning)

                    if hoveredRoot == url {
                        Button(role: .destructive) {
                            vm.removeRoot(url)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(AppTheme.theme.textSecondary)
                        .help("Remove Location")
                    }
                }
                .onHover { inside in hoveredRoot = inside ? url : nil }
                .contextMenu {
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
}
