//
//  SnapshotPickerView.swift
//  FileAtlas
//
//  Auswahl eines gespeicherten Snapshots zum Vergleich.
//

import SwiftUI

struct SnapshotPickerView: View {
    let showsChrome: Bool

    @Environment(IndexViewModel.self) private var vm
    @Environment(UIState.self) private var ui
    @Environment(\.dismiss) private var dismiss

    @State private var snapshots: [Snapshot] = []
    @State private var snapshotPendingDeletion: Snapshot?
    @State private var showDeleteConfirmation = false

    init(showsChrome: Bool = true) {
        self.showsChrome = showsChrome
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if showsChrome {
                HStack {
                    Text("Compare with Snapshot")
                        .font(.headline)
                    Spacer()
                    Button("Close") { dismiss() }
                }
                .padding()

                Divider()
            }

            if snapshots.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "clock.badge.questionmark")
                        .font(.system(size: 36, weight: .light))
                        .foregroundStyle(AppTheme.theme.textSecondary)
                    Text("No snapshots saved yet")
                        .foregroundStyle(AppTheme.theme.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(snapshots) { snapshot in
                    HStack(spacing: 8) {
                        Button {
                            vm.compare(with: snapshot)
                            ui.showDiff = true
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(snapshot.displayName)
                                        .foregroundStyle(AppTheme.theme.textPrimary)
                                    Text("\(snapshot.fileCount) files")
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.theme.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(AppTheme.theme.textSecondary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        Button(role: .destructive) {
                            confirmDelete(snapshot)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(AppTheme.theme.textSecondary)
                        .help("Delete Snapshot")
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            confirmDelete(snapshot)
                        } label: {
                            Label("Delete Snapshot", systemImage: "trash")
                        }
                    }
                }
            }

            Divider()

            HStack {
                Button {
                    vm.saveSnapshot()
                    snapshots = vm.availableSnapshots()
                } label: {
                    Label("Save snapshot now", systemImage: "camera")
                }
                .disabled(vm.entries.isEmpty)
                Spacer()
            }
            .padding()
        }
        .frame(width: showsChrome ? 460 : nil, height: showsChrome ? 460 : nil)
        .confirmationDialog(
            "Delete Snapshot?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Snapshot", role: .destructive) {
                deletePendingSnapshot()
            }
            Button("Cancel", role: .cancel) {
                snapshotPendingDeletion = nil
            }
        } message: {
            Text("This removes the snapshot from FileAtlas. Files on disk are not changed.")
        }
        .onAppear { snapshots = vm.availableSnapshots() }
    }

    private func confirmDelete(_ snapshot: Snapshot) {
        snapshotPendingDeletion = snapshot
        showDeleteConfirmation = true
    }

    private func deletePendingSnapshot() {
        guard let snapshot = snapshotPendingDeletion else { return }
        vm.deleteSnapshot(snapshot)
        snapshots = vm.availableSnapshots()
        snapshotPendingDeletion = nil
    }
}
