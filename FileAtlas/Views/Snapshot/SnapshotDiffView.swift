//
//  SnapshotDiffView.swift
//  FileAtlas
//
//  Ergebnis des Snapshot-Vergleichs: Neu / Entfernt / Geändert + Export.
//

import SwiftUI

struct SnapshotDiffView: View {
    @Environment(IndexViewModel.self) private var vm
    @Environment(\.dismiss) private var dismiss
    @Environment(MotionPreferences.self) private var motion
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @State private var hasAppeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Snapshot Comparison")
                    .font(.headline)
                Spacer()
                Menu {
                    Button("Export as Excel…") { vm.export(format: .xlsx) }
                    Button("Export as PDF…") { vm.export(format: .pdf) }
                    Button("Export as CSV…") { vm.export(format: .csv) }
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                .fixedSize()
                Button("Done") {
                    vm.clearDiff()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()

            Divider()

            if let diff = vm.currentDiff {
                if diff.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.seal")
                            .font(.system(size: 36, weight: .light))
                            .foregroundStyle(AppTheme.theme.accentColor)
                        Text("No changes since this snapshot")
                            .foregroundStyle(AppTheme.theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                } else {
                    List {
                        section("Added", color: .green, changes: diff.added, systemImage: "plus.circle.fill")
                        section("Changed", color: AppTheme.gold, changes: diff.changed, systemImage: "pencil.circle.fill")
                        section("Removed", color: .red, changes: diff.removed, systemImage: "minus.circle.fill")
                    }
                    .listStyle(.inset)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
        .frame(width: 620, height: 560)
        .animation(isMotionEnabled ? FileAtlasMotion.standard : nil, value: diffSignature)
        .task { hasAppeared = true }
    }

    @ViewBuilder
    private func section(_ title: LocalizedStringKey, color: Color, changes: [SnapshotChange], systemImage: String) -> some View {
        if !changes.isEmpty {
            Section {
                ForEach(changes) { change in
                    HStack(spacing: 8) {
                        Image(systemName: systemImage)
                            .foregroundStyle(color)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(change.entry.name)
                                .font(.callout)
                                .foregroundStyle(AppTheme.theme.textPrimary)
                            Text(change.entry.pathKey)
                                .font(.caption2)
                                .foregroundStyle(AppTheme.theme.textSecondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        Spacer()
                        if change.status == .changed, let prev = change.previous {
                            Text("\(prev.formattedSize) → \(change.entry.formattedSize)")
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(AppTheme.gold)
                        } else {
                            Text(change.entry.formattedSize)
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(AppTheme.theme.textSecondary)
                        }
                    }
                    .opacity(hasAppeared || !isMotionEnabled ? 1 : 0)
                    .offset(y: hasAppeared || !isMotionEnabled ? 0 : 10)
                    .animation(isMotionEnabled ? FileAtlasMotion.staged.delay(0.018 * Double(changes.firstIndex(where: { $0.id == change.id }) ?? 0)) : nil, value: hasAppeared)
                }
            } header: {
                HStack {
                    Text(title).foregroundStyle(color)
                    Text("(\(changes.count))")
                        .foregroundStyle(AppTheme.theme.textSecondary)
                        .contentTransition(isMotionEnabled ? .numericText() : .identity)
                }
            }
        }
    }

    private var isMotionEnabled: Bool {
        !motion.reduceMotion && !systemReduceMotion
    }

    private var diffSignature: String {
        guard let diff = vm.currentDiff else { return "empty" }
        return "\(diff.added.count)-\(diff.changed.count)-\(diff.removed.count)"
    }
}
