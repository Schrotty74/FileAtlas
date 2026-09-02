//
//  MainSettingsPanel.swift
//  FileAtlas
//

import SwiftUI

struct MainSettingsPanel: View {
    @Environment(IndexViewModel.self) private var vm
    @Environment(AppearanceManager.self) private var appearance
    @Environment(LanguageManager.self) private var language
    @Environment(MotionPreferences.self) private var motion
    @Environment(TooltipPreferences.self) private var tooltips
    @Environment(BackupManager.self) private var backup
    @Environment(UIState.self) private var ui
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
    @State private var editingAlertRule: AlertRule?
    @State private var showAlertRuleEditor = false

    private func text(_ german: String, _ english: String) -> String {
        language.effectiveLanguage == .de ? german : english
    }

    var body: some View {
        HStack(spacing: 0) {
            List {
                ForEach(SettingsSection.allCases) { section in
                    Button {
                        selectedSection = section
                    } label: {
                        Label(section.title(isGerman: language.effectiveLanguage == .de), systemImage: section.systemImage)
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
                    Text((selectedSection ?? .appearance).title(isGerman: language.effectiveLanguage == .de))
                        .font(.headline)
                    Spacer()
                    Button(text("Fertig", "Done")) { dismiss() }
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
        .sheet(isPresented: $showAlertRuleEditor) {
            AlertRuleEditorView(original: editingAlertRule)
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
        case .rules:
            rulesSection
        case .smartCollections:
            smartCollectionsSection
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
        @Bindable var motion = motion
        @Bindable var tooltips = tooltips

        return Form {
            Section(text("Darstellung", "Appearance")) {
                Picker(text("Darstellung", "Appearance"), selection: $appearance.mode) {
                    Text(text("Hell", "Light")).tag(AppearanceMode.light)
                    Text(text("Dunkel", "Dark")).tag(AppearanceMode.dark)
                    Text(text("System", "System")).tag(AppearanceMode.system)
                }

                Picker(text("Farbthema", "Color theme"), selection: $appearance.colorTheme) {
                    Text("Midnight Teal").tag(ColorTheme.midnightTeal)
                    Text("Retro").tag(ColorTheme.retro)
                    Text("Graphite Lime").tag(ColorTheme.graphiteLime)
                    Text(text("Herbst", "Autumn")).tag(ColorTheme.autumn)
                    Text("Winter").tag(ColorTheme.winter)
                    Text(text("Glas", "Glass")).tag(ColorTheme.glass)
                }

                Picker(text("Zeilenhöhe", "Row height"), selection: $vm.rowDensity) {
                    ForEach(FileRowDensity.allCases) { density in
                        Text(density.title).tag(density)
                    }
                }
                .pickerStyle(.segmented)

                Picker(text("Icon-Anzeige", "Icon display"), selection: $vm.iconDisplayMode) {
                    Text(text("Echte Symbole", "Real icons")).tag(IconDisplayMode.real)
                    Text(text("Schnelle Standardsymbole", "Fast generic icons")).tag(IconDisplayMode.generic)
                }
                .pickerStyle(.segmented)

                Toggle(text("Bewegungen reduzieren", "Reduce interface motion"), isOn: $motion.reduceMotion)
                    .tint(AppTheme.theme.accentColor)
                Text(text("Berücksichtigt auch die macOS-Bedienungshilfe „Bewegung reduzieren“.", "Also follows the macOS Reduce Motion accessibility setting."))
                    .font(.caption)
                    .foregroundStyle(AppTheme.theme.textSecondary)

                Toggle(text("Tooltips anzeigen", "Show tooltips"), isOn: $tooltips.showTooltips)
                    .tint(AppTheme.theme.accentColor)
            }
        }
        .formStyle(.grouped)
    }

    private var languageSection: some View {
        @Bindable var language = language

        return Form {
            Section(text("Sprache", "Language")) {
                Picker(text("Sprache", "Language"), selection: $language.language) {
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
            Section(text("Scan-Einstellungen", "Scan Settings")) {
                Picker(text("Automatisch beim Start scannen", "Auto-scan on launch"), selection: $vm.autoScanOnLaunchMode) {
                    ForEach(AutoScanOnLaunchMode.allCases) { mode in
                        Text(autoScanOnLaunchTitle(for: mode)).tag(mode)
                    }
                }
                .pickerStyle(.radioGroup)

                Toggle(text("Duplikate über alle Orte vergleichen", "Compare duplicates across all locations"), isOn: $vm.compareDuplicatesAcrossLocations)
                    .tint(AppTheme.theme.accentColor)
                Text(text("Aus vergleicht Duplikate nur innerhalb desselben gespeicherten Orts. Aktivieren, um Kopien zwischen Orten wie iCloud und einem lokalen Backup zu vergleichen. Gilt ab dem nächsten Scan.", "Off compares duplicates only within the same saved location. Turn this on to compare copies between locations such as iCloud and a local backup. Applies on the next scan."))
                    .font(.caption)
                    .foregroundStyle(AppTheme.theme.textSecondary)

                Button(text("Jetzt erneut scannen", "Rescan now")) { vm.startScan() }
                    .disabled(vm.scanRoots.isEmpty || vm.isScanning)
                Button(text("Cache leeren", "Clear Cache"), role: .destructive) {
                    showClearCacheConfirmation = true
                }
                .disabled(vm.isScanning)
                .confirmationDialog(text("Cache leeren?", "Clear Cache?"), isPresented: $showClearCacheConfirmation, titleVisibility: .visible) {
                    Button(text("Cache leeren", "Clear Cache"), role: .destructive) {
                        vm.clearIndexCache()
                        cacheClearMessage = NSLocalizedString("Cache cleared.", comment: "")
                    }
                    Button(text("Abbrechen", "Cancel"), role: .cancel) {}
                } message: {
                    Text(text("Dadurch werden zwischengespeicherte Scan-Ergebnisse gelöscht. Dateien auf dem Datenträger bleiben unverändert.", "This clears cached scan results. Files on disk are not changed."))
                }
                if let cacheClearMessage {
                    Text(cacheClearMessage)
                        .font(.caption)
                        .foregroundStyle(AppTheme.theme.accentColor)
                }
                Text(text("Regeln für ignorierte Ordner gelten ab dem nächsten Scan.", "Ignored folder rules apply on the next scan."))
                    .font(.caption)
                    .foregroundStyle(AppTheme.theme.textSecondary)
            }
        }
        .formStyle(.grouped)
    }

    private func autoScanOnLaunchTitle(for mode: AutoScanOnLaunchMode) -> String {
        switch mode {
        case .off: return text("Aus", "Off")
        case .allSavedAndRecent: return text("Alle Orte und Schnellzugriff scannen", "Scan all saved and quick-access folders")
        case .restoreCached: return text("Zuletzt zwischengespeicherte Ordner wiederherstellen", "Restore last cached folders")
        }
    }

    private var ignoredFoldersSection: some View {
        Form {
            Section(text("Ignorierte Ordner", "Ignored Folders")) {
                Text(text("Ordner, deren Name mit einem dieser Werte beginnt (Präfixvergleich, Groß-/Kleinschreibung egal), werden als einzelner Eintrag angezeigt und nicht durchsucht. Beispiel: „Firmware“ passt auch auf „Firmware.19.0.1“. Gilt ab dem nächsten Scan.", "Folders whose name starts with one of these (prefix match, case-insensitive) are shown as a single entry and not scanned — e.g. “Firmware” also matches “Firmware.19.0.1”. Applies on next scan."))
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
                    TextField(text("Ignorierter Ordner", "Ignored folder"), text: $newIgnoredFolder)
                        .onSubmit(addIgnoredFolder)
                    Button(text("Hinzufügen", "Add")) { addIgnoredFolder() }
                        .disabled(newIgnoredFolder.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    Button(text("Auswählen…", "Choose…")) { vm.addSkippedFoldersViaPanel() }
                }
            }
        }
        .formStyle(.grouped)
    }

    private var filterSetsSection: some View {
        @Bindable var vm = vm

        return Form {
            Section(text("Filtersets", "Filter Sets")) {
                Picker(text("Aktives Filterset", "Active filter set"), selection: activePresetBinding) {
                    Text(text("Keine", "None")).tag(FilterPreset.ID?.none)
                    ForEach(vm.presets) { preset in
                        Text(preset.name).tag(FilterPreset.ID?.some(preset.id))
                    }
                }

                Toggle(text("Aktiven Filter beim Start wiederherstellen", "Restore active filter on launch"), isOn: $vm.restoreActiveFilterOnLaunch)
                    .tint(AppTheme.theme.accentColor)
                Text(text("Wenn aktiviert, bleibt das zuletzt ausgewählte Filterset auch nach dem Beenden und Neustart aktiv.", "When enabled, the last selected filter set remains active after quitting and restarting."))
                    .font(.caption)
                    .foregroundStyle(AppTheme.theme.textSecondary)

                if vm.presets.isEmpty {
                    Text(text("Keine Filtersets gespeichert", "No filter sets saved"))
                        .foregroundStyle(AppTheme.theme.textSecondary)
                } else {
                    ForEach(vm.presets) { preset in
                        HStack {
                            Text(preset.name)
                            Spacer()
                            Button(text("Bearbeiten…", "Edit…")) {
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
                    Label(text("Neues Filterset…", "New Filter Set…"), systemImage: "plus")
                }
            }
        }
        .formStyle(.grouped)
    }

    private var filterSection: some View {
        @Bindable var vm = vm

        return Form {
            Section(text("Änderungsdatum", "Modified date")) {
                Toggle(text("Nach Änderungsdatum filtern", "Filter by modified date"), isOn: $filterByDate)
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
                    DatePicker(text("Von", "From"), selection: Binding(
                        get: { vm.dateFrom ?? Date.distantPast },
                        set: { vm.dateFrom = $0 }), displayedComponents: .date)
                    DatePicker(text("Bis", "To"), selection: Binding(
                        get: { vm.dateTo ?? Date() },
                        set: { vm.dateTo = $0 }), displayedComponents: .date)
                }
            }

            Section(text("Duplikate", "Duplicates")) {
                Toggle(text("Nur Duplikate", "Only duplicates"), isOn: $vm.showOnlyDuplicates)
                    .tint(AppTheme.theme.accentColor)
            }

            Section(text("Tags", "Tags")) {
                Picker(text("Tag-Filter", "Tag filter"), selection: $vm.selectedTagFilter) {
                    Text(text("Alle Tags", "All tags")).tag(FileTag?.none)
                    ForEach(vm.availableTags) { tag in
                        Text(tag.title).tag(FileTag?.some(tag))
                    }
                }
            }

            Section {
                Text(text("Tipp: „> 10 MB“ oder „< 500 KB“ im Suchfeld eingeben, um nach Größe zu filtern.", "Tip: type “> 10 MB” or “< 500 KB” in the search field to filter by size."))
                    .font(.caption)
                    .foregroundStyle(AppTheme.theme.textSecondary)
            }
        }
        .formStyle(.grouped)
    }

    private var rulesSection: some View {
        Form {
            Section(text("Regeln", "Rules")) {
                Text(text("Regeln werden nach jedem abgeschlossenen Scan geprüft und melden nur Treffer. Sie blenden keine Dateien aus und löschen nichts.", "Rules are checked after every completed scan and only report matches; they do not hide or delete files."))
                    .font(.caption)
                    .foregroundStyle(AppTheme.theme.textSecondary)

                if vm.alertRules.isEmpty {
                    Text(text("Keine Regeln erstellt", "No rules created"))
                        .foregroundStyle(AppTheme.theme.textSecondary)
                } else {
                    ForEach(vm.alertRules) { rule in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(rule.name)
                                Text(ruleDescription(rule))
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.theme.textSecondary)
                            }
                            Spacer()
                            Toggle("", isOn: ruleEnabledBinding(for: rule))
                                .labelsHidden()
                            Button(text("Bearbeiten…", "Edit…")) {
                                editingAlertRule = rule
                                showAlertRuleEditor = true
                            }
                            Button(role: .destructive) {
                                vm.deleteAlertRule(rule)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                HStack {
                    Button {
                        editingAlertRule = nil
                        showAlertRuleEditor = true
                    } label: {
                        Label(text("Neue Regel…", "New Rule…"), systemImage: "plus")
                    }
                    Button(text("Regeln jetzt ausführen", "Run Rules Now")) { vm.evaluateAlertRulesNow() }
                        .disabled(vm.entries.isEmpty || vm.alertRules.isEmpty)
                }
            }
        }
        .formStyle(.grouped)
    }

    private var smartCollectionsSection: some View {
        Form {
            Section(text("Intelligente Sammlungen", "Smart Collections")) {
                Text(text("Sammlungen aktualisieren sich aus dem aktuellen Index und verschieben, verbergen oder löschen keine Dateien.", "Collections update from the current index and never move, hide, or delete files."))
                    .font(.caption)
                    .foregroundStyle(AppTheme.theme.textSecondary)

                if vm.smartCollections.isEmpty {
                    Text(text("Keine intelligenten Sammlungen erstellt", "No smart collections created"))
                        .foregroundStyle(AppTheme.theme.textSecondary)
                } else {
                    ForEach(vm.smartCollections) { collection in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(collection.name)
                                Text(smartCollectionDescription(collection))
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.theme.textSecondary)
                            }
                            Spacer()
                            Text(vm.smartCollectionMatchCount(for: collection).formatted())
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(AppTheme.theme.textSecondary)
                            Button(text("Bearbeiten…", "Edit…")) {
                                ui.editingSmartCollection = collection
                                ui.isPresentingSmartCollectionEditor = true
                            }
                            Button(role: .destructive) {
                                vm.deleteSmartCollection(collection)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Button {
                    ui.editingSmartCollection = nil
                    ui.isPresentingSmartCollectionEditor = true
                } label: {
                    Label(text("Neue intelligente Sammlung…", "New Smart Collection…"), systemImage: "plus")
                }
            }
        }
        .formStyle(.grouped)
    }

    private func smartCollectionDescription(_ collection: SmartCollection) -> String {
        var parts: [String] = []
        if !collection.extensions.isEmpty {
            parts.append(collection.extensions.map { $0.uppercased() }.joined(separator: ", "))
        }
        if let minimumSize = collection.minimumSize {
            let size = ByteCountFormatter.string(fromByteCount: minimumSize, countStyle: .file)
            parts.append(text("ab \(size)", "from \(size)"))
        }
        if let modifiedWithinDays = collection.modifiedWithinDays {
            parts.append(text("letzte \(modifiedWithinDays) Tage", "last \(modifiedWithinDays) days"))
        }
        if collection.duplicatesOnly { parts.append(text("Duplikate", "duplicates")) }
        return parts.joined(separator: " · ")
    }

    private func ruleDescription(_ rule: AlertRule) -> String {
        var parts: [String] = []
        if !rule.extensions.isEmpty { parts.append(rule.extensions.map { $0.uppercased() }.joined(separator: ", ")) }
        if let minimumSize = rule.minimumSize {
            let size = ByteCountFormatter.string(fromByteCount: minimumSize, countStyle: .file)
            parts.append(text("ab \(size)", "from \(size)"))
        }
        if let olderThanDays = rule.olderThanDays {
            parts.append(text("älter als \(olderThanDays) Tage", "older than \(olderThanDays) days"))
        }
        return parts.joined(separator: " · ")
    }

    private func ruleEnabledBinding(for rule: AlertRule) -> Binding<Bool> {
        Binding(
            get: { vm.alertRules.first(where: { $0.id == rule.id })?.isEnabled ?? false },
            set: { isEnabled in
                var updated = rule
                updated.isEnabled = isEnabled
                vm.saveAlertRule(updated)
            }
        )
    }

    private var snapshotsSection: some View {
        SnapshotPickerView(showsChrome: false)
    }

    private var backupSection: some View {
        Form {
            Section(text("Backup", "Backup")) {
                if vm.scanRoots.isEmpty {
                    Text(text("Keine Scan-Orte konfiguriert", "No scan locations configured"))
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
                            Button(text("Einstellungen", "Settings")) {
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
            Section(text("Export", "Export")) {
                HStack {
                    Button(text("Excel exportieren", "Export Excel")) { vm.export(format: .xlsx) }
                    Button(text("PDF exportieren", "Export PDF")) { vm.export(format: .pdf) }
                    Button(text("CSV exportieren", "Export CSV")) { vm.export(format: .csv) }
                }
                .disabled(!vm.hasExportableContent)
            }
        }
        .formStyle(.grouped)
    }

    private var infoContactSection: some View {
        Form {
            Section(text("Info & Kontakt", "Info & Contact")) {
                Text(appVersionText)
                    .foregroundStyle(AppTheme.theme.textPrimary)

                Toggle(text("Beim Start nach Updates suchen", "Check for updates on launch"), isOn: Bindable(vm).automaticUpdateChecksEnabled)

                Picker(text("Release-Kanal", "Release channel"), selection: Bindable(vm).updateReleaseChannel) {
                    Text(text("Nur Final", "Final releases only")).tag(UpdateReleaseChannel.finalOnly)
                    Text(text("Beta und Final", "Beta and final releases")).tag(UpdateReleaseChannel.betaAndFinal)
                }
                .disabled(!vm.automaticUpdateChecksEnabled)

                Text(text("Die Prüfung kontaktiert ausschließlich GitHub Releases und lädt keine App automatisch herunter.", "The check contacts GitHub Releases only and never downloads the app automatically."))
                    .font(.caption)
                    .foregroundStyle(AppTheme.theme.textSecondary)

                if let availableUpdate = vm.availableUpdate {
                    Button {
                        vm.openAvailableUpdate()
                    } label: {
                        Label(
                            String(
                                format: text("Release %@ auf GitHub öffnen", "Open release %@ on GitHub"),
                                availableUpdate.versionTag
                            ),
                            systemImage: "arrow.up.forward.app.fill"
                        )
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.theme.accentColor)
                }

                Button {
                    Task { await vm.checkForUpdates(force: true) }
                } label: {
                    HStack {
                        if vm.isCheckingForUpdates {
                            ProgressView()
                                .controlSize(.small)
                        }
                        Text(text("Nach Updates suchen", "Check for updates"))
                    }
                }
                .disabled(vm.isCheckingForUpdates)

                if let updateCheckStatusMessage = vm.updateCheckStatusMessage {
                    Text(updateCheckStatusMessage)
                        .font(.caption)
                        .foregroundStyle(AppTheme.theme.textSecondary)
                }

                if let issuesURL = URL(string: "https://github.com/Schrotty74/FileAtlas/issues") {
                    Link(text("Fehler auf GitHub melden", "Report a bug on GitHub"), destination: issuesURL)
                }

                Text(text("Bitte Fehler und Vorschläge direkt auf GitHub melden.", "Please report bugs and suggestions directly on GitHub."))
                    .font(.caption)
                    .foregroundStyle(AppTheme.theme.textSecondary)
            }
        }
        .formStyle(.grouped)
    }

    private var appVersionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        return text("Version \(version ?? build ?? "-")", "Version \(version ?? build ?? "-")")
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
    case rules
    case smartCollections
    case snapshots
    case backup
    case export
    case infoContact

    var id: String { rawValue }

    func title(isGerman: Bool) -> String {
        switch self {
        case .appearance: return isGerman ? "Darstellung" : "Appearance"
        case .language: return isGerman ? "Sprache" : "Language"
        case .scan: return isGerman ? "Scan-Einstellungen" : "Scan Settings"
        case .ignoredFolders: return isGerman ? "Ignorierte Ordner" : "Ignored Folders"
        case .filterSets: return isGerman ? "Filtersets" : "Filter Sets"
        case .filter: return "Filter"
        case .rules: return isGerman ? "Regeln" : "Rules"
        case .smartCollections: return isGerman ? "Intelligente Sammlungen" : "Smart Collections"
        case .snapshots: return "Snapshots"
        case .backup: return "Backup"
        case .export: return "Export"
        case .infoContact: return isGerman ? "Info & Kontakt" : "Info & Contact"
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
        case .rules: return "exclamationmark.triangle"
        case .smartCollections: return "folder.badge.gearshape"
        case .snapshots: return "camera"
        case .backup: return "externaldrive"
        case .export: return "square.and.arrow.up"
        case .infoContact: return "info.circle"
        }
    }
}
