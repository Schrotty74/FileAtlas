//
//  SmartCollectionsSection.swift
//  FileAtlas
//

import SwiftUI

struct SmartCollectionsSection: View {
    @Environment(IndexViewModel.self) private var vm
    @Environment(UIState.self) private var ui

    var body: some View {
        Section {
            ForEach(vm.smartCollections) { collection in
                Button {
                    vm.toggleSmartCollection(collection)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: vm.activeSmartCollectionID == collection.id ? "folder.fill" : "folder")
                        Text(collection.name).lineLimit(1)
                        Spacer()
                        Text(vm.smartCollectionMatchCount(for: collection).formatted())
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(AppTheme.theme.textSecondary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(vm.activeSmartCollectionID == collection.id
                                 ? AppTheme.theme.accentColor : AppTheme.theme.textPrimary)
                .contextMenu {
                    Button {
                        ui.editingSmartCollection = collection
                        ui.isPresentingSmartCollectionEditor = true
                    } label: {
                        Label("Edit…", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        vm.deleteSmartCollection(collection)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }

            Button {
                ui.editingSmartCollection = nil
                ui.isPresentingSmartCollectionEditor = true
            } label: {
                Label("New Smart Collection…", systemImage: "plus")
            }
            .buttonStyle(.plain)
            .foregroundStyle(AppTheme.theme.accentColor)
        } header: {
            Text("Smart Collections")
        }
    }
}
