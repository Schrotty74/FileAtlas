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
    @State private var hasModifiedLimit = false
    @State private var modifiedWithinDays = 30
    @State private var duplicatesOnly = false

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
                    Toggle("Modified within", isOn: $hasModifiedLimit)
                    if hasModifiedLimit {
                        Stepper("Last \(modifiedWithinDays) days", value: $modifiedWithinDays, in: 1...10_000)
                    }
                }

                Section("Status") {
                    Toggle("Duplicates only", isOn: $duplicatesOnly)
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 460, height: 500)
        .onAppear(perform: load)
    }

    private var hasCondition: Bool {
        !extensions.isEmpty || hasMinimumSize || hasModifiedLimit || duplicatesOnly
    }

    private func load() {
        guard let original else { return }
        name = original.name
        extensions = original.extensions
        hasMinimumSize = original.minimumSize != nil
        minimumSizeMB = max(1, Int((original.minimumSize ?? 100_000_000) / 1_000_000))
        hasModifiedLimit = original.modifiedWithinDays != nil
        modifiedWithinDays = original.modifiedWithinDays ?? 30
        duplicatesOnly = original.duplicatesOnly
    }

    private func addExtension() {
        let value = FilterPreset.normalize(newExtension)
        guard !value.isEmpty else { return }
        if !extensions.contains(value) { extensions.append(value) }
        newExtension = ""
    }

    private func save() {
        vm.saveSmartCollection(SmartCollection(
            id: original?.id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            extensions: extensions,
            minimumSize: hasMinimumSize ? Int64(minimumSizeMB) * 1_000_000 : nil,
            modifiedWithinDays: hasModifiedLimit ? modifiedWithinDays : nil,
            duplicatesOnly: duplicatesOnly
        ))
        dismiss()
    }
}

private struct SmartCollectionChips: View {
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
            }
        }
    }
}
