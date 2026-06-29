//
//  ContentView_MidnightTeal.swift
//  FileIndexer Design Exploration — Vorschlag 4 „Midnight Teal"
//
//  Reine Design-Shell mit statischen Daten. Keine funktionale Logik.
//

import SwiftUI

// MARK: - Statische Demo-Daten

private struct MidnightTealFile: Identifiable {
    let id = UUID()
    let name: String
    let size: String
    let modified: String
    let icon: String
    let kind: String
    let status: String          // Status-Badge (gold hervorgehoben)
}

private let midnightTealFiles: [MidnightTealFile] = [
    .init(name: "Q4_Forecast.xlsx",      size: "1.8 MB",  modified: "16 Jun 2026 08:40", icon: "chart.bar.doc.horizontal", kind: "Spreadsheet", status: "Final"),
    .init(name: "Revenue_2025.csv",      size: "9.2 MB",  modified: "15 Jun 2026 19:11", icon: "tablecells",               kind: "Dataset",     status: "Review"),
    .init(name: "Audit_Report.pdf",      size: "3.4 MB",  modified: "15 Jun 2026 11:02", icon: "doc.text.magnifyingglass", kind: "PDF",         status: "Locked"),
    .init(name: "Cashflow_Model.numbers", size: "780 KB", modified: "14 Jun 2026 16:55", icon: "function",                 kind: "Model",       status: "Draft"),
    .init(name: "Investor_Deck.key",     size: "22 MB",   modified: "13 Jun 2026 09:30", icon: "rectangle.on.rectangle",   kind: "Keynote",     status: "Final"),
    .init(name: "Tax_2024.pdf",          size: "1.1 MB",  modified: "11 Jun 2026 14:20", icon: "doc.richtext",             kind: "PDF",         status: "Archived"),
    .init(name: "Ledger_June.csv",       size: "4.7 MB",  modified: "10 Jun 2026 22:48", icon: "tablecells",               kind: "Dataset",     status: "Review"),
    .init(name: "KPIs_Weekly.xlsx",      size: "512 KB",  modified: "09 Jun 2026 07:05", icon: "chart.line.uptrend.xyaxis", kind: "Spreadsheet", status: "Draft"),
]

// MARK: - Hauptansicht

struct ContentView_MidnightTeal: View {

    @State private var selection: MidnightTealFile.ID? = midnightTealFiles.first?.id
    @State private var search = ""

    private let theme = MidnightTealTheme.theme

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 270)
        } content: {
            fileList
                .navigationSplitViewColumnWidth(min: 420, ideal: 560, max: 800)
        } detail: {
            detail
                .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 420)
        }
        .navigationTitle("Finance")
        .searchable(text: $search, placement: .toolbar, prompt: "Filter records")
        .preferredColorScheme(.dark)
    }

    // MARK: Sidebar — dunkles Glas mit Teal-Tint

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "chart.pie.fill")
                Text("FileIndexer")
            }
            .font(.headline)
            .foregroundStyle(theme.accentColor)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular.tint(theme.accentColor.opacity(0.22)), in: .rect(cornerRadius: theme.cornerRadius))
            .padding(10)

            sidebarGroup(title: "WORKSPACES", rows: [
                ("All Records", "square.grid.3x3"),
                ("Reports", "doc.text"),
                ("Datasets", "tablecells"),
                ("Models", "function"),
            ])

            sidebarGroup(title: "STATUS", rows: [
                ("Final", "checkmark.seal.fill"),
                ("In Review", "clock.badge"),
                ("Archived", "archivebox.fill"),
            ])

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(theme.accentColor.opacity(0.06))
        .background(MidnightTealTheme.surface)
    }

    private func sidebarGroup(title: String, rows: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .tracking(0.6)
                .foregroundStyle(theme.secondaryColor)
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 5)

            ForEach(rows, id: \.0) { row in
                HStack(spacing: 10) {
                    Image(systemName: row.1)
                        .font(.system(size: 12))
                        .foregroundStyle(theme.accentColor)
                        .frame(width: 18)
                    Text(row.0)
                        .font(.callout)
                        .foregroundStyle(MidnightTealTheme.textPrimary)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .frame(height: 30)
            }
        }
    }

    // MARK: Dateiliste — maximale Informationsdichte, enges Tracking

    private var fileList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Tabellenkopf
                HStack(spacing: 0) {
                    Text("NAME").frame(maxWidth: .infinity, alignment: .leading)
                    Text("KIND").frame(width: 90, alignment: .leading)
                    Text("STATUS").frame(width: 80, alignment: .leading)
                    Text("SIZE").frame(width: 70, alignment: .trailing)
                    Text("MODIFIED").frame(width: 130, alignment: .trailing)
                }
                .font(.caption2.weight(.semibold))
                .tracking(0.4)
                .foregroundStyle(theme.secondaryColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)

                Rectangle().fill(MidnightTealTheme.stroke).frame(height: 1)

                ForEach(Array(midnightTealFiles.enumerated()), id: \.element.id) { index, file in
                    let isSelected = file.id == selection
                    HStack(spacing: 0) {
                        HStack(spacing: 8) {
                            Image(systemName: file.icon)
                                .font(.system(size: 12))
                                .foregroundStyle(theme.accentColor)
                            Text(file.name)
                                .font(.callout)
                                .tracking(-0.2)
                                .foregroundStyle(MidnightTealTheme.textPrimary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Text(file.kind)
                            .font(.caption)
                            .foregroundStyle(MidnightTealTheme.textSecondary)
                            .frame(width: 90, alignment: .leading)

                        statusBadge(file.status)
                            .frame(width: 80, alignment: .leading)

                        Text(file.size)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(MidnightTealTheme.textSecondary)
                            .frame(width: 70, alignment: .trailing)

                        Text(file.modified)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(MidnightTealTheme.textSecondary)
                            .frame(width: 130, alignment: .trailing)
                    }
                    .padding(.horizontal, 14)
                    .frame(height: theme.rowHeight)
                    .background(
                        isSelected
                            ? theme.accentColor.opacity(0.16)
                            : (index.isMultiple(of: 2) ? .clear : Color.white.opacity(0.02))
                    )
                    .contentShape(Rectangle())
                    .onTapGesture { selection = file.id }
                }
            }
        }
        .background(MidnightTealTheme.windowBackground)
    }

    private func statusBadge(_ status: String) -> some View {
        let isHighlighted = (status == "Final" || status == "Locked")
        return Text(status)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(isHighlighted ? MidnightTealTheme.gold : theme.secondaryColor)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(
                Capsule().fill(
                    isHighlighted
                        ? MidnightTealTheme.gold.opacity(0.15)
                        : theme.secondaryColor.opacity(0.12)
                )
            )
    }

    // MARK: Detail-Panel

    private var detail: some View {
        let file = midnightTealFiles.first { $0.id == selection }
        return ScrollView {
            if let file {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: file.icon)
                            .font(.system(size: 26))
                            .foregroundStyle(theme.accentColor)
                            .frame(width: 50, height: 50)
                            .background(MidnightTealTheme.surfaceRaised, in: .rect(cornerRadius: 10))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(file.name)
                                .font(.headline)
                                .tracking(-0.2)
                                .foregroundStyle(MidnightTealTheme.textPrimary)
                            statusBadge(file.status)
                        }
                    }

                    Divider().overlay(MidnightTealTheme.stroke)

                    VStack(spacing: 10) {
                        metaRow("Kind", file.kind)
                        metaRow("Size", file.size)
                        metaRow("Modified", file.modified)
                        metaRow("Owner", "Finance")
                        metaRow("Encryption", "AES-256")
                    }
                    .padding(14)
                    .background(MidnightTealTheme.surfaceRaised, in: .rect(cornerRadius: theme.cornerRadius))

                    Spacer()
                }
                .padding(18)
            } else {
                Text("No record selected")
                    .font(.callout)
                    .foregroundStyle(MidnightTealTheme.textSecondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(MidnightTealTheme.surface)
    }

    private func metaRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(MidnightTealTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.caption.weight(.medium))
                .foregroundStyle(MidnightTealTheme.textPrimary)
        }
    }
}

// MARK: - Preview

#Preview("Design 4 — Midnight Teal") {
    ContentView_MidnightTeal()
        .frame(width: 1200, height: 800)
}
