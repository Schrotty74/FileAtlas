//
//  PresetEditorView.swift
//  FileAtlas
//
//  Editor zum Anlegen/Bearbeiten eines FilterPreset.
//

import SwiftUI

struct PresetEditorView: View {
    @Environment(IndexViewModel.self) private var vm
    @Environment(\.dismiss) private var dismiss

    /// `nil` = neues Preset.
    let original: FilterPreset?

    @State private var name: String = ""
    @State private var included: [String] = []
    @State private var excluded: [String] = []
    @State private var extensionWhitelistEnabled = false
    @State private var extensionWhitelist: [String] = []
    @State private var newIncluded: String = ""
    @State private var newExcluded: String = ""
    @State private var newWhitelistExtension: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(original == nil ? "New Filter Set" : "Edit Filter Set")
                    .font(.headline)
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Save") { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding()

            Divider()

            Form {
                Section("Name") {
                    TextField("Filter set name", text: $name)
                }

                Section("Included extensions") {
                    extensionEditor(items: $included, newValue: $newIncluded, suggestions: [])
                    Text("Empty = all files allowed.")
                        .font(.caption)
                        .foregroundStyle(AppTheme.theme.textSecondary)
                }

                Section("Excluded extensions") {
                    extensionEditor(items: $excluded, newValue: $newExcluded,
                                    suggestions: FilterPreset.suggestedExclusions)
                }

                Section("Formats") {
                    Toggle("Show only these formats", isOn: $extensionWhitelistEnabled)
                        .tint(AppTheme.theme.accentColor)
                    extensionEditor(items: $extensionWhitelist, newValue: $newWhitelistExtension, suggestions: [])
                        .disabled(!extensionWhitelistEnabled)
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 460, height: 540)
        .onAppear(perform: load)
    }

    private func extensionEditor(items: Binding<[String]>, newValue: Binding<String>, suggestions: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if !items.wrappedValue.isEmpty {
                FlowChips(items: items.wrappedValue) { value in
                    items.wrappedValue.removeAll { $0 == value }
                }
            }
            HStack {
                TextField("Add extension (e.g. jpg)", text: newValue)
                    .onSubmit { add(newValue.wrappedValue, to: items, clearing: newValue) }
                Button("Add") { add(newValue.wrappedValue, to: items, clearing: newValue) }
                    .disabled(newValue.wrappedValue.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            if !suggestions.isEmpty {
                HStack(spacing: 6) {
                    ForEach(suggestions, id: \.self) { s in
                        Button(s) {
                            let n = FilterPreset.normalize(s)
                            if !items.wrappedValue.contains(n) { items.wrappedValue.append(n) }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }
        }
    }

    private func add(_ value: String, to items: Binding<[String]>, clearing field: Binding<String>) {
        let n = FilterPreset.normalize(value)
        guard !n.isEmpty, !items.wrappedValue.contains(n) else { field.wrappedValue = ""; return }
        items.wrappedValue.append(n)
        field.wrappedValue = ""
    }

    private func load() {
        if let original {
            name = original.name
            included = original.includedExtensions
            excluded = original.excludedExtensions
            extensionWhitelistEnabled = original.extensionWhitelistEnabled
            extensionWhitelist = original.extensionWhitelist
        }
    }

    private func save() {
        var preset = original ?? FilterPreset(name: name)
        preset.name = name.trimmingCharacters(in: .whitespaces)
        preset.includedExtensions = included
        preset.excludedExtensions = excluded
        preset.extensionWhitelistEnabled = extensionWhitelistEnabled
        preset.extensionWhitelist = extensionWhitelist
        vm.savePreset(preset)
        dismiss()
    }
}

/// Einfache Chip-Darstellung mit Entfernen-Button.
private struct FlowChips: View {
    let items: [String]
    let onRemove: (String) -> Void

    var body: some View {
        let columns = [GridItem(.adaptive(minimum: 64), spacing: 6)]
        LazyVGrid(columns: columns, alignment: .leading, spacing: 6) {
            ForEach(items, id: \.self) { item in
                HStack(spacing: 4) {
                    Text(item)
                        .font(.caption)
                    Button {
                        onRemove(item)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption2)
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
}
