import SwiftUI
import AppKit

struct SimilarImagesView: View {
    @Environment(IndexViewModel.self) private var vm
    @Environment(LanguageManager.self) private var language
    @Environment(\.dismiss) private var dismiss
    @State private var groups: [SimilarImageGroup] = []
    @State private var isAnalyzing = true

    private func text(_ de: String, _ en: String) -> String {
        language.effectiveLanguage == .de ? de : en
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(text("Aehnliche Bilder", "Similar Images")).font(.headline)
                    Text(text("Lokale Vision-Analyse, maximal 250 Bilder", "On-device Vision analysis, up to 250 images"))
                        .font(.caption).foregroundStyle(AppTheme.theme.textSecondary)
                }
                Spacer()
                Button(text("Fertig", "Done")) { dismiss() }.keyboardShortcut(.defaultAction)
            }
            .padding()
            Divider()

            if isAnalyzing {
                ProgressView(text("Bilder werden verglichen…", "Comparing images…"))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if groups.isEmpty {
                ContentUnavailableView(text("Keine aehnlichen Bilder gefunden", "No similar images found"), systemImage: "photo.on.rectangle")
            } else {
                List(groups) { group in
                    Section(text("\(group.entries.count) aehnliche Bilder", "\(group.entries.count) similar images")) {
                        ForEach(group.entries) { entry in
                            Button {
                                NSWorkspace.shared.activateFileViewerSelecting([entry.path])
                            } label: {
                                HStack {
                                    SystemFileIconView(entry: entry, size: 20, iconDisplayMode: vm.iconDisplayMode)
                                    Text(entry.name).lineLimit(1)
                                    Spacer()
                                    Text(entry.formattedSize).font(.caption.monospacedDigit())
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .frame(width: 620, height: 600)
        .task {
            groups = SimilarImageDetector.groups(in: vm.entries)
            isAnalyzing = false
        }
    }
}
