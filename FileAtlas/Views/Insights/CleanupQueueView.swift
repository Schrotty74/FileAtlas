//
//  CleanupQueueView.swift
//  FileAtlas
//

import SwiftUI
import AppKit

struct CleanupQueueView: View {
    @Environment(IndexViewModel.self) private var vm
    @Environment(\.dismiss) private var dismiss
    @State private var showsTrashConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Cleanup Queue")
                    .font(.headline)
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding()

            Divider()

            if vm.cleanupQueue.isEmpty {
                ContentUnavailableView("Cleanup queue is empty", systemImage: "trash")
            } else {
                List {
                    Section {
                        ForEach(vm.cleanupQueue) { entry in
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
                                Button {
                                    vm.removeFromCleanupQueue(entry)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(AppTheme.theme.textSecondary)
                                .help("Remove from cleanup queue")
                            }
                        }
                    } header: {
                        Text("\(vm.cleanupQueue.count) items · \(ByteCountFormatter.string(fromByteCount: vm.cleanupQueueSize, countStyle: .file))")
                    }
                }
                .listStyle(.inset)
            }

            Divider()

            HStack {
                Button("Empty Queue") { vm.clearCleanupQueue() }
                    .disabled(vm.cleanupQueue.isEmpty)
                Spacer()
                Button(role: .destructive) {
                    showsTrashConfirmation = true
                } label: {
                    Label("Move to Trash", systemImage: "trash")
                }
                .disabled(vm.cleanupQueue.isEmpty)
            }
            .padding()
        }
        .frame(width: 640, height: 520)
        .confirmationDialog(
            "Move \(vm.cleanupQueue.count) items to Trash?",
            isPresented: $showsTrashConfirmation,
            titleVisibility: .visible
        ) {
            Button("Move to Trash", role: .destructive) {
                vm.moveCleanupQueueToTrash()
            }
        } message: {
            Text("The selected items will be moved to the macOS Trash. They are not permanently deleted by FileAtlas.")
        }
        .alert("Cleanup Result", isPresented: Binding(
            get: { vm.cleanupResultMessage != nil },
            set: { if !$0 { vm.cleanupResultMessage = nil } }
        )) {
            Button("OK", role: .cancel) { vm.cleanupResultMessage = nil }
        } message: {
            Text(vm.cleanupResultMessage ?? "")
        }
    }
}
