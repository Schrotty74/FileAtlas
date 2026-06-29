//
//  ContentView_FrostedVivid.swift
//  FileIndexer Design Exploration — Vorschlag 5 „Frosted Vivid"
//
//  Reine Design-Shell mit statischen Daten. Keine funktionale Logik.
//

import SwiftUI

// MARK: - Statische Demo-Daten

private struct FrostedVividFile: Identifiable {
    let id = UUID()
    let name: String
    let size: String
    let modified: String
    let icon: String
    let kind: String
}

private let frostedVividFiles: [FrostedVividFile] = [
    .init(name: "Launch Trailer.mov",   size: "248 MB", modified: "Today, 10:02",     icon: "film",              kind: "QuickTime Movie"),
    .init(name: "App Icon.png",         size: "1.2 MB", modified: "Today, 08:30",     icon: "app.gift",          kind: "PNG Image"),
    .init(name: "Pitch Deck.key",       size: "34 MB",  modified: "Yesterday, 21:14", icon: "rectangle.on.rectangle", kind: "Keynote"),
    .init(name: "Soundtrack.wav",       size: "56 MB",  modified: "14 Jun 2026",      icon: "waveform",          kind: "Audio"),
    .init(name: "Screenshots.zip",      size: "18 MB",  modified: "12 Jun 2026",      icon: "photo.stack",       kind: "ZIP Archive"),
    .init(name: "Roadmap.pdf",          size: "2.0 MB", modified: "10 Jun 2026",      icon: "map",               kind: "PDF Document"),
    .init(name: "Brand Colors.svg",     size: "84 KB",  modified: "08 Jun 2026",      icon: "paintpalette",      kind: "Vector Graphic"),
]

// MARK: - Hauptansicht

struct ContentView_FrostedVivid: View {

    @State private var selection: FrostedVividFile.ID? = frostedVividFiles.first?.id
    @State private var search = ""

    private let theme = FrostedVividTheme.theme

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 220, ideal: 250, max: 310)
        } content: {
            fileList
                .navigationSplitViewColumnWidth(min: 380, ideal: 500, max: 740)
        } detail: {
            detail
                .navigationSplitViewColumnWidth(min: 290, ideal: 330, max: 430)
        }
        .navigationTitle("Library")
        .searchable(text: $search, placement: .toolbar, prompt: "Search everything")
        .preferredColorScheme(.dark)
    }

    // MARK: Sidebar — maximales Frosted Glass über lebendigem Wallpaper

    private var sidebar: some View {
        ZStack {
            // Wallpaper scheint stark durch das Frosted Glass.
            FrostedVividTheme.wallpaper

            VStack(alignment: .leading, spacing: 0) {
                Text("FileIndexer")
                    .font(.largeTitle.weight(.heavy))      // fette Headings in der Sidebar
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.top, 24)
                    .padding(.bottom, 20)

                sidebarGroup(title: "BROWSE", rows: [
                    ("All Files", "square.stack.3d.up.fill"),
                    ("Recents", "clock.fill"),
                    ("Shared", "person.2.fill"),
                ])

                sidebarGroup(title: "SMART", rows: [
                    ("Large Files", "arrow.up.right.circle.fill"),
                    ("Media", "play.rectangle.fill"),
                    ("Downloads", "arrow.down.circle.fill"),
                ])

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(.ultraThinMaterial)            // maximales Frosted Glass
        }
    }

    private func sidebarGroup(title: String, rows: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption.weight(.bold))
                .tracking(1.0)
                .foregroundStyle(.white.opacity(0.7))
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, 6)

            ForEach(rows, id: \.0) { row in
                HStack(spacing: 12) {
                    Image(systemName: row.1)
                        .font(.system(size: 15))
                        .foregroundStyle(.white)
                        .frame(width: 22)
                    Text(row.0)
                        .font(.body.weight(.medium))      // schlanker als die Headings, aber kräftig
                        .foregroundStyle(.white)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .frame(height: 42)
            }
        }
    }

    // MARK: Dateiliste — kräftige Auswahl mit Glow

    private var fileList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(frostedVividFiles) { file in
                    let isSelected = file.id == selection
                    HStack(spacing: 14) {
                        Image(systemName: file.icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(isSelected ? .white : theme.accentColor)
                            .frame(width: 30)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(file.name)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(isSelected ? .white : FrostedVividTheme.textPrimary)
                            Text("\(file.kind) · \(file.size)")
                                .font(.caption)
                                .foregroundStyle(isSelected ? .white.opacity(0.85) : FrostedVividTheme.textSecondary)
                        }
                        Spacer()
                        Text(file.modified)
                            .font(.callout)
                            .foregroundStyle(isSelected ? .white.opacity(0.9) : FrostedVividTheme.textSecondary)
                    }
                    .padding(.horizontal, 16)
                    .frame(height: theme.rowHeight)
                    .background {
                        if isSelected {
                            RoundedRectangle(cornerRadius: theme.cornerRadius)
                                .fill(
                                    LinearGradient(
                                        colors: [theme.accentColor, theme.secondaryColor],
                                        startPoint: .leading, endPoint: .trailing
                                    )
                                )
                                // leichter Glow-Effekt rund um die aktive Auswahl
                                .shadow(color: theme.accentColor.opacity(0.7), radius: 14, y: 0)
                        } else {
                            RoundedRectangle(cornerRadius: theme.cornerRadius)
                                .fill(FrostedVividTheme.surfaceRaised)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { selection = file.id }
                }
            }
            .padding(18)
        }
        .background(FrostedVividTheme.surface)
    }

    // MARK: Detail-Panel

    private var detail: some View {
        let file = frostedVividFiles.first { $0.id == selection }
        return ScrollView {
            if let file {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Spacer()
                        Image(systemName: file.icon)
                            .font(.system(size: 52, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 110, height: 110)
                            .background(
                                LinearGradient(
                                    colors: [theme.accentColor, theme.secondaryColor],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ),
                                in: .rect(cornerRadius: 24)
                            )
                            .shadow(color: theme.accentColor.opacity(0.6), radius: 18, y: 6)
                        Spacer()
                    }
                    .padding(.top, 8)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(file.name)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(FrostedVividTheme.textPrimary)
                        Text(file.kind)
                            .font(.subheadline)
                            .foregroundStyle(FrostedVividTheme.textSecondary)
                    }

                    VStack(spacing: 12) {
                        metaRow("Size", file.size)
                        metaRow("Modified", file.modified)
                        metaRow("Tags", "Featured")
                        metaRow("Location", "FileIndexer › Library")
                    }
                    .padding(16)
                    .background(FrostedVividTheme.surfaceRaised, in: .rect(cornerRadius: theme.cornerRadius))

                    Spacer()
                }
                .padding(20)
            } else {
                Text("Pick a file")
                    .font(.callout)
                    .foregroundStyle(FrostedVividTheme.textSecondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(FrostedVividTheme.surface)
    }

    private func metaRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(FrostedVividTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(FrostedVividTheme.textPrimary)
        }
    }
}

// MARK: - Preview

#Preview("Design 5 — Frosted Vivid") {
    ContentView_FrostedVivid()
        .frame(width: 1200, height: 800)
}
