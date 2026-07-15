//
//  SelectionBackupView.swift
//  FileAtlas
//

import SwiftUI
import AppKit

struct SelectionBackupView: View {
    let entries: [FileEntry]

    @Environment(BackupManager.self) private var backup
    @Environment(IndexViewModel.self) private var vm
    @Environment(\.dismiss) private var dismiss
    @State private var destination: URL?
    @State private var compressionEnabled = true
    @State private var hashManifestEnabled = false

    private var sourceSize: Int64 { entries.reduce(0) { $0 + $1.size } }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Back Up Selection")
                        .font(.headline)
                    Text("\(entries.count) item(s) · \(ByteCountFormatter.string(fromByteCount: sourceSize, countStyle: .file))")
                        .font(.caption)
                        .foregroundStyle(AppTheme.theme.textSecondary)
                }
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Back Up") { startBackup() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(destination == nil || backup.isBackingUp)
            }
            .padding()

            Divider()

            Form {
                Section("Selected Items") {
                    ForEach(entries) { entry in
                        HStack(spacing: 8) {
                            SystemFileIconView(entry: entry, size: 16, iconDisplayMode: vm.iconDisplayMode)
                            Text(entry.name).lineLimit(1)
                            Spacer()
                            Text(entry.formattedSize)
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(AppTheme.theme.textSecondary)
                        }
                    }
                }

                Section("Archive Options") {
                    Toggle("Compress files", isOn: $compressionEnabled)
                        .tint(AppTheme.theme.accentColor)
                    Toggle("Create SHA-256 hash manifest", isOn: $hashManifestEnabled)
                        .tint(AppTheme.theme.accentColor)
                }

                Section("Destination") {
                    HStack {
                        Image(systemName: destination == nil ? "folder.badge.questionmark" : "folder.fill")
                            .foregroundStyle(destination == nil ? AppTheme.theme.textSecondary : AppTheme.theme.accentColor)
                        Text(destination?.path(percentEncoded: false) ?? "No destination chosen")
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .foregroundStyle(destination == nil ? AppTheme.theme.textSecondary : AppTheme.theme.textPrimary)
                        Spacer()
                        Button("Choose…", action: chooseDestination)
                    }
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 500, height: 480)
    }

    private func chooseDestination() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = NSLocalizedString("Choose", comment: "")
        guard panel.runModal() == .OK else { return }
        destination = panel.url
    }

    private func startBackup() {
        guard let destination else { return }
        let sources = entries.map(\.path)
        let accessRoots = entries.map { vm.securityScopedAccessRoot(for: $0.path) }
        Task {
            await backup.runSelectionBackup(
                sources: sources,
                accessRoots: accessRoots,
                destination: destination,
                compressionEnabled: compressionEnabled,
                hashManifestEnabled: hashManifestEnabled
            )
        }
        dismiss()
    }
}
