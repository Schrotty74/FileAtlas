//
//  ContentView_CleanLight.swift
//  FileIndexer Design Exploration — Vorschlag 2 „Clean Light"
//
//  Reine Design-Shell mit statischen Daten. Keine funktionale Logik.
//

import SwiftUI

// MARK: - Statische Demo-Daten

private struct CleanLightFile: Identifiable {
    let id = UUID()
    let name: String
    let size: String
    let modified: String
    let icon: String
    let kind: String
}

private let cleanLightFiles: [CleanLightFile] = [
    .init(name: "Meeting Notes.md",       size: "12 KB",  modified: "Today, 09:24",     icon: "doc.text",        kind: "Markdown Document"),
    .init(name: "Q3 Report.pages",        size: "2.4 MB", modified: "Yesterday, 16:10", icon: "doc.richtext",    kind: "Pages Document"),
    .init(name: "Household Budget.numbers", size: "640 KB", modified: "14 Jun 2026",    icon: "tablecells",      kind: "Numbers Spreadsheet"),
    .init(name: "Reading List.txt",       size: "3 KB",   modified: "12 Jun 2026",      icon: "doc.plaintext",   kind: "Plain Text"),
    .init(name: "Travel Itinerary.pdf",   size: "880 KB", modified: "09 Jun 2026",      icon: "doc",             kind: "PDF Document"),
    .init(name: "Sourdough Recipe.md",    size: "8 KB",   modified: "05 Jun 2026",      icon: "doc.text",        kind: "Markdown Document"),
    .init(name: "Garden Plan.rtf",        size: "21 KB",  modified: "01 Jun 2026",      icon: "doc.richtext",    kind: "Rich Text"),
]

// MARK: - Hauptansicht

struct ContentView_CleanLight: View {

    @State private var selection: CleanLightFile.ID? = cleanLightFiles.first?.id
    @State private var search = ""

    private let theme = CleanLightTheme.theme

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 210, ideal: 240, max: 300)
        } content: {
            fileList
                .navigationSplitViewColumnWidth(min: 360, ideal: 480, max: 720)
        } detail: {
            detail
                .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 420)
        }
        .navigationTitle("Documents")
        .searchable(text: $search, placement: .toolbar, prompt: "Search documents")
        .preferredColorScheme(.light)
    }

    // MARK: Sidebar — maximale Transparenz, kaum sichtbar

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "doc.on.doc")
                Text("FileIndexer")
            }
            .font(.title3.weight(.semibold))
            .foregroundStyle(theme.accentColor)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            // Bewusst minimaler Glas-Einsatz: klares Glas, kaum wahrnehmbar.
            .glassEffect(.clear, in: .rect(cornerRadius: theme.cornerRadius))
            .padding(.horizontal, 14)
            .padding(.top, 18)
            .padding(.bottom, 10)

            sidebarGroup(title: "Library", rows: [
                ("All Documents", "tray.full"),
                ("Recents", "clock"),
                ("Favorites", "star"),
            ])

            sidebarGroup(title: "Folders", rows: [
                ("Work", "folder"),
                ("Personal", "folder"),
                ("Archive", "archivebox"),
            ])

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.ultraThinMaterial)          // verschmilzt mit dem Hintergrund
        .background(CleanLightTheme.windowBackground)
    }

    private func sidebarGroup(title: String, rows: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.secondaryColor)
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, 6)

            ForEach(rows, id: \.0) { row in
                HStack(spacing: 12) {
                    Image(systemName: row.1)
                        .font(.system(size: 14))
                        .foregroundStyle(theme.accentColor.opacity(0.9))
                        .frame(width: 20)
                    Text(row.0)
                        .font(.body)
                        .foregroundStyle(CleanLightTheme.textPrimary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .frame(height: 38)
            }
        }
    }

    // MARK: Dateiliste — keine Trennlinien, nur Abstände & Graustufen

    private var fileList: some View {
        ScrollView {
            LazyVStack(spacing: 6) {
                ForEach(cleanLightFiles) { file in
                    let isSelected = file.id == selection
                    HStack(spacing: 14) {
                        Image(systemName: file.icon)
                            .font(.system(size: 18))
                            .foregroundStyle(theme.accentColor)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(file.name)
                                .font(.body)
                                .foregroundStyle(CleanLightTheme.textPrimary)
                            Text(file.kind)
                                .font(.caption)
                                .foregroundStyle(CleanLightTheme.textSecondary)
                        }
                        Spacer()
                        Text(file.modified)
                            .font(.callout)
                            .foregroundStyle(CleanLightTheme.textSecondary)
                    }
                    .padding(.horizontal, 16)
                    .frame(height: theme.rowHeight)
                    .background(
                        RoundedRectangle(cornerRadius: theme.cornerRadius)
                            .fill(isSelected ? theme.accentColor.opacity(0.10) : .clear)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture { selection = file.id }
                }
            }
            .padding(18)
        }
        .background(CleanLightTheme.surface)
    }

    // MARK: Detail-Panel

    private var detail: some View {
        let file = cleanLightFiles.first { $0.id == selection }
        return ScrollView {
            if let file {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 14) {
                        Image(systemName: file.icon)
                            .font(.system(size: 40, weight: .light))
                            .foregroundStyle(theme.accentColor)
                        Text(file.name)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(CleanLightTheme.textPrimary)
                        Text(file.kind)
                            .font(.subheadline)
                            .foregroundStyle(CleanLightTheme.textSecondary)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        metaRow("Size", file.size)
                        metaRow("Modified", file.modified)
                        metaRow("Where", "iCloud Drive › Documents")
                        metaRow("Shared", "Just me")
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(CleanLightTheme.surfaceSubtle, in: .rect(cornerRadius: theme.cornerRadius))

                    Spacer()
                }
                .padding(24)
            } else {
                Text("Select a document")
                    .font(.callout)
                    .foregroundStyle(CleanLightTheme.textSecondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(CleanLightTheme.surface)
    }

    private func metaRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(CleanLightTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(CleanLightTheme.textPrimary)
        }
    }
}

// MARK: - Preview

#Preview("Design 2 — Clean Light") {
    ContentView_CleanLight()
        .frame(width: 1200, height: 800)
}
