import SwiftUI
import AppKit

struct ArchiveInspectorView: View {
    let archiveURL: URL

    @Environment(LanguageManager.self) private var language
    @Environment(\.dismiss) private var dismiss
    @State private var inspection: ArchiveInspection?
    @State private var selectedEntries = Set<String>()
    @State private var destination: URL?
    @State private var statusText: String?

    private func text(_ de: String, _ en: String) -> String {
        language.effectiveLanguage == .de ? de : en
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(text("Archiv pruefen", "Inspect Archive")).font(.headline)
                    Text(archiveURL.lastPathComponent).font(.caption).foregroundStyle(AppTheme.theme.textSecondary)
                }
                Spacer()
                Button(text("Fertig", "Done")) { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding()

            Divider()

            if let inspection {
                Form {
                    Section(text("Integritaet", "Integrity")) {
                        Label(
                            inspection.isValid ? text("ZIP-Struktur ist lesbar", "ZIP structure is readable") : text("Archiv konnte nicht bestaetigt werden", "Archive could not be verified"),
                            systemImage: inspection.isValid ? "checkmark.seal.fill" : "exclamationmark.triangle.fill"
                        )
                        .foregroundStyle(inspection.isValid ? AppTheme.theme.accentColor : .orange)
                        if inspection.hasHashManifest {
                            Label(text("SHA-256-Manifest neben dem Archiv vorhanden", "SHA-256 manifest found beside archive"), systemImage: "checkmark.shield")
                        }
                        Text(inspection.message)
                            .font(.caption)
                            .foregroundStyle(AppTheme.theme.textSecondary)
                    }

                    Section(text("Archivinhalt", "Archive Contents")) {
                        if inspection.entries.isEmpty {
                            Text(text("Keine lesbaren Eintraege", "No readable entries"))
                                .foregroundStyle(AppTheme.theme.textSecondary)
                        } else {
                            List(inspection.entries, id: \.self, selection: $selectedEntries) { entry in
                                Label(entry, systemImage: "doc")
                                    .lineLimit(1)
                            }
                            .frame(minHeight: 220)
                        }
                    }

                    Section(text("Auswahl wiederherstellen", "Restore Selection")) {
                        HStack {
                            Text(destination?.lastPathComponent ?? text("Kein Zielordner gewaehlt", "No destination selected"))
                                .foregroundStyle(destination == nil ? AppTheme.theme.textSecondary : AppTheme.theme.textPrimary)
                            Spacer()
                            Button(text("Auswaehlen…", "Choose…"), action: chooseDestination)
                        }
                        Button {
                            restore()
                        } label: {
                            Label(text("Ausgewaehlte Eintraege wiederherstellen", "Restore Selected Entries"), systemImage: "arrow.uturn.backward")
                        }
                        .disabled(destination == nil || selectedEntries.isEmpty)
                        if let statusText {
                            Text(statusText).font(.caption).foregroundStyle(AppTheme.theme.textSecondary)
                        }
                    }
                }
                .formStyle(.grouped)
            } else {
                ProgressView(text("Archiv wird geprueft…", "Inspecting archive…"))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(width: 620, height: 620)
        .task {
            inspection = await Task.detached { ArchiveInspector.inspect(archiveURL) }.value
        }
    }

    private func chooseDestination() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = text("Auswaehlen", "Choose")
        guard panel.runModal() == .OK else { return }
        destination = panel.url
    }

    private func restore() {
        guard let destination else { return }
        let entries = Array(selectedEntries)
        Task {
            do {
                try await Task.detached { try ArchiveInspector.restore(entries, from: archiveURL, to: destination) }.value
                statusText = text("Wiederherstellung abgeschlossen.", "Restore completed.")
                NSWorkspace.shared.activateFileViewerSelecting([destination])
            } catch {
                statusText = error.localizedDescription
            }
        }
    }
}
