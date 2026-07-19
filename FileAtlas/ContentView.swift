//
//  ContentView.swift
//  FileAtlas
//
//  Drei-Spalten-Wurzel: Sidebar | Dateiliste | Detailpanel.
//

import AppKit
import SwiftUI

/// Gemeinsamer UI-Zustand (Sheets, Spaltensichtbarkeit, Preset-Editor).
@Observable
@MainActor
final class UIState {
    private static let fileListViewModeKey = "FileAtlas.fileListViewMode"

    var showFilterPanel = false
    var showSnapshotPicker = false
    var showDiff = false
    var showFolderCompare = false
    var showStorageAnalysis = false
    var showCleanupQueue = false
    var showAlertRuleResults = false
    var showSettingsPanel = false
    var isPresentingPresetEditor = false
    var editingPreset: FilterPreset? = nil
    var isPresentingSmartCollectionEditor = false
    var editingSmartCollection: SmartCollection? = nil
    var isSidebarVisible = true
    var fileListViewMode: FileListViewMode {
        didSet { UserDefaults.standard.set(fileListViewMode.rawValue, forKey: Self.fileListViewModeKey) }
    }

    // Backup
    var backupLocation: URL? = nil
    var showBackupSettings = false
    var selectionBackupEntries: [FileEntry] = []
    var showSelectionBackup = false

    init() {
        let rawMode = UserDefaults.standard.string(forKey: Self.fileListViewModeKey)
        self.fileListViewMode = rawMode.flatMap(FileListViewMode.init(rawValue:)) ?? .table
    }
}

struct ContentView: View {
    @Environment(IndexViewModel.self) private var vm
    @Environment(UIState.self) private var ui

    var body: some View {
        @Bindable var vm = vm
        @Bindable var ui = ui

        Group {
            if vm.hasUserContent {
                HSplitView {
                    if ui.isSidebarVisible {
                        SidebarView()
                            .frame(minWidth: 220, idealWidth: 244, maxWidth: 300)
                    }

                    FileListView()
                        .frame(minWidth: 480, idealWidth: 660)

                    DetailPanelView()
                        .frame(minWidth: 280, idealWidth: 320, maxWidth: 440)
                }
            } else {
                FirstLaunchHelpView()
            }
        }
        .toolbar {
            MainToolbar(vm: vm, ui: ui, searchText: $vm.searchText, searchAllFolders: $vm.searchAllFolders)
        }
        .sheet(isPresented: $ui.showFilterPanel) {
            FilterPanel()
        }
        .sheet(isPresented: $ui.isPresentingPresetEditor) {
            PresetEditorView(original: ui.editingPreset)
        }
        .sheet(isPresented: $ui.isPresentingSmartCollectionEditor) {
            SmartCollectionEditorView(original: ui.editingSmartCollection)
        }
        .sheet(isPresented: $ui.showSnapshotPicker) {
            SnapshotPickerView()
        }
        .sheet(isPresented: $ui.showDiff) {
            SnapshotDiffView()
        }
        .sheet(isPresented: $ui.showFolderCompare) {
            FolderCompareView()
        }
        .sheet(isPresented: $ui.showStorageAnalysis) {
            StorageAnalysisView()
        }
        .sheet(isPresented: $ui.showCleanupQueue) {
            CleanupQueueView()
        }
        .sheet(isPresented: $ui.showAlertRuleResults) {
            AlertRuleResultsView()
        }
        .sheet(isPresented: $ui.showSettingsPanel) {
            MainSettingsPanel()
        }
        .sheet(isPresented: $ui.showBackupSettings) {
            if let location = ui.backupLocation {
                BackupSettingsView(location: location)
            }
        }
        .sheet(isPresented: $ui.showSelectionBackup) {
            SelectionBackupView(entries: ui.selectionBackupEntries)
        }
        .overlay(alignment: .bottom) {
            VStack(spacing: 8) {
                AutoRescanBanner()
                ScanChangeSummaryBanner { ui.showDiff = true }
                AlertRuleBanner { ui.showAlertRuleResults = true }
                BackupProgressBanner()
            }
        }
    }
}

private struct FirstLaunchHelpView: View {
    @Environment(IndexViewModel.self) private var vm
    @Environment(LanguageManager.self) private var language

    private var content: FirstLaunchHelpContent {
        FirstLaunchHelpContent(language: language.effectiveLanguage)
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder.badge.gearshape")
                .font(.system(size: 58, weight: .medium))
                .foregroundStyle(AppTheme.theme.accentColor)

            Text(content.title)
                .font(.largeTitle.bold())

            Text(content.introduction)
                .font(.title3)
                .foregroundStyle(AppTheme.theme.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 580)

            HStack(spacing: 12) {
                Button {
                    vm.addFolders()
                } label: {
                    Label(content.addFolderTitle, systemImage: "folder.badge.plus")
                }
                .buttonStyle(.borderedProminent)

                Button {
                    FirstLaunchHelpAction.openManual(for: language.effectiveLanguage)
                } label: {
                    Label(content.manualButtonTitle, systemImage: "book")
                }
                .buttonStyle(.bordered)
            }

            VStack(spacing: 10) {
                Text(content.aiHeading)
                    .font(.headline)

                HStack(spacing: 12) {
                    ForEach(FirstLaunchAIService.allCases) { service in
                        Button {
                            FirstLaunchHelpAction.copyPromptAndOpen(
                                service,
                                language: language.effectiveLanguage
                            )
                        } label: {
                            HStack(spacing: 7) {
                                AIServiceLogo(service: service)
                                Text(service.title)
                            }
                        }
                        .buttonStyle(.bordered)
                        .help(content.serviceHelp(service))
                    }
                }
            }

            Text(content.privacyNote)
                .font(.callout)
                .foregroundStyle(AppTheme.theme.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 620)
        }
        .padding(36)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct AIServiceLogo: View {
    let service: FirstLaunchAIService

    var body: some View {
        Image(nsImage: image)
            .resizable()
            .scaledToFit()
            .frame(width: 18, height: 18)
            .accessibilityHidden(true)
    }

    private var image: NSImage {
        guard let url = Bundle.main.url(
            forResource: service.logoResource.name,
            withExtension: service.logoResource.fileExtension
        ) else {
            return NSImage()
        }
        return NSImage(contentsOf: url) ?? NSImage()
    }
}

private struct AlertRuleBanner: View {
    @Environment(IndexViewModel.self) private var vm
    let showDetails: () -> Void

    var body: some View {
        if vm.alertRuleMatchCount > 0 {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(AppTheme.gold)
                Text("Rules found \(vm.alertRuleMatchCount) matching item(s)")
                    .font(.callout)
                Button("Show") { showDetails() }
                    .controlSize(.small)
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(.regularMaterial, in: Capsule())
            .overlay(Capsule().stroke(AppTheme.stroke, lineWidth: 0.5))
            .padding(.bottom, 12)
        }
    }
}

private struct ScanChangeSummaryBanner: View {
    @Environment(IndexViewModel.self) private var vm
    let showDetails: () -> Void

    var body: some View {
        if let summary = vm.latestScanSummary {
            HStack(spacing: 8) {
                Image(systemName: summary.diff.isEmpty ? "checkmark.circle.fill" : "arrow.triangle.2.circlepath.circle.fill")
                    .foregroundStyle(summary.diff.isEmpty ? AppTheme.theme.accentColor : AppTheme.gold)
                Text(summary.diff.isEmpty
                    ? "No changes since the last scan"
                    : "Since last scan: \(summary.addedCount) new, \(summary.changedCount) changed, \(summary.removedCount) removed")
                    .font(.callout)
                if !summary.diff.isEmpty {
                    Button("Details") {
                        vm.showLatestScanChanges()
                        showDetails()
                    }
                    .controlSize(.small)
                }
                Button {
                    vm.dismissLatestScanSummary()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppTheme.theme.textSecondary)
                .help("Dismiss")
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(.regularMaterial, in: Capsule())
            .overlay(Capsule().stroke(AppTheme.stroke, lineWidth: 0.5))
            .padding(.bottom, 12)
        }
    }
}

private struct AutoRescanBanner: View {
    @Environment(IndexViewModel.self) private var vm

    var body: some View {
        if let message = vm.lastAutoRescanMessage {
            HStack(spacing: 8) {
                Image(systemName: "arrow.clockwise.circle.fill")
                    .foregroundStyle(AppTheme.theme.accentColor)
                Text(message).font(.callout)
                Button {
                    vm.clearAutoRescanMessage()
                } label: { Image(systemName: "xmark.circle.fill") }
                    .buttonStyle(.plain)
                    .foregroundStyle(AppTheme.theme.textSecondary)
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(.regularMaterial, in: Capsule())
            .overlay(Capsule().stroke(AppTheme.stroke, lineWidth: 0.5))
            .padding(.bottom, 12)
        }
    }
}

/// Schmales Statusband am unteren Rand, während ein Backup läuft / nach Abschluss.
private struct BackupProgressBanner: View {
    @Environment(BackupManager.self) private var backup

    var body: some View {
        if backup.isBackingUp {
            HStack(spacing: 10) {
                ProgressView(value: backup.progressFraction)
                    .frame(width: 140)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Backing up \(backup.activeSourceName)…")
                        .font(.callout.weight(.medium))
                    if !backup.currentItemName.isEmpty {
                        Text(backup.currentItemName)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    } else {
                        Text(backup.progressLabel)
                    }
                }
                .font(.caption)
                .foregroundStyle(AppTheme.theme.textSecondary)
                Text(backup.progressLabel)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(AppTheme.theme.textSecondary)
                Button("Cancel") {
                    backup.cancelBackup()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(.regularMaterial, in: Capsule())
            .overlay(Capsule().stroke(AppTheme.stroke, lineWidth: 0.5))
            .padding(.bottom, 12)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        } else if let message = backup.statusMessage {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(AppTheme.theme.accentColor)
                Text(message).font(.callout)
                Button {
                    backup.statusMessage = nil
                } label: { Image(systemName: "xmark.circle.fill") }
                    .buttonStyle(.plain)
                    .foregroundStyle(AppTheme.theme.textSecondary)
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(.regularMaterial, in: Capsule())
            .overlay(Capsule().stroke(AppTheme.stroke, lineWidth: 0.5))
            .padding(.bottom, 12)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

#Preview {
    ContentView()
        .environment(IndexViewModel())
        .environment(AppearanceManager())
        .environment(LanguageManager())
        .environment(UIState())
        .environment(BackupManager())
        .frame(width: 1100, height: 720)
        .preferredColorScheme(.dark)
}
