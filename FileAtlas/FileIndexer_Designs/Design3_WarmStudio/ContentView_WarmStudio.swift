//
//  ContentView_WarmStudio.swift
//  FileIndexer Design Exploration — Vorschlag 3 „Warm Studio"
//
//  Reine Design-Shell mit statischen Daten. Keine funktionale Logik.
//

import SwiftUI

// MARK: - Statische Demo-Daten

private struct WarmStudioFile: Identifiable {
    let id = UUID()
    let name: String
    let size: String
    let modified: String
    let icon: String
    let kind: String
    let swatch: Color          // steht für die Thumbnail-Vorschau
}

private let warmStudioFiles: [WarmStudioFile] = [
    .init(name: "Sunset_Beach.RAW",   size: "48.2 MB", modified: "14 Jun 2026", icon: "camera.aperture",  kind: "RAW Photo",     swatch: Color(red: 0.97, green: 0.62, blue: 0.31)),
    .init(name: "Logo_v3.sketch",     size: "6.4 MB",  modified: "13 Jun 2026", icon: "pencil.and.outline", kind: "Sketch File", swatch: Color(red: 0.92, green: 0.45, blue: 0.36)),
    .init(name: "Portrait_Anna.psd",  size: "112 MB",  modified: "11 Jun 2026", icon: "person.crop.square", kind: "Photoshop",   swatch: Color(red: 0.85, green: 0.55, blue: 0.45)),
    .init(name: "Moodboard.pdf",      size: "8.1 MB",  modified: "09 Jun 2026", icon: "square.grid.2x2",   kind: "PDF",          swatch: Color(red: 0.96, green: 0.74, blue: 0.42)),
    .init(name: "Hero_Shot.jpg",      size: "5.7 MB",  modified: "07 Jun 2026", icon: "photo",             kind: "JPEG Image",   swatch: Color(red: 0.80, green: 0.50, blue: 0.30)),
    .init(name: "Palette_Autumn.aco", size: "24 KB",   modified: "04 Jun 2026", icon: "paintpalette",      kind: "Color Swatches", swatch: Color(red: 0.88, green: 0.60, blue: 0.28)),
]

// MARK: - Hauptansicht

struct ContentView_WarmStudio: View {

    @State private var selection: WarmStudioFile.ID? = warmStudioFiles.first?.id
    @State private var search = ""

    private let theme = WarmStudioTheme.theme

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 220, ideal: 250, max: 300)
        } content: {
            fileList
                .navigationSplitViewColumnWidth(min: 400, ideal: 520, max: 760)
        } detail: {
            detail
                .navigationSplitViewColumnWidth(min: 300, ideal: 340, max: 440)
        }
        .navigationTitle("Studio")
        .searchable(text: $search, placement: .toolbar, prompt: "Search assets")
    }

    // MARK: Sidebar — mittleres Glas mit warmem Tint

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                Text("FileIndexer")
                    .fontDesign(.rounded)
            }
            .font(.title3.weight(.bold))
            .foregroundStyle(theme.accentColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular.tint(theme.accentColor.opacity(0.18)), in: .rect(cornerRadius: theme.cornerRadius))
            .padding(12)

            sidebarGroup(title: "Collections", rows: [
                ("All Assets", "square.stack.3d.up"),
                ("Photos", "photo.on.rectangle"),
                ("Designs", "paintbrush.pointed"),
                ("Palettes", "paintpalette"),
            ])

            sidebarGroup(title: "Projects", rows: [
                ("Autumn Campaign", "leaf"),
                ("Brand Refresh", "wand.and.stars"),
            ])

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(WarmStudioTheme.warmTint.opacity(0.4))
        .background(.regularMaterial)
        .background(WarmStudioTheme.windowBackground)
    }

    private func sidebarGroup(title: String, rows: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption.weight(.semibold))
                .fontDesign(.rounded)
                .foregroundStyle(theme.secondaryColor)
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 6)

            ForEach(rows, id: \.0) { row in
                HStack(spacing: 12) {
                    Image(systemName: row.1)
                        .font(.system(size: 16))
                        .foregroundStyle(theme.accentColor)
                        .frame(width: 22)
                    Text(row.0)
                        .font(.body)
                        .fontDesign(.rounded)
                        .foregroundStyle(WarmStudioTheme.textPrimary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .frame(height: 40)
            }
        }
    }

    // MARK: Dateiliste — prominente Thumbnails, große Icons

    private var fileList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(warmStudioFiles) { file in
                    let isSelected = file.id == selection
                    HStack(spacing: 16) {
                        // Vorschau-Thumbnail (Platzhalter-Swatch)
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [file.swatch, file.swatch.opacity(0.55)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                            .overlay {
                                Image(systemName: file.icon)
                                    .font(.system(size: 22))
                                    .foregroundStyle(.white.opacity(0.95))
                            }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(file.name)
                                .font(.body.weight(.semibold))
                                .fontDesign(.rounded)
                                .foregroundStyle(WarmStudioTheme.textPrimary)
                            Text("\(file.kind) · \(file.size)")
                                .font(.subheadline)
                                .fontDesign(.rounded)
                                .foregroundStyle(WarmStudioTheme.textSecondary)
                        }
                        Spacer()
                        Text(file.modified)
                            .font(.callout)
                            .fontDesign(.rounded)
                            .foregroundStyle(WarmStudioTheme.textSecondary)
                    }
                    .padding(12)
                    .frame(height: theme.rowHeight + 16)
                    .background(
                        RoundedRectangle(cornerRadius: theme.cornerRadius)
                            .fill(isSelected ? theme.accentColor.opacity(0.16) : WarmStudioTheme.surfaceRaised)
                            .shadow(color: .black.opacity(isSelected ? 0.08 : 0.04), radius: isSelected ? 8 : 3, y: 2)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture { selection = file.id }
                }
            }
            .padding(18)
        }
        .background(WarmStudioTheme.surface)
    }

    // MARK: Detail-Panel

    private var detail: some View {
        let file = warmStudioFiles.first { $0.id == selection }
        return ScrollView {
            if let file {
                VStack(alignment: .leading, spacing: 20) {
                    RoundedRectangle(cornerRadius: theme.cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [file.swatch, file.swatch.opacity(0.5)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 180)
                        .overlay {
                            Image(systemName: file.icon)
                                .font(.system(size: 56))
                                .foregroundStyle(.white.opacity(0.95))
                        }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(file.name)
                            .font(.title3.weight(.bold))
                            .fontDesign(.rounded)
                            .foregroundStyle(WarmStudioTheme.textPrimary)
                        Text(file.kind)
                            .font(.subheadline)
                            .fontDesign(.rounded)
                            .foregroundStyle(WarmStudioTheme.textSecondary)
                    }

                    VStack(spacing: 12) {
                        metaRow("Size", file.size)
                        metaRow("Modified", file.modified)
                        metaRow("Dimensions", "4032 × 3024")
                        metaRow("Color Profile", "Display P3")
                    }
                    .padding(16)
                    .background(WarmStudioTheme.surfaceRaised, in: .rect(cornerRadius: theme.cornerRadius))

                    Spacer()
                }
                .padding(20)
            } else {
                Text("Select an asset")
                    .font(.callout)
                    .fontDesign(.rounded)
                    .foregroundStyle(WarmStudioTheme.textSecondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(WarmStudioTheme.surface)
    }

    private func metaRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .fontDesign(.rounded)
                .foregroundStyle(WarmStudioTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .fontDesign(.rounded)
                .foregroundStyle(WarmStudioTheme.textPrimary)
        }
    }
}

// MARK: - Preview

#Preview("Design 3 — Warm Studio") {
    ContentView_WarmStudio()
        .frame(width: 1200, height: 800)
}
