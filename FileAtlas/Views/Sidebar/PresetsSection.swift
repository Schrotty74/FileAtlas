//
//  PresetsSection.swift
//  FileAtlas
//

import SwiftUI

struct PresetsSection: View {
    @Environment(IndexViewModel.self) private var vm
    @Environment(UIState.self) private var ui

    var body: some View {
        Section {
            ForEach(vm.presets) { preset in
                Button {
                    if vm.activePresetID == preset.id {
                        vm.clearPreset()
                    } else {
                        vm.applyPreset(preset)
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: vm.activePresetID == preset.id
                              ? "line.3.horizontal.decrease.circle.fill"
                              : "line.3.horizontal.decrease.circle")
                        Text(preset.name)
                            .lineLimit(1)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(vm.activePresetID == preset.id
                                 ? AppTheme.theme.accentColor : AppTheme.theme.textPrimary)
                .contextMenu {
                    Button {
                        ui.editingPreset = preset
                        ui.isPresentingPresetEditor = true
                    } label: { Label("Edit…", systemImage: "pencil") }
                    Button(role: .destructive) {
                        vm.deletePreset(preset)
                    } label: { Label("Delete", systemImage: "trash") }
                }
            }

            Button {
                ui.editingPreset = nil
                ui.isPresentingPresetEditor = true
            } label: {
                Label("New Filter Set…", systemImage: "plus")
            }
            .buttonStyle(.plain)
            .foregroundStyle(AppTheme.theme.accentColor)
        } header: {
            Text("Filter Sets")
        }
    }
}
