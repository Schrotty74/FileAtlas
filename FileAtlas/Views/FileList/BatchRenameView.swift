import SwiftUI

struct BatchRenameView: View {
    let entries: [FileEntry]

    @Environment(IndexViewModel.self) private var vm
    @Environment(LanguageManager.self) private var language
    @Environment(\.dismiss) private var dismiss
    @State private var prefix = ""
    @State private var suffix = ""
    @State private var addsNumber = false
    @State private var startingAt = 1
    @State private var showsConfirmation = false
    @State private var isRenaming = false
    @State private var statusText: String?

    private func text(_ german: String, _ english: String) -> String {
        language.effectiveLanguage == .de ? german : english
    }

    private var plans: [BatchRenamePlan] {
        BatchRenamePlanner.plans(
            for: entries,
            prefix: prefix,
            suffix: suffix,
            addsNumber: addsNumber,
            startingAt: max(1, startingAt)
        )
    }

    private var validationError: String? {
        BatchRenamePlanner.validationError(for: plans)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(text("Stapel umbenennen", "Batch Rename")).font(.headline)
                    Text(text("\(entries.count) ausgewaehlte Elemente", "\(entries.count) selected items"))
                        .font(.caption)
                        .foregroundStyle(AppTheme.theme.textSecondary)
                }
                Spacer()
                Button(text("Fertig", "Done")) { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding()

            Divider()

            Form {
                Section(text("Namensregel", "Naming Rule")) {
                    TextField(text("Praefix", "Prefix"), text: $prefix)
                    TextField(text("Suffix", "Suffix"), text: $suffix)
                    Toggle(text("Fortlaufende Nummer hinzufuegen", "Add sequential number"), isOn: $addsNumber)
                    if addsNumber {
                        Stepper(text("Start bei \(max(1, startingAt))", "Start at \(max(1, startingAt))"), value: $startingAt, in: 1...999_999)
                    }
                }

                Section(text("Vorschau", "Preview")) {
                    List(plans) { plan in
                        HStack(spacing: 8) {
                            Text(plan.source.lastPathComponent)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Image(systemName: "arrow.right")
                                .foregroundStyle(AppTheme.theme.textSecondary)
                            Text(plan.destination.lastPathComponent)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .foregroundStyle(AppTheme.theme.textPrimary)
                        }
                        .font(.caption)
                    }
                    .frame(minHeight: 210)

                    if let validationError {
                        Label(validationError, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    } else {
                        Text(text("Bestehende Dateien werden nie ueberschrieben.", "Existing files are never overwritten."))
                            .font(.caption)
                            .foregroundStyle(AppTheme.theme.textSecondary)
                    }
                }

                if let statusText {
                    Section(text("Ergebnis", "Result")) {
                        Text(statusText).font(.caption)
                    }
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                Button(text("Abbrechen", "Cancel")) { dismiss() }
                Spacer()
                Button {
                    showsConfirmation = true
                } label: {
                    Label(text("\(plans.count) Elemente umbenennen", "Rename \(plans.count) items"), systemImage: "pencil")
                }
                .disabled(validationError != nil || isRenaming)
            }
            .padding()
        }
        .frame(width: 680, height: 610)
        .confirmationDialog(
            text("Umbenennung ausfuehren?", "Apply rename?"),
            isPresented: $showsConfirmation,
            titleVisibility: .visible
        ) {
            Button(text("Jetzt umbenennen", "Rename Now")) {
                performRename()
            }
        } message: {
            Text(text("Die Vorschau wird auf die ausgewaehlten Elemente angewendet. Diese Aktion kann in FileAtlas nicht rueckgaengig gemacht werden.", "The preview will be applied to the selected items. This action cannot be undone in FileAtlas."))
        }
    }

    private func performRename() {
        let plans = plans
        isRenaming = true
        Task {
            let result = await vm.applyBatchRename(plans)
            if result.failures.isEmpty {
                statusText = text("\(result.renamedCount) Elemente wurden umbenannt.", "Renamed \(result.renamedCount) items.")
            } else {
                statusText = text(
                    "\(result.renamedCount) umbenannt. \(result.failures.joined(separator: " "))",
                    "Renamed \(result.renamedCount). \(result.failures.joined(separator: " "))"
                )
            }
            isRenaming = false
        }
    }
}
