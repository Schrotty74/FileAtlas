//
//  MainToolbar.swift
//  FileAtlas
//
//  Werkzeugleiste: Suchfeld, Scan/Abbrechen, Filter, Vergleich, Export.
//

import AppKit
import SwiftUI

struct MainToolbar: ToolbarContent {
    let vm: IndexViewModel
    let ui: UIState
    @Binding var searchText: String
    @Binding var searchAllFolders: Bool
    @Environment(TooltipPreferences.self) private var tooltips

    var body: some ToolbarContent {
        @Bindable var ui = ui

        ToolbarItem(placement: .navigation) {
            HStack(spacing: 8) {
                Text("FileAtlas")
                    .font(.title3.weight(.semibold))
                    .fixedSize()
                DiscordMark(size: 30)
                GitHubMark(size: 30)
            }
        }

        ToolbarItem(placement: .principal) {
            SearchField(text: $searchText, searchAllFolders: $searchAllFolders)
                .frame(maxWidth: 520)
        }

        ToolbarItemGroup(placement: .primaryAction) {
            ViewModeSegmentedControl(
                selection: $ui.fileListViewMode,
                showTooltips: tooltips.showTooltips
            )
            .frame(width: 92)

            if vm.isScanning {
                Button(role: .cancel) {
                    vm.cancelScan()
                } label: {
                    Label("Cancel Scan", systemImage: "xmark.circle")
                }
                .fileAtlasTooltip("Cancel Scan")
            } else {
                Button {
                    vm.rescanSelectedRoot()
                } label: {
                    Label(vm.entries.isEmpty ? "Scan" : "Rescan", systemImage: "arrow.clockwise")
                }
                .disabled(vm.scanRoots.isEmpty)
                .fileAtlasTooltip(vm.entries.isEmpty ? "Scan" : "Rescan")
            }

            Button {
                ui.showStorageAnalysis = true
            } label: {
                Label("Storage Analysis", systemImage: "chart.bar.xaxis")
            }
            .disabled(vm.entries.isEmpty)
            .fileAtlasTooltip("Storage Analysis")

            Button {
                ui.showCleanupQueue = true
            } label: {
                Label("Cleanup Queue", systemImage: "trash")
            }
            .fileAtlasTooltip("Cleanup Queue")

            Button {
                ui.showSettingsPanel = true
            } label: {
                Label("Settings", systemImage: "gearshape")
            }
            .fileAtlasTooltip("Settings")

            Menu {
                Button("Export as Excel…") { vm.export(format: .xlsx) }
                Button("Export as PDF…") { vm.export(format: .pdf) }
                Button("Export as CSV…") { vm.export(format: .csv) }
            } label: {
                Label("Export", systemImage: "square.and.arrow.up")
            }
            .disabled(vm.displayedEntries.isEmpty)
            .fileAtlasTooltip("Export")
        }
    }

}

private struct ViewModeSegmentedControl: NSViewRepresentable {
    @Binding var selection: FileListViewMode
    let showTooltips: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(selection: $selection)
    }

    func makeNSView(context: Context) -> NSSegmentedControl {
        let control = NSSegmentedControl()
        control.segmentCount = FileListViewMode.allCases.count
        control.trackingMode = .selectOne
        control.target = context.coordinator
        control.action = #selector(Coordinator.selectSegment(_:))
        control.setAccessibilityLabel(String(localized: "View Mode"))

        for (index, mode) in FileListViewMode.allCases.enumerated() {
            control.setImage(
                NSImage(systemSymbolName: mode.systemImage, accessibilityDescription: Self.localizedTitle(for: mode)),
                forSegment: index
            )
            control.setWidth(46, forSegment: index)
        }

        return control
    }

    func updateNSView(_ control: NSSegmentedControl, context: Context) {
        context.coordinator.selection = $selection
        control.selectedSegment = FileListViewMode.allCases.firstIndex(of: selection) ?? 0

        for (index, mode) in FileListViewMode.allCases.enumerated() {
            control.setToolTip(showTooltips ? Self.localizedTitle(for: mode) : nil, forSegment: index)
        }
    }

    private static func localizedTitle(for mode: FileListViewMode) -> String {
        switch mode {
        case .table: return String(localized: "Table")
        case .list: return String(localized: "List")
        }
    }

    final class Coordinator: NSObject {
        var selection: Binding<FileListViewMode>

        init(selection: Binding<FileListViewMode>) {
            self.selection = selection
        }

        @MainActor @objc func selectSegment(_ sender: NSSegmentedControl) {
            guard FileListViewMode.allCases.indices.contains(sender.selectedSegment) else { return }
            selection.wrappedValue = FileListViewMode.allCases[sender.selectedSegment]
        }
    }
}
