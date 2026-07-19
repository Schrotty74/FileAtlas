//
//  StorageAnalysisView.swift
//  FileAtlas
//

import SwiftUI
import AppKit

struct StorageAnalysisView: View {
    @Environment(IndexViewModel.self) private var vm
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
        .frame(width: 640, height: 560)
        .task { hasAppeared = true }
    }

    private var isMotionEnabled: Bool {
        !motion.reduceMotion && !systemReduceMotion
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
