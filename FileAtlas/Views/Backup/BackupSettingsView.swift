//
//  BackupSettingsView.swift
//  FileAtlas
//
//  Sheet mit den Backup-Einstellungen eines Ortes.
//

import SwiftUI

struct BackupSettingsView: View {
    let location: URL

    @Environment(BackupManager.self) private var backup
    @Environment(\.dismiss) private var dismiss

    @State private var kind: BackupKind = .indexOnly
    @State private var schedule: BackupSchedule = .off
    @State private var passwordEnabled = false
    @State private var compressionEnabled = true
    @State private var hashManifestEnabled = false
    @State private var password = ""
    @State private var hasDestination = false
    @State private var destinationName: String?
    @State private var sourceName = ""
    @State private var estimatedSize: Int64?

    private var includesFull: Bool { kind != .indexOnly }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Backup Settings").font(.headline)
                    Text(location.lastPathComponent)
                        .font(.caption).foregroundStyle(AppTheme.theme.textSecondary)
                }
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Save") { save(); dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding()

            Divider()

            Form {
                Section("Backup type") {
                    Picker("Type", selection: $kind) {
                        Text("Index only").tag(BackupKind.indexOnly)
                        Text("Full backup (ZIP)").tag(BackupKind.fullOnly)
                        Text("Both").tag(BackupKind.both)
                    }
                    .pickerStyle(.radioGroup)
                }

                Section("Source") {
                    HStack {
                        Image(systemName: "folder.fill")
                            .foregroundStyle(AppTheme.theme.accentColor)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(sourceName)
                            Text("Full backup backs up the selected folder recursively. You can choose a single file instead.")
                                .font(.caption)
                                .foregroundStyle(AppTheme.theme.textSecondary)
                        }
                        Spacer()
                        Button("Choose…") {
                            backup.chooseSource(for: location)
                            refreshSource()
                            refreshEstimate()
                        }
                    }
                }

                if includesFull {
                    Section("Archive options") {
                        Toggle("Compress files", isOn: $compressionEnabled)
                            .tint(AppTheme.theme.accentColor)
                        Toggle("Create SHA-256 hash manifest", isOn: $hashManifestEnabled)
                            .tint(AppTheme.theme.accentColor)
                        Text("Large already-compressed files are streamed for speed and cancellation responsiveness.")
                            .font(.caption)
                            .foregroundStyle(AppTheme.theme.textSecondary)
                    }

                    Section("Password protection (AES-256)") {
                        Toggle("Encrypt backup with password", isOn: $passwordEnabled)
                            .tint(AppTheme.theme.accentColor)
                        if passwordEnabled {
                            SecureField("Password", text: $password)
                            Text("Stored in the macOS Keychain. AES-256 ZIPs open with Keka / 7-Zip / WinZip (not Finder or The Unarchiver).")
                                .font(.caption)
                                .foregroundStyle(AppTheme.theme.textSecondary)
                        }
                    }
                }

                Section("Destination") {
                    HStack {
                        Image(systemName: hasDestination ? "folder.fill" : "folder.badge.questionmark")
                            .foregroundStyle(hasDestination ? AppTheme.theme.accentColor : AppTheme.theme.textSecondary)
                        Text(destinationName ?? NSLocalizedString("No destination chosen", comment: ""))
                            .foregroundStyle(hasDestination ? AppTheme.theme.textPrimary : AppTheme.theme.textSecondary)
                        Spacer()
                        Button("Choose…") {
                            backup.chooseDestination(for: location)
                            refreshDestination()
                        }
                    }
                }

                Section("Schedule") {
                    Picker("Schedule", selection: $schedule) {
                        Text("Off").tag(BackupSchedule.off)
                        Text("Daily").tag(BackupSchedule.daily)
                        Text("Weekly").tag(BackupSchedule.weekly)
                    }
                    Text("Scheduled backups run on app launch when due (only while FileAtlas is running).")
                        .font(.caption)
                        .foregroundStyle(AppTheme.theme.textSecondary)
                }

                Section {
                    HStack {
                        Text("Estimated size")
                        Spacer()
                        if let estimatedSize {
                            Text(ByteCountFormatter.string(fromByteCount: estimatedSize, countStyle: .file))
                                .foregroundStyle(AppTheme.theme.textSecondary)
                        } else {
                            ProgressView().controlSize(.small)
                        }
                    }
                    if let last = backup.lastBackup(for: location) {
                        HStack {
                            Text("Last backup")
                            Spacer()
                            Text(last.formatted(date: .abbreviated, time: .shortened))
                                .foregroundStyle(AppTheme.theme.textSecondary)
                        }
                    }
                }

                Section {
                    Button {
                        save()
                        let loc = location
                        Task { await backup.runBackup(for: loc) }
                        dismiss()
                    } label: {
                        Label("Back up now", systemImage: "arrow.down.doc")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.theme.accentColor)
                    .disabled(!hasDestination || backup.isBackingUp
                              || (includesFull && passwordEnabled && password.isEmpty && !backup.hasPassword(for: location)))
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 460, height: 600)
        .onAppear(perform: load)
        .task {
            refreshEstimate()
        }
    }

    // MARK: - Laden / Speichern

    private func load() {
        let config = backup.config(for: location)
        kind = config.kind
        schedule = config.schedule
        passwordEnabled = config.passwordEnabled
        compressionEnabled = config.compressionEnabled
        hashManifestEnabled = config.hashManifestEnabled
        refreshSource()
        refreshDestination()
    }

    private func refreshSource() {
        sourceName = backup.sourceDisplayName(for: location)
    }

    private func refreshDestination() {
        destinationName = backup.destinationDisplayName(for: location)
        hasDestination = destinationName != nil
    }

    private func refreshEstimate() {
        estimatedSize = nil
        let loc = location
        Task {
            estimatedSize = await Task.detached { BackupEngine.estimatedSize(of: loc) }.value
        }
    }

    private func save() {
        var config = backup.config(for: location)
        config.kind = kind
        config.schedule = schedule
        config.passwordEnabled = passwordEnabled
        config.compressionEnabled = compressionEnabled
        config.hashManifestEnabled = hashManifestEnabled
        backup.saveConfig(config)

        if includesFull && passwordEnabled {
            if !password.isEmpty {
                backup.setPassword(password, for: location)
            }
        } else {
            backup.clearPassword(for: location)
        }
    }
}
