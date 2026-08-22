//
//  StorageAnalysisView.swift
//  FileAtlas
//

import SwiftUI
import AppKit

struct StorageAnalysisView: View {
    @Environment(IndexViewModel.self) private var vm
    @Environment(BackupManager.self) private var backup
    @Environment(UIState.self) private var ui
    @Environment(LanguageManager.self) private var language
    @Environment(\.dismiss) private var dismiss
    @Environment(MotionPreferences.self) private var motion
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @State private var hasAppeared = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Storage Analysis")
                    .font(.headline)
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding()

            Divider()

            if vm.entries.isEmpty {
                ContentUnavailableView("No indexed items", systemImage: "internaldrive")
            } else {
                List {
                    Section("Overview") {
                        MotionMetricRow("Indexed items", value: vm.entries.count.formatted(), isActive: isMotionEnabled && hasAppeared)
                        MotionMetricRow("Indexed size", value: vm.indexedSize.formattedFileSize, isActive: isMotionEnabled && hasAppeared)
                        MotionMetricRow("Duplicates", value: vm.duplicateEntries.count.formatted(), isActive: isMotionEnabled && hasAppeared)
                    }

                    Section(text("Speicherkarte", "Storage Map")) {
                        StorageTreemap(types: vm.storageTypeSummaries)
                    }

                    Section(text("Gesundheit", "Health")) {
                        let unavailable = vm.scanRoots.filter { !FileManager.default.fileExists(atPath: $0.path(percentEncoded: false)) }
                        let missingDestination = vm.scanRoots.filter { backup.destinationDisplayName(for: $0) == nil }
                        let overdue = vm.scanRoots.filter { backup.config(for: $0).isDue(now: Date()) }
                        HealthMetricRow(title: text("Nicht erreichbare Orte", "Unavailable locations"), value: unavailable.count, symbol: "externaldrive.badge.exclamationmark", color: unavailable.isEmpty ? .green : .orange)
                        HealthMetricRow(title: text("Orte ohne Backup-Ziel", "Locations without backup destination"), value: missingDestination.count, symbol: "externaldrive.badge.questionmark", color: missingDestination.isEmpty ? .green : .orange)
                        HealthMetricRow(title: text("Faellige geplante Sicherungen", "Scheduled backups due"), value: overdue.count, symbol: "clock.badge.exclamationmark", color: overdue.isEmpty ? .green : .orange)
                        HealthMetricRow(title: text("Potenzieller Duplikatspeicher", "Potential duplicate space"), value: vm.duplicateEntries.reduce(Int64(0)) { $0 + $1.size }.formattedFileSize, symbol: "doc.on.doc", color: AppTheme.theme.accentColor)
                    }

                    Section(text("Bildanalyse", "Image Analysis")) {
                        Button {
                            ui.showSimilarImages = true
                        } label: {
                            Label(text("Aehnliche Bilder finden", "Find Similar Images"), systemImage: "photo.on.rectangle.angled")
                        }
                        Text(text("Vergleicht das Aussehen von Bildern lokal. Exakte Duplikate bleiben SHA-256-basiert.", "Compares image appearance locally. Exact duplicates remain handled by SHA-256."))
                            .font(.caption)
                            .foregroundStyle(AppTheme.theme.textSecondary)
                    }

                    Section("Largest Items") {
                        ForEach(vm.largestIndexedEntries) { entry in
                            Button {
                                NSWorkspace.shared.activateFileViewerSelecting([entry.path])
                            } label: {
                                HStack(spacing: 10) {
                                    SystemFileIconView(entry: entry, size: 18, iconDisplayMode: vm.iconDisplayMode)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(entry.name).lineLimit(1)
                                        Text(entry.pathKey)
                                            .font(.caption2)
                                            .foregroundStyle(AppTheme.theme.textSecondary)
                                            .lineLimit(1)
                                            .truncationMode(.middle)
                                    }
                                    Spacer()
                                    Text(entry.formattedSize)
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(AppTheme.theme.textSecondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Section("File Types") {
                        let largestTypeSize = vm.storageTypeSummaries.map(\.totalSize).max() ?? 1
                        ForEach(vm.storageTypeSummaries) { type in
                            StorageTypeMeter(
                                type: type,
                                largestTypeSize: largestTypeSize,
                                isActive: isMotionEnabled && hasAppeared
                            )
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
        .frame(minWidth: 640, minHeight: 600)
        .task { hasAppeared = true }
    }

    private var isMotionEnabled: Bool {
        !motion.reduceMotion && !systemReduceMotion
    }

    private func text(_ de: String, _ en: String) -> String {
        language.effectiveLanguage == .de ? de : en
    }
}

private struct HealthMetricRow<Value: CustomStringConvertible>: View {
    let title: String
    let value: Value
    let symbol: String
    let color: Color

    var body: some View {
        LabeledContent(title) {
            HStack(spacing: 6) {
                Image(systemName: symbol).foregroundStyle(color)
                Text(value.description).font(.body.monospacedDigit())
            }
        }
    }
}

private struct StorageTreemap: View {
    let types: [StorageTypeSummary]

    private var visibleTypes: [StorageTypeSummary] { Array(types.sorted { $0.totalSize > $1.totalSize }.prefix(8)) }
    private let colors: [Color] = [.teal, .blue, .purple, .pink, .orange, .green, .cyan, .yellow]
    private let columns = [
        GridItem(.adaptive(minimum: 145, maximum: 230), spacing: 6, alignment: .leading)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(visibleTypes.indices, id: \.self) { index in
                let type = visibleTypes[index]
                VStack(alignment: .leading, spacing: 5) {
                    Text(type.displayName).font(.caption.bold()).lineLimit(1)
                    Text(type.totalSize.formattedFileSize).font(.caption.monospacedDigit()).lineLimit(1)
                }
                .foregroundStyle(.white)
                .padding(10)
                .frame(maxWidth: .infinity, minHeight: 74, alignment: .topLeading)
                .background(colors[index % colors.count].opacity(0.78), in: RoundedRectangle(cornerRadius: 6))
                .help("\(type.displayName): \(type.totalSize.formattedFileSize)")
            }
        }
    }
}

private struct MotionMetricRow: View {
    let title: LocalizedStringKey
    let value: String
    let isActive: Bool

    init(_ title: LocalizedStringKey, value: String, isActive: Bool) {
        self.title = title
        self.value = value
        self.isActive = isActive
    }

    var body: some View {
        LabeledContent(title) {
            Text(value)
                .font(.body.monospacedDigit())
                .contentTransition(isActive ? .numericText() : .identity)
        }
    }
}

private struct StorageTypeMeter: View {
    let type: StorageTypeSummary
    let largestTypeSize: Int64
    let isActive: Bool

    private var fraction: CGFloat {
        guard largestTypeSize > 0 else { return 0 }
        return CGFloat(type.totalSize) / CGFloat(largestTypeSize)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(type.displayName)
                Spacer()
                Text("\(type.fileCount) items")
                    .foregroundStyle(AppTheme.theme.textSecondary)
                Text(type.totalSize.formattedFileSize)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(AppTheme.theme.textSecondary)
                    .contentTransition(isActive ? .numericText() : .identity)
            }

            GeometryReader { proxy in
                Capsule()
                    .fill(AppTheme.theme.accentColor.opacity(0.22))
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(AppTheme.theme.accentColor)
                            .frame(width: isActive ? proxy.size.width * fraction : 0)
                    }
            }
            .frame(height: 5)
        }
        .padding(.vertical, 2)
        .animation(isActive ? FileAtlasMotion.staged : nil, value: fraction)
    }
}

private extension Int64 {
    var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: self, countStyle: .file)
    }
}
