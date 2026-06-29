//
//  MainToolbar.swift
//  FileAtlas
//
//  Werkzeugleiste: Suchfeld, Scan/Abbrechen, Filter, Vergleich, Export.
//

import SwiftUI

struct MainToolbar: ToolbarContent {
    let vm: IndexViewModel
    let ui: UIState
    @Binding var searchText: String

    var body: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            SearchField(text: $searchText)
                .frame(maxWidth: 340)
        }

        ToolbarItemGroup(placement: .primaryAction) {
            if vm.isScanning {
                Button(role: .cancel) {
                    vm.cancelScan()
                } label: {
                    Label("Cancel Scan", systemImage: "xmark.circle")
                }
            } else {
                Button {
                    vm.rescanSelectedRoot()
                } label: {
                    Label(vm.entries.isEmpty ? "Scan" : "Rescan", systemImage: "arrow.clockwise")
                }
                .disabled(vm.scanRoots.isEmpty)
            }

            Button {
                ui.showSettingsPanel = true
            } label: {
                Label("Settings", systemImage: "gearshape")
            }

            Menu {
                Button("Export as Excel…") { vm.export(format: .xlsx) }
                Button("Export as PDF…") { vm.export(format: .pdf) }
                Button("Export as CSV…") { vm.export(format: .csv) }
            } label: {
                Label("Export", systemImage: "square.and.arrow.up")
            }
            .disabled(vm.displayedEntries.isEmpty)
        }
    }
}
