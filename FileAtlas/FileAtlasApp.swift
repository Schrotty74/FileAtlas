//
//  FileAtlasApp.swift
//  FileAtlas
//

import SwiftUI
import AppKit

@main
struct FileAtlasApp: App {
    @NSApplicationDelegateAdaptor(FileAtlasApplicationDelegate.self) private var appDelegate
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
        .defaultSize(width: 1180, height: 760)
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

private final class FileAtlasApplicationDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

// MARK: - Menüstruktur

struct FileAtlasCommands: Commands {
    let vm: IndexViewModel
    let ui: UIState
    let appearance: AppearanceManager
    let language: LanguageManager

    private func menuText(_ german: String, _ english: String) -> String {
        language.effectiveLanguage == .de ? german : english
    }

    var body: some Commands {
        // „Datei"-Menü
        CommandGroup(replacing: .newItem) {
            Button(menuText("Ordner hinzufügen…", "Add Folder…")) { vm.addFolders() }
                .keyboardShortcut("o", modifiers: .command)
            Button(menuText("Erneut scannen", "Rescan")) { vm.startScan() }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(vm.scanRoots.isEmpty)
            Button(menuText("Scan abbrechen", "Cancel Scan")) { vm.cancelScan() }
                .disabled(!vm.isScanning)

            Divider()

            Button(menuText("Ausgewählte Datei öffnen", "Open Selected File")) { vm.openSelectedEntry() }
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(vm.selectedEntry == nil)
            Button(menuText("Im Finder zeigen", "Show in Finder")) { vm.revealSelectedEntryInFinder() }
                .keyboardShortcut("r", modifiers: [.command, .shift])
                .disabled(vm.selectedEntry == nil)
            Button(menuText("Schnellansicht", "Quick Look")) { vm.quickLookSelectedEntry() }
                .disabled(vm.selectedEntry == nil)

            Divider()

            Button(menuText("Als Excel exportieren…", "Export as Excel…")) { vm.export(format: .xlsx) }
                .keyboardShortcut("e", modifiers: .command)
            Button(menuText("Als PDF exportieren…", "Export as PDF…")) { vm.export(format: .pdf) }
            Button(menuText("Als CSV exportieren…", "Export as CSV…")) { vm.export(format: .csv) }

            Divider()

            Button(menuText("Snapshot sichern", "Save Snapshot")) { vm.saveSnapshot() }
                .disabled(vm.entries.isEmpty)
            Button(menuText("Mit Snapshot vergleichen…", "Compare with Snapshot…")) { ui.showSnapshotPicker = true }
                .disabled(vm.entries.isEmpty)
            Button(menuText("Zwei Ordner vergleichen…", "Compare Two Folders…")) { ui.showFolderCompare = true }

            Divider()

            Button(menuText("Speicheranalyse", "Storage Analysis")) { ui.showStorageAnalysis = true }
                .disabled(vm.entries.isEmpty)
            Button(menuText("Aufräumwarteschlange", "Cleanup Queue")) { ui.showCleanupQueue = true }
        }

        // „Darstellung"-Menü
        CommandMenu(menuText("Darstellung", "Appearance")) {
            Picker(menuText("Darstellung", "Appearance"), selection: Binding(
                get: { appearance.mode },
                set: { appearance.mode = $0 })) {
                Text(menuText("Hell", "Light")).tag(AppearanceMode.light)
                Text(menuText("Dunkel", "Dark")).tag(AppearanceMode.dark)
                Text(menuText("System", "System")).tag(AppearanceMode.system)
            }
            .pickerStyle(.inline)

            Picker(menuText("Farbthema", "Color theme"), selection: Binding(
                get: { appearance.colorTheme },
                set: { appearance.colorTheme = $0 })) {
                Text("Midnight Teal").tag(ColorTheme.midnightTeal)
                Text("Retro").tag(ColorTheme.retro)
                Text("Graphite Lime").tag(ColorTheme.graphiteLime)
                Text(menuText("Herbst", "Autumn")).tag(ColorTheme.autumn)
                Text(menuText("Winter", "Winter")).tag(ColorTheme.winter)
                Text(menuText("Glas", "Glass")).tag(ColorTheme.glass)
            }
            .pickerStyle(.inline)

            Divider()

            Picker(menuText("Sprache", "Language"), selection: Binding(
                get: { language.language },
                set: { language.language = $0 })) {
                Text("Deutsch").tag(AppLanguage.de)
                Text("English").tag(AppLanguage.en)
                Text(menuText("System", "System")).tag(AppLanguage.auto)
            }
            .pickerStyle(.inline)

            Divider()

            Button(menuText("Seitenleiste ein-/ausblenden", "Toggle Sidebar")) {
                ui.isSidebarVisible.toggle()
            }
            .keyboardShortcut("s", modifiers: [.command, .control])
        }
    }
}
