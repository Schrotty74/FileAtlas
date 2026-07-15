//
//  AlertRuleEditorView.swift
//  FileAtlas
//

import SwiftUI

struct AlertRuleEditorView: View {
    @Environment(IndexViewModel.self) private var vm
    @Environment(\.dismiss) private var dismiss
    let original: AlertRule?

    @State private var name = ""
    @State private var extensions: [String] = []
    @State private var newExtension = ""
    @State private var hasMinimumSize = false
    @State private var minimumSizeMB = 100
    @State private var hasAgeLimit = false
    @State private var olderThanDays = 365
    @State private var isEnabled = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(original == nil ? "New Rule" : "Edit Rule")
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
                Section("Rule") {
                    TextField("Name", text: $name)
                    Toggle("Enabled", isOn: $isEnabled)
                }

                Section("File type") {
                    HStack {
                        TextField("Extension, e.g. dmg", text: $newExtension)
                            .onSubmit(addExtension)
                        Button("Add", action: addExtension)
                            .disabled(newExtension.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    if !extensions.isEmpty {
                        AlertRuleChips(items: extensions) { value in
                            extensions.removeAll { $0 == value }
                        }
                    }
                    Text("Leave empty to apply to every file type.")
                        .font(.caption)
                        .foregroundStyle(AppTheme.theme.textSecondary)
                }

                Section("Size") {
                    Toggle("Minimum size", isOn: $hasMinimumSize)
                    if hasMinimumSize {
                        Stepper("\(minimumSizeMB) MB", value: $minimumSizeMB, in: 1...1_000_000)
                    }
                }

                Section("Age") {
                    Toggle("Modified before", isOn: $hasAgeLimit)
                    if hasAgeLimit {
                        Stepper("More than \(olderThanDays) days ago", value: $olderThanDays, in: 1...10_000)
                    }
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 460, height: 500)
        .onAppear(perform: load)
    }

    private var hasCondition: Bool {
        !extensions.isEmpty || hasMinimumSize || hasAgeLimit
    }

    private func load() {
        guard let original else { return }
        name = original.name
        extensions = original.extensions
        hasMinimumSize = original.minimumSize != nil
        minimumSizeMB = max(1, Int((original.minimumSize ?? 100_000_000) / 1_000_000))
        hasAgeLimit = original.olderThanDays != nil
        olderThanDays = original.olderThanDays ?? 365
        isEnabled = original.isEnabled
    }

    private func addExtension() {
        let value = FilterPreset.normalize(newExtension)
        guard !value.isEmpty else { return }
        if !extensions.contains(value) { extensions.append(value) }
        newExtension = ""
    }

    private func save() {
        let rule = AlertRule(
            id: original?.id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            extensions: extensions,
            minimumSize: hasMinimumSize ? Int64(minimumSizeMB) * 1_000_000 : nil,
            olderThanDays: hasAgeLimit ? olderThanDays : nil,
            isEnabled: isEnabled
        )
        vm.saveAlertRule(rule)
        dismiss()
    }
}

private struct AlertRuleChips: View {
    let items: [String]
    let onRemove: (String) -> Void

    var body: some View {
        let columns = [GridItem(.adaptive(minimum: 64), spacing: 6)]
        LazyVGrid(columns: columns, alignment: .leading, spacing: 6) {
            ForEach(items, id: \.self) { item in
                HStack(spacing: 4) {
                    Text(item).font(.caption)
                    Button {
                        onRemove(item)
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
}
