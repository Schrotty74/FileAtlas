//
//  FileAtlasApp.swift
//  FileAtlas
//

import SwiftUI
import AppKit

@main
struct FileAtlasApp: App {
    @State private var vm = IndexViewModel()
    @State private var appearance = AppearanceManager()
    @State private var language = LanguageManager()
    @State private var motion = MotionPreferences()
    @State private var tooltips = TooltipPreferences()
    @State private var ui = UIState()
    @State private var backup = BackupManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(vm)
                .environment(appearance)
                .environment(language)
                .environment(motion)
                .environment(tooltips)
                .environment(ui)
                .environment(backup)
                .frame(minWidth: 980, minHeight: 620)
                .environment(\.locale, language.locale)
                .task {
                    vm.startAutoScanOnLaunchIfNeeded()
                    vm.scheduleUpdateCheckOnLaunch()
                    // Fällige geplante Backups beim Start (nur während die App läuft).
                    await backup.runScheduledIfDue(locations: vm.scanRoots)
                }
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
                    vm.persistCachedRootPathsForAutoScan()
                }
        }
        .windowToolbarStyle(.unified(showsTitle: false))
        .commands {
            FileAtlasCommands(vm: vm, ui: ui, appearance: appearance, language: language)
        }

        Settings {
            MainSettingsPanel()
                .environment(vm)
                .environment(appearance)
                .environment(language)
                .environment(motion)
                .environment(tooltips)
                .environment(ui)
                .environment(backup)
                .environment(\.locale, language.locale)
        }
    }
}

// MARK: - Menüstruktur

struct FileAtlasCommands: Commands {
    let vm: IndexViewModel
    let ui: UIState
    let appearance: AppearanceManager
    let language: LanguageManager

    var body: some Commands {
        // „Datei"-Menü
        CommandGroup(replacing: .newItem) {
            Button("Add Folder…") { vm.addFolders() }
                .keyboardShortcut("o", modifiers: .command)
            Button("Rescan") { vm.startScan() }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(vm.scanRoots.isEmpty)
            Button("Cancel Scan") { vm.cancelScan() }
                .disabled(!vm.isScanning)

            Divider()

            Button("Open Selected File") { vm.openSelectedEntry() }
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(vm.selectedEntry == nil)
            Button("Show in Finder") { vm.revealSelectedEntryInFinder() }
                .keyboardShortcut("r", modifiers: [.command, .shift])
                .disabled(vm.selectedEntry == nil)
            Button("Quick Look") { vm.quickLookSelectedEntry() }
                .disabled(vm.selectedEntry == nil)

            Divider()

            Button("Export as Excel…") { vm.export(format: .xlsx) }
                .keyboardShortcut("e", modifiers: .command)
            Button("Export as PDF…") { vm.export(format: .pdf) }
            Button("Export as CSV…") { vm.export(format: .csv) }

            Divider()

            Button("Save Snapshot") { vm.saveSnapshot() }
                .disabled(vm.entries.isEmpty)
            Button("Compare with Snapshot…") { ui.showSnapshotPicker = true }
                .disabled(vm.entries.isEmpty)
            Button("Compare Two Folders…") { ui.showFolderCompare = true }

            Divider()

            Button("Storage Analysis") { ui.showStorageAnalysis = true }
                .disabled(vm.entries.isEmpty)
            Button("Cleanup Queue") { ui.showCleanupQueue = true }
        }

        // „Darstellung"-Menü
        CommandMenu("Appearance") {
            Picker("Appearance", selection: Binding(
                get: { appearance.mode },
                set: { appearance.mode = $0 })) {
                Text("Light").tag(AppearanceMode.light)
                Text("Dark").tag(AppearanceMode.dark)
                Text("System").tag(AppearanceMode.system)
            }
            .pickerStyle(.inline)

            Picker("Color theme", selection: Binding(
                get: { appearance.colorTheme },
                set: { appearance.colorTheme = $0 })) {
                Text("Midnight Teal").tag(ColorTheme.midnightTeal)
                Text("Retro").tag(ColorTheme.retro)
                Text("Graphite Lime").tag(ColorTheme.graphiteLime)
                Text("Autumn").tag(ColorTheme.autumn)
                Text("Winter").tag(ColorTheme.winter)
                Text("Glass").tag(ColorTheme.glass)
            }
            .pickerStyle(.inline)

            Divider()

            Picker("Language", selection: Binding(
                get: { language.language },
                set: { language.language = $0 })) {
                Text("Deutsch").tag(AppLanguage.de)
                Text("English").tag(AppLanguage.en)
                Text("System").tag(AppLanguage.auto)
            }
            .pickerStyle(.inline)

            Divider()

            Button("Toggle Sidebar") {
                ui.isSidebarVisible.toggle()
            }
            .keyboardShortcut("s", modifiers: [.command, .control])
        }
    }
}
