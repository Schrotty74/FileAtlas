//
//  SmartCollectionEditorView.swift
//  FileAtlas
//

import SwiftUI

struct SmartCollectionEditorView: View {
    @Environment(IndexViewModel.self) private var vm
    @Environment(\.dismiss) private var dismiss
    let original: SmartCollection?

    @State private var name = ""
    @State private var extensions: [String] = []
    @State private var newExtension = ""
    @State private var hasMinimumSize = false
    @State private var minimumSizeMB = 100
    @State private var hasMaximumSize = false
    @State private var maximumSizeMB = 1_000
    @State private var hasModifiedLimit = false
    @State private var modifiedWithinDays = 30
    @State private var duplicatesOnly = false
    @State private var selectedTagTitles: Set<String> = []
    @State private var selectedFolderPaths: Set<String> = []
    @State private var excludedExtensions: [String] = []
    @State private var newExcludedExtension = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(original == nil ? "New Smart Collection" : "Edit Smart Collection")
                    .font(.headline)
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Save") { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !hasCondition)
            }
            .padding()

            Divider()

            Form {
                Section("Collection") {
                    TextField("Name", text: $name)
                }

                Section("File type") {
                    HStack {
                        TextField("Extension, e.g. dmg", text: $newExtension)
                            .onSubmit(addExtension)
                        Button("Add", action: addExtension)
                            .disabled(newExtension.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    if !extensions.isEmpty {
                        SmartCollectionChips(items: extensions) { value in
                            extensions.removeAll { $0 == value }
                        }
                    }
                }

                Section("Size and time") {
                    Toggle("Minimum size", isOn: $hasMinimumSize)
                    if hasMinimumSize {
                        Stepper("\(minimumSizeMB) MB", value: $minimumSizeMB, in: 1...1_000_000)
                    }
                    Toggle("Maximum size", isOn: $hasMaximumSize)
                    if hasMaximumSize {
                        Stepper("\(maximumSizeMB) MB", value: $maximumSizeMB, in: 1...1_000_000)
                    }
                    Toggle("Modified within", isOn: $hasModifiedLimit)
                    if hasModifiedLimit {
                        Stepper("Last \(modifiedWithinDays) days", value: $modifiedWithinDays, in: 1...10_000)
                    }
                }

                Section("Status") {
                    Toggle("Duplicates only", isOn: $duplicatesOnly)
                }

                Section("Tags") {
                    if vm.availableTags.isEmpty {
                        Text("No tags available yet.")
                            .foregroundStyle(AppTheme.theme.textSecondary)
                    } else {
                        ForEach(vm.availableTags) { tag in
                            Toggle(tag.title, isOn: Binding(
                                get: { selectedTagTitles.contains(tag.title) },
                                set: { enabled in
                                    if enabled { selectedTagTitles.insert(tag.title) }
                                    else { selectedTagTitles.remove(tag.title) }
                                }
                            ))
                        }
                    }
                }

                Section("Locations") {
                    ForEach(vm.knownFilterScopeFolders, id: \.path) { folder in
                        Toggle(folder.lastPathComponent, isOn: Binding(
                            get: { selectedFolderPaths.contains(folder.path(percentEncoded: false)) },
                            set: { enabled in
                                let path = folder.path(percentEncoded: false)
                                if enabled { selectedFolderPaths.insert(path) }
                                else { selectedFolderPaths.remove(path) }
                            }
                        ))
                    }
                    if vm.knownFilterScopeFolders.isEmpty {
                        Text("Add a location first to limit this collection to a folder.")
                            .foregroundStyle(AppTheme.theme.textSecondary)
                    }
                }

                Section("Exclude file types") {
                    HStack {
                        TextField("Extension, e.g. tmp", text: $newExcludedExtension)
                            .onSubmit(addExcludedExtension)
                        Button("Add", action: addExcludedExtension)
                            .disabled(newExcludedExtension.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    if !excludedExtensions.isEmpty {
                        SmartCollectionChips(items: excludedExtensions) { value in
                            excludedExtensions.removeAll { $0 == value }
                        }
                    }
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 520, height: 680)
        .onAppear(perform: load)
    }

    private var hasCondition: Bool {
        !extensions.isEmpty || hasMinimumSize || hasMaximumSize || hasModifiedLimit || duplicatesOnly
            || !selectedTagTitles.isEmpty || !selectedFolderPaths.isEmpty || !excludedExtensions.isEmpty
    }

    private func load() {
        guard let original else { return }
        name = original.name
        extensions = original.extensions
        hasMinimumSize = original.minimumSize != nil
        minimumSizeMB = max(1, Int((original.minimumSize ?? 100_000_000) / 1_000_000))
        hasMaximumSize = original.maximumSize != nil
        maximumSizeMB = max(1, Int((original.maximumSize ?? 1_000_000_000) / 1_000_000))
        hasModifiedLimit = original.modifiedWithinDays != nil
        modifiedWithinDays = original.modifiedWithinDays ?? 30
        duplicatesOnly = original.duplicatesOnly
        selectedTagTitles = Set(original.tagTitles)
        selectedFolderPaths = Set(original.scopedFolderPaths)
        excludedExtensions = original.excludedExtensions
    }

    private func addExtension() {
        let value = FilterPreset.normalize(newExtension)
        guard !value.isEmpty else { return }
        if !extensions.contains(value) { extensions.append(value) }
        newExtension = ""
    }

    private func addExcludedExtension() {
        let value = FilterPreset.normalize(newExcludedExtension)
        guard !value.isEmpty else { return }
        if !excludedExtensions.contains(value) { excludedExtensions.append(value) }
        newExcludedExtension = ""
    }

    private func save() {
        vm.saveSmartCollection(SmartCollection(
            id: original?.id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            extensions: extensions,
            minimumSize: hasMinimumSize ? Int64(minimumSizeMB) * 1_000_000 : nil,
            maximumSize: hasMaximumSize ? Int64(maximumSizeMB) * 1_000_000 : nil,
            modifiedWithinDays: hasModifiedLimit ? modifiedWithinDays : nil,
            duplicatesOnly: duplicatesOnly,
            tagTitles: Array(selectedTagTitles).sorted(),
            scopedFolderPaths: Array(selectedFolderPaths).sorted(),
            excludedExtensions: excludedExtensions
        ))
        dismiss()
    }
}

private struct SmartCollectionChips: View {
    @Environment(MotionPreferences.self) private var motion
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    let items: [String]
    let onRemove: (String) -> Void

    var body: some View {
        let columns = [GridItem(.adaptive(minimum: 64), spacing: 6)]
        LazyVGrid(columns: columns, alignment: .leading, spacing: 6) {
            ForEach(items, id: \.self) { item in
                HStack(spacing: 4) {
                    Text(item).font(.caption)
                    Button { onRemove(item) } label: {
                        Image(systemName: "xmark.circle.fill").font(.caption2)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(AppTheme.theme.accentColor.opacity(0.15), in: Capsule())
                .foregroundStyle(AppTheme.theme.accentColor)
                .transition(isMotionEnabled ? .scale(scale: 0.82).combined(with: .opacity) : .identity)
            }
        }
        .animation(isMotionEnabled ? FileAtlasMotion.emphasis : nil, value: items)
    }

    private var isMotionEnabled: Bool { !motion.reduceMotion && !systemReduceMotion }
}
