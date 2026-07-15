//
//  AlertRuleResultsView.swift
//  FileAtlas
//

import SwiftUI
import AppKit

struct AlertRuleResultsView: View {
    @Environment(IndexViewModel.self) private var vm
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Rule Matches")
                    .font(.headline)
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding()

            Divider()

            if vm.latestAlertRuleMatches.isEmpty {
                ContentUnavailableView("No rule matches", systemImage: "checkmark.seal")
            } else {
                List {
                    ForEach(vm.latestAlertRuleMatches) { result in
                        Section("\(result.rule.name) (\(result.entries.count))") {
                            ForEach(result.entries) { entry in
                                Button {
                                    NSWorkspace.shared.activateFileViewerSelecting([entry.path])
                                } label: {
                                    HStack(spacing: 8) {
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
                    }
                }
                .listStyle(.inset)
            }
        }
        .frame(width: 640, height: 560)
    }
}
