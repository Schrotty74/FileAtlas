//
//  StorageAnalysisView.swift
//  FileAtlas
//

import SwiftUI
import AppKit

struct StorageAnalysisView: View {
    @Environment(IndexViewModel.self) private var vm
    @Environment(\.dismiss) private var dismiss

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
                        LabeledContent("Indexed items", value: vm.entries.count.formatted())
                        LabeledContent("Indexed size", value: vm.indexedSize.formattedFileSize)
                        LabeledContent("Duplicates", value: vm.duplicateEntries.count.formatted())
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
                        ForEach(vm.storageTypeSummaries) { type in
                            HStack {
                                Text(type.displayName)
                                Spacer()
                                Text("\(type.fileCount) items")
                                    .foregroundStyle(AppTheme.theme.textSecondary)
                                Text(type.totalSize.formattedFileSize)
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(AppTheme.theme.textSecondary)
                            }
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
        .frame(width: 640, height: 560)
    }
}

private extension Int64 {
    var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: self, countStyle: .file)
    }
}
