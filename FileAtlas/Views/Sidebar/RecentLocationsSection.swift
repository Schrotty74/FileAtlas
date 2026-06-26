//
//  RecentLocationsSection.swift
//  FileAtlas
//

import SwiftUI

struct RecentLocationsSection: View {
    @Environment(IndexViewModel.self) private var vm
    @State private var hoveredRoot: URL?

    var body: some View {
        if !vm.recentScanRoots.isEmpty {
            Section {
                ForEach(vm.recentScanRoots, id: \.self) { url in
                    HStack(spacing: 6) {
                        Button {
                            vm.startRecentScan(root: url)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "clock.fill")
                                    .foregroundStyle(AppTheme.theme.accentColor)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(url.lastPathComponent)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                    Text(url.deletingLastPathComponent().path(percentEncoded: false))
                                        .font(.caption2)
                                        .foregroundStyle(AppTheme.theme.textSecondary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }
                                Spacer(minLength: 0)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .disabled(vm.isScanning)

                        if hoveredRoot == url {
                            Button {
                                vm.removeRecentScanRoot(url)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(AppTheme.theme.textSecondary)
                            .help("Remove from Quick Access")
                        }
                    }
                    .onHover { inside in hoveredRoot = inside ? url : nil }
                    .contextMenu {
                        Button(role: .destructive) {
                            vm.removeRecentScanRoot(url)
                        } label: {
                            Label("Remove from Quick Access", systemImage: "xmark.circle")
                        }
                    }
                }
            } header: {
                Text("Schnellzugriff")
            }
        }
    }
}
