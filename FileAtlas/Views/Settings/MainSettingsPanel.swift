//
//  MainSettingsPanel.swift
//  FileAtlas
//

import SwiftUI

struct MainSettingsPanel: View {
    @Environment(IndexViewModel.self) private var vm
    @Environment(AppearanceManager.self) private var appearance
    @Environment(LanguageManager.self) private var language
    @Environment(BackupManager.self) private var backup
    @Environment(\.dismiss) private var dismiss

    @State private var selectedSection: SettingsSection? = .appearance
    @State private var newIgnoredFolder = ""
    @State private var filterByDate = false
    @State private var backupSettingsLocation: URL?
    @State private var showBackupSettings = false
    @State private var editingPreset: FilterPreset?
    @State private var showPresetEditor = false
    @State private var showClearCacheConfirmation = false
    @State private var cacheClearMessage: String?

    var body: some View {
        HStack(spacing: 0) {
            List {
                ForEach(SettingsSection.allCases) { section in
                    Button {
                        selectedSection = section
                    } label: {
                        Label(section.title, systemImage: section.systemImage)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(selectedSection == section ? AppTheme.theme.accentColor : AppTheme.theme.textPrimary)
                    .listRowBackground(
                        selectedSection == section
                        ? AppTheme.theme.accentColor.opacity(0.14)
                        : Color.clear
                    )
                }
            }
            .listStyle(.sidebar)
            .frame(width: 210)

            Divider()

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text((selectedSection ?? .appearance).title)
                        .font(.headline)
                    Spacer()
                    Button("Done") { dismiss() }
                        .keyboardShortcut(.defaultAction)
                }
                .padding()

                Divider()

                sectionContent(selectedSection ?? .appearance)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 720, idealWidth: 760, minHeight: 500, idealHeight: 540)
        .sheet(isPresented: $showBackupSettings) {
            if let backupSettingsLocation {
                BackupSettingsView(location: backupSettingsLocation)
            }
        }
        .sheet(isPresented: $showPresetEditor) {
            PresetEditorView(original: editingPreset)
        }
        .onAppear { filterByDate = vm.dateFrom != nil || vm.dateTo != nil }
    }

    @ViewBuilder
    private func sectionContent(_ section: SettingsSection) -> some View {
        switch section {
        case .appearance:
            appearanceSection
        case .language:
            languageSection
        case .scan:
            scanSection
        case .ignoredFolders:
            ignoredFoldersSection
        case .filterSets:
            filterSetsSection
        case .filter:
            filterSection
        case .snapshots:
            snapshotsSection
        case .backup:
            backupSection
        case .export:
            exportSection
        case .infoContact:
            infoContactSection
        }
    }

    private var appearanceSection: some View {
        @Bindable var appearance = appearance
        @Bindable var vm = vm

        return Form {
            Section("Appearance") {
                Picker("Appearance", selection: $appearance.mode) {
                    Text("Light").tag(AppearanceMode.light)
                    Text("Dark").tag(AppearanceMode.dark)
                    Text("System").tag(AppearanceMode.system)
                }
                Picker("Zeilenhöhe", selection: $vm.rowDensity) {
                    ForEach(FileRowDensity.allCases) { density in
                        Text(density.title).tag(density)
                    }
                }
                .pickerStyle(.segmented)

                Picker("Icon display", selection: $vm.iconDisplayMode) {
                    Text("Real icons").tag(IconDisplayMode.real)
                    Text("Fast generic icons").tag(IconDisplayMode.generic)
                }
                .pickerStyle(.segmented)
            }
        }
        .formStyle(.grouped)
    }

    private var languageSection: some View {
        @Bindable var language = language

        return Form {
            Section("Language") {
                Picker("Language", selection: $language.language) {
                    Text("Deutsch").tag(AppLanguage.de)
                    Text("English").tag(AppLanguage.en)
                    Text("System").tag(AppLanguage.auto)
                }
            }
        }
        .formStyle(.grouped)
    }

    private var scanSection: some View {
        @Bindable var vm = vm

        return Form {
            Section("Scan Settings") {
                Picker("Auto-scan on launch", selection: $vm.autoScanOnLaunchMode) {
                    ForEach(AutoScanOnLaunchMode.allCases) { mode in
                        Text(autoScanOnLaunchTitle(for: mode)).tag(mode)
                    }
                }
                .pickerStyle(.radioGroup)

                Button("Rescan now") { vm.startScan() }
                    .disabled(vm.scanRoots.isEmpty || vm.isScanning)
                Button("Clear Cache", role: .destructive) {
                    showClearCacheConfirmation = true
                }
                .disabled(vm.isScanning)
                .confirmationDialog("Clear Cache?", isPresented: $showClearCacheConfirmation, titleVisibility: .visible) {
                    Button("Clear Cache", role: .destructive) {
                        vm.clearIndexCache()
                        cacheClearMessage = NSLocalizedString("Cache cleared.", comment: "")
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This clears cached scan results. Files on disk are not changed.")
                }
                if let cacheClearMessage {
                    Text(cacheClearMessage)
                        .font(.caption)
                        .foregroundStyle(AppTheme.theme.accentColor)
                }
                Text("Ignored folder rules apply on the next scan.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.theme.textSecondary)
            }
        }
        .formStyle(.grouped)
    }

    private func autoScanOnLaunchTitle(for mode: AutoScanOnLaunchMode) -> LocalizedStringKey {
        switch mode {
        case .off: return "Off"
        case .allSavedAndRecent: return "Scan all Orte and Schnellzugriff folders"
        case .restoreCached: return "Restore last cached folders"
        }
    }

    private var ignoredFoldersSection: some View {
        Form {
            Section("Ignored Folders") {
                Text("Folders whose name starts with one of these (prefix match, case-insensitive) are shown as a single entry and not scanned — e.g. “Firmware” also matches “Firmware.19.0.1”. Applies on next scan.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.theme.textSecondary)

                if !vm.skippedFolderNames.isEmpty {
                    let columns = [GridItem(.adaptive(minimum: 100), spacing: 6)]
                    LazyVGrid(columns: columns, alignment: .leading, spacing: 6) {
                        ForEach(vm.skippedFolderNames, id: \.self) { name in
                            HStack(spacing: 4) {
                                Text(name).font(.caption)
                                Button {
                                    vm.removeSkippedFolder(name)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(AppTheme.theme.accentColor.opacity(0.15), in: Capsule())
                            .foregroundStyle(AppTheme.theme.accentColor)
                        }
                    }
                }

                HStack {
                    TextField("Ignored folder", text: $newIgnoredFolder)
                        .onSubmit(addIgnoredFolder)
                    Button("Add") { addIgnoredFolder() }
                        .disabled(newIgnoredFolder.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    Button("Choose…") { vm.addSkippedFoldersViaPanel() }
                }
            }
        }
        .formStyle(.grouped)
    }

    private var filterSetsSection: some View {
        Form {
            Section("Filter Sets") {
                Picker("Active filter set", selection: activePresetBinding) {
                    Text("None").tag(FilterPreset.ID?.none)
                    ForEach(vm.presets) { preset in
                        Text(preset.name).tag(FilterPreset.ID?.some(preset.id))
                    }
                }

                if vm.presets.isEmpty {
                    Text("Keine Filtersets gespeichert")
                        .foregroundStyle(AppTheme.theme.textSecondary)
                } else {
                    ForEach(vm.presets) { preset in
                        HStack {
                            Text(preset.name)
                            Spacer()
                            Button("Edit…") {
                                editingPreset = preset
                                showPresetEditor = true
                            }
                            Button(role: .destructive) {
                                vm.deletePreset(preset)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Button {
                    editingPreset = nil
                    showPresetEditor = true
                } label: {
                    Label("New Filter Set…", systemImage: "plus")
                }
            }
        }
        .formStyle(.grouped)
    }

    private var filterSection: some View {
        @Bindable var vm = vm

        return Form {
            Section("Modified date") {
                Toggle("Filter by modified date", isOn: $filterByDate)
                    .onChange(of: filterByDate) { _, on in
                        if !on {
                            vm.dateFrom = nil
                            vm.dateTo = nil
                        } else {
                            vm.dateFrom = vm.dateFrom ?? Date.distantPast
                            vm.dateTo = vm.dateTo ?? Date()
                        }
                    }
                if filterByDate {
                    DatePicker("From", selection: Binding(
                        get: { vm.dateFrom ?? Date.distantPast },
                        set: { vm.dateFrom = $0 }), displayedComponents: .date)
                    DatePicker("To", selection: Binding(
                        get: { vm.dateTo ?? Date() },
                        set: { vm.dateTo = $0 }), displayedComponents: .date)
                }
            }

            Section("Duplicates") {
                Toggle("Only duplicates", isOn: $vm.showOnlyDuplicates)
                    .tint(AppTheme.theme.accentColor)
            }

            Section("Tags") {
                Picker("Tag filter", selection: $vm.selectedTagFilter) {
                    Text("All tags").tag(FileTag?.none)
                    ForEach(vm.availableTags) { tag in
                        Text(tag.title).tag(FileTag?.some(tag))
                    }
                }
            }

            Section {
                Text("Tip: type “> 10 MB” or “< 500 KB” in the search field to filter by size.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.theme.textSecondary)
            }
        }
        .formStyle(.grouped)
    }

    private var snapshotsSection: some View {
        SnapshotPickerView(showsChrome: false)
    }

    private var backupSection: some View {
        Form {
            Section("Backup") {
                if vm.scanRoots.isEmpty {
                    Text("Keine Scan-Orte konfiguriert")
                        .foregroundStyle(AppTheme.theme.textSecondary)
                } else {
                    ForEach(vm.scanRoots, id: \.self) { url in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(url.lastPathComponent)
                                if let destination = backup.destinationDisplayName(for: url) {
                                    Text(destination)
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.theme.textSecondary)
                                }
                            }
                            Spacer()
                            Button("Settings") {
                                backupSettingsLocation = url
                                showBackupSettings = true
                            }
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    private var exportSection: some View {
        Form {
            Section("Export") {
                HStack {
                    Button("Excel exportieren") { vm.export(format: .xlsx) }
                    Button("PDF exportieren") { vm.export(format: .pdf) }
                    Button("CSV exportieren") { vm.export(format: .csv) }
                }
                .disabled(!vm.hasExportableContent)
            }
        }
        .formStyle(.grouped)
    }

    private var infoContactSection: some View {
        Form {
            Section("Info & Contact") {
                Text(appVersionText)
                    .foregroundStyle(AppTheme.theme.textPrimary)

                if let issuesURL = URL(string: "https://github.com/Schrotty74/FileAtlas/issues") {
                    Link("Report a bug on GitHub", destination: issuesURL)
                }

                Text("Please report bugs and suggestions directly on GitHub.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.theme.textSecondary)
            }
        }
        .formStyle(.grouped)
    }

    private var appVersionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        return "Version \(version ?? build ?? "-")"
    }

    private var activePresetBinding: Binding<FilterPreset.ID?> {
        Binding(
            get: { vm.activePresetID },
            set: { vm.activePresetID = $0 }
        )
    }

    private func addIgnoredFolder() {
        vm.addSkippedFolder(newIgnoredFolder)
        newIgnoredFolder = ""
    }
}

private enum SettingsSection: String, CaseIterable, Identifiable, Hashable {
    case appearance
    case language
    case scan
    case ignoredFolders
    case filterSets
    case filter
    case snapshots
    case backup
    case export
    case infoContact

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .appearance: return "Appearance"
        case .language: return "Language"
        case .scan: return "Scan Settings"
        case .ignoredFolders: return "Ignored Folders"
        case .filterSets: return "Filter Sets"
        case .filter: return "Filter"
        case .snapshots: return "Snapshots"
        case .backup: return "Backup"
        case .export: return "Export"
        case .infoContact: return "Info & Contact"
        }
    }

    var systemImage: String {
        switch self {
        case .appearance: return "paintpalette"
        case .language: return "globe"
        case .scan: return "magnifyingglass"
        case .ignoredFolders: return "folder.badge.minus"
        case .filterSets: return "bookmark"
        case .filter: return "tag"
        case .snapshots: return "camera"
        case .backup: return "externaldrive"
        case .export: return "square.and.arrow.up"
        case .infoContact: return "info.circle"
        }
    }
}
