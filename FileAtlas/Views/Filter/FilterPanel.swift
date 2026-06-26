//
//  FilterPanel.swift
//  FileAtlas
//
//  Sheet für Ad-hoc-Filter: Datumsbereich, Duplikate, aktives Preset.
//

import SwiftUI

struct FilterPanel: View {
    @Environment(IndexViewModel.self) private var vm
    @Environment(\.dismiss) private var dismiss

    @State private var filterByDate = false
    @State private var newFolder = ""

    var body: some View {
        @Bindable var vm = vm
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Filter")
                    .font(.headline)
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding()

            Divider()

            Form {
                Section("Modified date") {
                    Toggle("Filter by modified date", isOn: $filterByDate)
                        .onChange(of: filterByDate) { _, on in
                            if !on { vm.dateFrom = nil; vm.dateTo = nil }
                            else { vm.dateFrom = vm.dateFrom ?? Date.distantPast; vm.dateTo = vm.dateTo ?? Date() }
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

                Section("Table density") {
                    Picker("Row height", selection: $vm.rowDensity) {
                        ForEach(FileRowDensity.allCases) { density in
                            Text(density.title).tag(density)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Active filter set") {
                    Picker("Filter set", selection: $vm.activePresetID) {
                        Text("None").tag(FilterPreset.ID?.none)
                        ForEach(vm.presets) { preset in
                            Text(preset.name).tag(FilterPreset.ID?.some(preset.id))
                        }
                    }
                }

                Section("Ignored folders") {
                    Text("Folders whose name starts with one of these (prefix match, case-insensitive) are shown as a single entry and not scanned — e.g. \u{201C}Firmware\u{201D} also matches \u{201C}Firmware.19.0.1\u{201D}. Applies on next scan.")
                        .font(.caption)
                        .foregroundStyle(AppTheme.theme.textSecondary)

                    if !vm.skippedFolderNames.isEmpty {
                        let columns = [GridItem(.adaptive(minimum: 90), spacing: 6)]
                        LazyVGrid(columns: columns, alignment: .leading, spacing: 6) {
                            ForEach(vm.skippedFolderNames, id: \.self) { name in
                                HStack(spacing: 4) {
                                    Text(name).font(.caption)
                                    Button {
                                        vm.removeSkippedFolder(name)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill").font(.caption2)
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
                        TextField("Add folder name (e.g. node_modules)", text: $newFolder)
                            .onSubmit { addFolder() }
                        Button("Add") { addFolder() }
                            .disabled(newFolder.trimmingCharacters(in: .whitespaces).isEmpty)
                    }

                    Button {
                        vm.addSkippedFoldersViaPanel()
                    } label: {
                        Label("Choose folders…", systemImage: "folder.badge.minus")
                    }

                    Button {
                        addFolder()        // ausstehende Eingabe übernehmen
                        dismiss()
                        vm.startScan()
                    } label: {
                        Label("Rescan now", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.theme.accentColor)
                    .disabled(vm.scanRoots.isEmpty || vm.isScanning)
                }

                Section {
                    Text("Tip: type \u{201C}> 10 MB\u{201D} or \u{201C}< 500 KB\u{201D} in the search field to filter by size.")
                        .font(.caption)
                        .foregroundStyle(AppTheme.theme.textSecondary)
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 440, height: 560)
        .onAppear { filterByDate = vm.dateFrom != nil || vm.dateTo != nil }
    }

    private func addFolder() {
        vm.addSkippedFolder(newFolder)
        newFolder = ""
    }
}
