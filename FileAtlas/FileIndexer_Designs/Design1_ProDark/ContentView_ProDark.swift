//
//  ContentView_ProDark.swift
//  FileIndexer Design Exploration — Vorschlag 1 „Pro Dark"
//
//  Reine Design-Shell mit statischen Daten. Keine funktionale Logik.
//  Beschreibung siehe README.md im selben Ordner.
//

import SwiftUI

// MARK: - Statische Demo-Daten

private struct ProDarkFile: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let size: String
    let modified: String
    let icon: String
    let kind: String
}

private let proDarkFiles: [ProDarkFile] = [
    .init(name: "main.swift",       path: "~/dev/atlas/Sources/App", size: "4.2 KB",   modified: "2026-06-14 09:12", icon: "swift",                                    kind: "Swift Source"),
    .init(name: "AtlasIndexer.swift", path: "~/dev/atlas/Sources/Core", size: "18.7 KB", modified: "2026-06-14 08:51", icon: "swift",                                  kind: "Swift Source"),
    .init(name: "Package.resolved", path: "~/dev/atlas",            size: "2.1 KB",   modified: "2026-06-11 17:03", icon: "shippingbox.fill",                         kind: "SPM Lockfile"),
    .init(name: "config.yaml",      path: "~/dev/atlas/Config",     size: "812 B",    modified: "2026-06-10 11:48", icon: "doc.badge.gearshape",                      kind: "YAML"),
    .init(name: "dataset.csv",      path: "~/dev/atlas/Data",       size: "44.9 MB",  modified: "2026-06-09 22:17", icon: "tablecells",                               kind: "CSV"),
    .init(name: "build.log",        path: "~/dev/atlas/.build",     size: "320 KB",   modified: "2026-06-15 14:02", icon: "doc.text.fill",                            kind: "Log"),
    .init(name: "Dockerfile",       path: "~/dev/atlas",            size: "1.4 KB",   modified: "2026-06-08 10:30", icon: "cube.transparent",                         kind: "Dockerfile"),
]

// MARK: - Hauptansicht

struct ContentView_ProDark: View {

    @State private var selection: ProDarkFile.ID? = proDarkFiles.first?.id
    @State private var search = ""

    private let theme = ProDarkTheme.theme

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 200, ideal: 224, max: 280)
        } content: {
            fileList
                .navigationSplitViewColumnWidth(min: 380, ideal: 500, max: 720)
        } detail: {
            detail
                .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 420)
        }
        .navigationTitle("FileIndexer")
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("~/dev/atlas")
                    .font(.system(.callout, design: .monospaced))
                    .foregroundStyle(ProDarkTheme.textSecondary)
            }
            ToolbarItem {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .foregroundStyle(theme.accentColor)
            }
        }
        .searchable(text: $search, placement: .toolbar, prompt: "grep files…")
        .preferredColorScheme(.dark)
    }

    // MARK: Sidebar — sehr dunkles, fast opakes Glas

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "terminal.fill")
                Text("FileIndexer")
                    .font(.system(.headline, design: .monospaced))
            }
            .foregroundStyle(theme.accentColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                ProDarkTheme.surfaceRaised.opacity(0.6),
                in: .rect(cornerRadius: theme.cornerRadius)
            )
            .glassEffect(.regular.tint(.black.opacity(0.35)), in: .rect(cornerRadius: theme.cornerRadius))
            .padding(10)

            sidebarSection(title: "LOCATIONS", rows: [
                ("Project", "folder.fill"),
                ("Sources", "chevron.left.forwardslash.chevron.right"),
                ("Build", "hammer.fill"),
                ("Logs", "doc.text.fill"),
            ])

            sidebarSection(title: "TAGS", rows: [
                ("Modified", "circle.fill"),
                ("Staged", "circle.fill"),
                ("Ignored", "circle.fill"),
            ])

            Spacer()

            HStack(spacing: 6) {
                Circle().fill(theme.accentColor).frame(width: 7, height: 7)
                Text("indexed 1,284 files")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(ProDarkTheme.textSecondary)
            }
            .padding(12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(ProDarkTheme.surface)
    }

    private func sidebarSection(title: String, rows: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title)
                .font(.system(.caption2, design: .monospaced).weight(.semibold))
                .foregroundStyle(ProDarkTheme.textSecondary)
                .padding(.horizontal, 14)
                .padding(.top, 14)
                .padding(.bottom, 4)

            ForEach(rows, id: \.0) { row in
                HStack(spacing: 8) {
                    Image(systemName: row.1)
                        .font(.system(size: 11))
                        .foregroundStyle(theme.accentColor.opacity(0.85))
                        .frame(width: 16)
                    Text(row.0)
                        .font(.system(.callout, design: .monospaced))
                        .foregroundStyle(ProDarkTheme.textPrimary)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .frame(height: theme.rowHeight)
            }
        }
    }

    // MARK: Dateiliste — monospaced wie ein Terminal

    private var fileList: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                HStack {
                    Text("NAME").frame(maxWidth: .infinity, alignment: .leading)
                    Text("SIZE").frame(width: 80, alignment: .trailing)
                    Text("MODIFIED").frame(width: 150, alignment: .trailing)
                }
                .font(.system(.caption2, design: .monospaced).weight(.semibold))
                .foregroundStyle(ProDarkTheme.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)

                ForEach(proDarkFiles) { file in
                    let isSelected = file.id == selection
                    HStack(spacing: 10) {
                        Image(systemName: file.icon)
                            .font(.system(size: 13))
                            .foregroundStyle(isSelected ? theme.accentColor : ProDarkTheme.textSecondary)
                            .frame(width: 18)
                        Text(file.name)
                            .font(.system(.callout, design: .monospaced))
                            .foregroundStyle(ProDarkTheme.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(file.size)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(ProDarkTheme.textSecondary)
                            .frame(width: 80, alignment: .trailing)
                        Text(file.modified)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(ProDarkTheme.textSecondary)
                            .frame(width: 150, alignment: .trailing)
                    }
                    .padding(.horizontal, 14)
                    .frame(height: theme.rowHeight + 4)
                    .background(
                        RoundedRectangle(cornerRadius: theme.cornerRadius)
                            .fill(isSelected ? theme.accentColor.opacity(0.14) : .clear)
                            .overlay(alignment: .leading) {
                                if isSelected {
                                    Rectangle()
                                        .fill(theme.accentColor)
                                        .frame(width: 2)
                                }
                            }
                    )
                    .contentShape(Rectangle())
                    .onTapGesture { selection = file.id }
                    .padding(.horizontal, 6)
                }
            }
            .padding(.vertical, 6)
        }
        .background(ProDarkTheme.windowBackground)
    }

    // MARK: Detail-Panel

    private var detail: some View {
        let file = proDarkFiles.first { $0.id == selection }
        return ScrollView {
            if let file {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 12) {
                        Image(systemName: file.icon)
                            .font(.system(size: 30))
                            .foregroundStyle(theme.accentColor)
                            .frame(width: 54, height: 54)
                            .background(ProDarkTheme.surfaceRaised, in: .rect(cornerRadius: 10))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(file.name)
                                .font(.system(.title3, design: .monospaced).weight(.medium))
                                .foregroundStyle(ProDarkTheme.textPrimary)
                            Text(file.kind)
                                .font(.system(.caption, design: .default))
                                .foregroundStyle(ProDarkTheme.textSecondary)
                        }
                    }

                    Divider().overlay(ProDarkTheme.stroke)

                    metaRow("PATH", file.path)
                    metaRow("SIZE", file.size)
                    metaRow("MODIFIED", file.modified)
                    metaRow("KIND", file.kind)
                    metaRow("PERMISSIONS", "rw-r--r--")

                    Spacer()
                }
                .padding(20)
            } else {
                Text("No selection")
                    .font(.system(.callout, design: .monospaced))
                    .foregroundStyle(ProDarkTheme.textSecondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(ProDarkTheme.surface)
    }

    private func metaRow(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(.caption2, design: .monospaced).weight(.semibold))
                .foregroundStyle(ProDarkTheme.textSecondary)
            Text(value)
                .font(.system(.callout, design: .monospaced))
                .foregroundStyle(theme.accentColor)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview

#Preview("Design 1 — Pro Dark") {
    ContentView_ProDark()
        .frame(width: 1200, height: 800)
}
