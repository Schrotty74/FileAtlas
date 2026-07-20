//
//  FileListView.swift
//  FileAtlas
//
//  Mittlere Spalte: Scan-Status, Onboarding, sortierbare Tabelle, Fußleiste.
//

import SwiftUI
import AppKit

struct FileListView: View {
    @Environment(IndexViewModel.self) private var vm
    @Environment(UIState.self) private var ui
    @Environment(BackupManager.self) private var backup
    @Environment(MotionPreferences.self) private var motion
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage("FileListColumnCustomization") private var columnCustomizationData = Data()
    @State private var columnCustomization = TableColumnCustomization<FileEntry>()
    @State private var tagPickerEntry: FileEntry?
    @State private var newTagName = ""

    var body: some View {
        @Bindable var vm = vm
        VStack(spacing: 0) {
            if vm.isScanning {
                scanStatusBar
            }

            if vm.isScanning && vm.displayedEntries.isEmpty {
                ScanLoadingPlaceholder()
            } else if vm.entries.isEmpty && !vm.isScanning {
                onboarding
            } else {
                switch ui.fileListViewMode {
                case .table:
                    fileTable
                case .list:
                    compactList
                }

                footer
            }

            if !vm.scanErrors.isEmpty && !vm.isScanning {
                errorBar
            }
        }
        .background(AppTheme.windowBackground)
        .animation(motionEnabled ? FileAtlasMotion.standard : nil, value: vm.isScanning)
        .animation(motionEnabled ? FileAtlasMotion.standard : nil, value: ui.fileListViewMode)
        .animation(motionEnabled ? FileAtlasMotion.standard : nil, value: vm.displayedEntries.map(\.id))
        .navigationTitle("FileAtlas")
        .onAppear(perform: restoreColumnCustomization)
        .onChange(of: columnCustomization) { _, newValue in
            persistColumnCustomization(newValue)
        }
        .background(SpaceKeyMonitor {
            if QuickLookPresenter.shared.isPreviewVisible {
                QuickLookPresenter.shared.close()
                return true
            }
            guard vm.selectedEntry != nil else { return true }
            vm.quickLookSelectedEntry()
            return true
        })
    }

    // MARK: - Tabelle

    private var fileTable: some View {
        @Bindable var vm = vm

        return Table(vm.displayedEntries,
                     selection: $vm.selection,
                     columnCustomization: $columnCustomization) {
            TableColumn("Name") { entry in
                HStack(spacing: 8) {
                    SystemFileIconView(entry: entry, size: 16, iconDisplayMode: vm.iconDisplayMode)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(entry.name)
                            .font(.callout)
                            .tracking(-0.2)
                            .foregroundStyle(AppTheme.theme.textPrimary)
                            .lineLimit(1)
                            .truncationMode(.middle)

                        if let location = vm.searchLocationDescription(for: entry) {
                            Text(location)
                                .font(.caption2)
                                .foregroundStyle(AppTheme.theme.textSecondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }
                }
                .frame(maxWidth: .infinity, minHeight: vm.rowDensity.rowHeight, alignment: .leading)
                .contextMenu { rowContextMenu(for: entry) }
            }
            .width(min: 180, ideal: 280, max: 600)
            .customizationID("name")
            .disabledCustomizationBehavior(.visibility)

            TableColumn("Kind") { entry in
                Text(entry.isDirectory ? "Folder" : entry.fileExtension.uppercased())
                    .font(.caption)
                    .foregroundStyle(AppTheme.theme.textSecondary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, minHeight: vm.rowDensity.rowHeight, alignment: .leading)
                    .contextMenu { rowContextMenu(for: entry) }
            }
            .width(min: 64, ideal: FileColumnWidth.kind, max: 160)
            .customizationID("kind")
            .disabledCustomizationBehavior(.visibility)

            TableColumn("Status") { entry in
                Group {
                    if entry.isDuplicate {
                        DuplicateBadge()
                    } else {
                        Text("—")
                            .foregroundStyle(AppTheme.theme.textSecondary.opacity(0.5))
                    }
                }
                .frame(maxWidth: .infinity, minHeight: vm.rowDensity.rowHeight, alignment: .leading)
                .contextMenu { rowContextMenu(for: entry) }
            }
            .width(min: 72, ideal: FileColumnWidth.status, max: 180)
            .customizationID("status")
            .disabledCustomizationBehavior(.visibility)

            TableColumn("Tags") { entry in
                tagMenu(for: entry, alignment: .leading)
                    .frame(maxWidth: .infinity, minHeight: vm.rowDensity.rowHeight, alignment: .leading)
                    .contextMenu { rowContextMenu(for: entry) }
            }
            .width(min: 96, ideal: 140, max: 220)
            .customizationID("tags")
            .disabledCustomizationBehavior(.visibility)

            TableColumn("Size") { entry in
                Text(entry.formattedSize)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(AppTheme.theme.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: vm.rowDensity.rowHeight, alignment: .leading)
                    .contextMenu { rowContextMenu(for: entry) }
            }
            .width(min: 64, ideal: FileColumnWidth.size, max: 150)
            .customizationID("size")
            .disabledCustomizationBehavior(.visibility)

            TableColumn("Modified") { entry in
                Text(FileRowView.dateString(entry.modified))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(AppTheme.theme.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: vm.rowDensity.rowHeight, alignment: .leading)
                    .contextMenu { rowContextMenu(for: entry) }
            }
            .width(min: 110, ideal: FileColumnWidth.modified, max: 240)
            .customizationID("modified")
            .disabledCustomizationBehavior(.visibility)
        }
        .scrollContentBackground(.hidden)
        .alternatingRowBackgrounds(AppTheme.usesWindowGlass ? .disabled : .enabled)
        .background(GlassTableRowBackgroundConfiguration(isEnabled: AppTheme.usesWindowGlass))
        .animation(motionEnabled ? FileAtlasMotion.standard : nil, value: vm.displayedEntries.map(\.id))
    }

    private var compactList: some View {
        @Bindable var vm = vm

        return List(selection: $vm.selection) {
            ForEach(vm.displayedEntries) { entry in
                compactRow(for: entry)
                    .tag(entry.id)
                    .listRowInsets(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
                    .listRowBackground(Color.clear)
                    .contextMenu { rowContextMenu(for: entry) }
                    .transition(rowTransition)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .animation(motionEnabled ? FileAtlasMotion.standard : nil, value: vm.displayedEntries.map(\.id))
    }

    private func compactRow(for entry: FileEntry) -> some View {
        HStack(spacing: 8) {
            SystemFileIconView(entry: entry, size: 16, iconDisplayMode: vm.iconDisplayMode)

            VStack(alignment: .leading, spacing: 1) {
                Text(entry.name)
                    .font(.callout)
                    .tracking(-0.2)
                    .foregroundStyle(AppTheme.theme.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                if let location = vm.searchLocationDescription(for: entry) {
                    Text(location)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.theme.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            tagMenu(for: entry)
                .frame(width: 160, alignment: .leading)
                .layoutPriority(1)

            Text(entry.formattedSize)
                .font(.caption.monospacedDigit())
                .foregroundStyle(AppTheme.theme.textSecondary)
                .lineLimit(1)
                .frame(width: 76, alignment: .trailing)
        }
        .frame(minHeight: vm.rowDensity.rowHeight)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func rowContextMenu(for entry: FileEntry) -> some View {
        Button("Open Selected File") {
            NSWorkspace.shared.open(entry.path)
        }

        Button {
            NSWorkspace.shared.activateFileViewerSelecting([entry.path])
        } label: {
            Label("Show in Finder", systemImage: "folder")
        }

        if !entry.isDirectory {
            Button {
                vm.selection = [entry.id]
                vm.quickLookSelectedEntry()
            } label: {
                Label("Open Quick Look", systemImage: "eye")
            }
        }

        Button {
            copyPath(for: entry)
        } label: {
            Label("Copy", systemImage: "doc.on.doc")
        }

        Divider()

        Button {
            ui.selectionBackupEntries = vm.backupEntries(fallback: entry)
            ui.showSelectionBackup = true
        } label: {
            Label("Back Up Selected Items…", systemImage: "arrow.down.doc")
        }
        .disabled(backup.isBackingUp)

        Divider()

        if vm.isInCleanupQueue(entry) {
            Button {
                vm.removeFromCleanupQueue(entry)
            } label: {
                Label("Remove from Cleanup Queue", systemImage: "trash.slash")
            }
        } else {
            Button {
                vm.addToCleanupQueue(entry)
            } label: {
                Label("Add to Cleanup Queue", systemImage: "trash")
            }
        }

        Divider()

        Button {
            tagPickerEntry = entry
        } label: {
            Label("Add tag", systemImage: "tag")
        }

        Menu("Tags") {
            ForEach(vm.availableTags) { tag in
                Button {
                    vm.toggleTag(tag, for: entry)
                } label: {
                    Label(tag.title, systemImage: vm.hasTag(tag, for: entry) ? "checkmark.circle.fill" : "circle")
                }
            }
        }
    }

    private func copyPath(for entry: FileEntry) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(entry.pathKey, forType: .string)
    }

    private func tagMenu(for entry: FileEntry, alignment: Alignment = .center) -> some View {
        Button {
            tagPickerEntry = entry
        } label: {
            ZStack(alignment: alignment) {
                Color.clear
                tagSummary(for: entry)
            }
            .frame(width: 160, alignment: alignment)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("tag-button")
        .popover(isPresented: Binding(
            get: { tagPickerEntry?.id == entry.id },
            set: { isPresented in if !isPresented { tagPickerEntry = nil } }
        )) {
            TagPickerPopover(entry: entry, newTagName: $newTagName)
                .environment(vm)
        }
    }

    @ViewBuilder
    private func tagSummary(for entry: FileEntry) -> some View {
        let tags = Array(vm.tags(for: entry)).sorted { $0.title < $1.title }
        if tags.isEmpty {
            Text("Add tag")
                .font(.caption)
                .foregroundStyle(AppTheme.theme.textSecondary)
        } else {
            HStack(spacing: 4) {
                ForEach(tags) { tag in
                    TagPill(tag: tag)
                }
            }
        }
    }

    private func restoreColumnCustomization() {
        guard !columnCustomizationData.isEmpty,
              let restored = try? JSONDecoder().decode(TableColumnCustomization<FileEntry>.self, from: columnCustomizationData)
        else { return }
        columnCustomization = restored
    }

    private func persistColumnCustomization(_ customization: TableColumnCustomization<FileEntry>) {
        guard let data = try? JSONEncoder().encode(customization) else { return }
        columnCustomizationData = data
    }

    // MARK: - Spaltenkopf (sortierbar)

    private var columnHeader: some View {
        HStack(spacing: 0) {
            sortButton("Name", field: .name)
                .frame(maxWidth: .infinity, alignment: .leading)
            sortButton("Kind", field: .type)
                .frame(width: FileColumnWidth.kind, alignment: .leading)
            Text("Status")
                .frame(width: FileColumnWidth.status, alignment: .leading)
            sortButton("Size", field: .size, trailing: true)
                .frame(width: FileColumnWidth.size, alignment: .trailing)
            sortButton("Modified", field: .modified, trailing: true)
                .frame(width: FileColumnWidth.modified, alignment: .trailing)
        }
        .font(.caption2.weight(.semibold))
        .foregroundStyle(AppTheme.theme.textSecondary)
        .textCase(.uppercase)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
    }

    private func sortButton(_ title: LocalizedStringKey, field: SortField, trailing: Bool = false) -> some View {
        Button {
            vm.toggleSort(field)
        } label: {
            HStack(spacing: 3) {
                if trailing { Spacer(minLength: 0) }
                Text(title)
                if vm.sortField == field {
                    Image(systemName: vm.sortDirection == .ascending ? "chevron.up" : "chevron.down")
                        .font(.system(size: 8))
                        .foregroundStyle(AppTheme.theme.accentColor)
                }
                if !trailing { Spacer(minLength: 0) }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Scan-Status

    private var scanStatusBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(AppTheme.theme.accentColor)
                .symbolEffect(.rotate, options: .repeating, isActive: vm.isScanning && motionEnabled)
            Group {
                if let autoScanLaunchMessage = vm.autoScanLaunchMessage {
                    Text(autoScanLaunchMessage)
                } else {
                    Text("Scanning…")
                }
            }
            .font(.callout.weight(.medium))
            .foregroundStyle(AppTheme.theme.textPrimary)
            Text("\(vm.scanProgressCount) files")
                .font(.caption.monospacedDigit())
                .foregroundStyle(AppTheme.theme.accentColor)
                .contentTransition(motionEnabled ? .numericText() : .identity)
            Text(vm.currentScanPath)
                .font(.caption)
                .foregroundStyle(AppTheme.theme.textSecondary)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer()
            Button("Cancel") { vm.cancelScan() }
                .buttonStyle(.plain)
                .foregroundStyle(AppTheme.theme.accentColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.thinMaterial)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Onboarding

    @ViewBuilder
    private var onboarding: some View {
        if vm.scanRoots.isEmpty {
            // Noch keine Orte: zum Hinzufügen auffordern.
            VStack(spacing: 14) {
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(AppTheme.theme.accentColor)
                Text("Add a folder to get started")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(AppTheme.theme.textPrimary)
                Text("Choose one or more folders to index. FileAtlas never modifies your files.")
                    .font(.callout)
                    .foregroundStyle(AppTheme.theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 360)
                Button {
                    vm.addFolders()
                } label: {
                    Label("Add Folder…", systemImage: "plus")
                        .padding(.horizontal, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.theme.accentColor)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.opacity.combined(with: .scale(scale: 0.98)))
        } else {
            // Orte vorhanden, aber noch nicht gescannt (z. B. nach Neustart).
            VStack(spacing: 14) {
                Image(systemName: "sparkle.magnifyingglass")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(AppTheme.theme.accentColor)
                Text("Ready to scan")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(AppTheme.theme.textPrimary)
                Text("\(vm.scanRoots.count) location(s) ready. Start a scan to index their contents.")
                    .font(.callout)
                    .foregroundStyle(AppTheme.theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 360)
                Button {
                    vm.startScan()
                } label: {
                    Label("Scan", systemImage: "arrow.clockwise")
                        .padding(.horizontal, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.theme.accentColor)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.opacity.combined(with: .scale(scale: 0.98)))
        }
    }

    // MARK: - Fußleiste

    private var footer: some View {
        HStack(spacing: 8) {
            Text(fileCountText)
                .contentTransition(motionEnabled ? .numericText() : .identity)
            Text("·")
            Text(ByteCountFormatter.string(fromByteCount: vm.totalSize, countStyle: .file))
            if vm.displayedDuplicateCount > 0 {
                Text("·")
                Text(duplicateCountText)
                    .foregroundStyle(AppTheme.gold)
                    .contentTransition(motionEnabled ? .numericText() : .identity)
            }
            Spacer()
        }
        .font(.caption2.monospacedDigit())
        .foregroundStyle(AppTheme.theme.textSecondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.thinMaterial)
    }

    private var fileCountText: String {
        let visibleCount = vm.displayedEntries.count.formatted()
        if vm.hasActiveDisplayFilter {
            return String(
                format: NSLocalizedString("%@ of %@ files", comment: "Visible file count compared to total file count when filters are active."),
                visibleCount,
                vm.entries.count.formatted()
            )
        }
        return String(
            format: NSLocalizedString("%@ files", comment: "Visible file count."),
            visibleCount
        )
    }

    private var duplicateCountText: String {
        String(
            format: NSLocalizedString("%@ duplicates", comment: "Visible duplicate file count."),
            vm.displayedDuplicateCount.formatted()
        )
    }

    // MARK: - Fehlerliste

    private var errorBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(AppTheme.gold)
            Text("\(vm.scanErrors.count) folders skipped (no permission)")
                .font(.caption)
                .foregroundStyle(AppTheme.theme.textSecondary)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(AppTheme.gold.opacity(0.08))
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var motionEnabled: Bool {
        !motion.reduceMotion && !systemReduceMotion
    }

    private var rowTransition: AnyTransition {
        motionEnabled
            ? .opacity.combined(with: .move(edge: .bottom))
            : .identity
    }
}

/// Applies the Glass-theme alternation to native row views so it spans the full table width.
@MainActor
private struct GlassTableRowBackgroundConfiguration: NSViewRepresentable {
    let isEnabled: Bool

    func makeNSView(context: Context) -> GlassTableRowBackgroundProbe {
        GlassTableRowBackgroundProbe()
    }

    func updateNSView(_ nsView: GlassTableRowBackgroundProbe, context: Context) {
        nsView.configure(isEnabled: isEnabled)
    }
}

@MainActor
private final class GlassTableRowBackgroundProbe: NSView {
    private weak var tableView: NSTableView?
    private var isEnabled = false

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func configure(isEnabled: Bool) {
        self.isEnabled = isEnabled
        DispatchQueue.main.async { [weak self] in
            self?.connectAndApply()
        }
    }

    private func connectAndApply() {
        if tableView == nil {
            guard let tableView = findTableView() else { return }
            self.tableView = tableView

            if let clipView = tableView.enclosingScrollView?.contentView {
                clipView.postsBoundsChangedNotifications = true
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(handleVisibleRowsChanged),
                    name: NSView.boundsDidChangeNotification,
                    object: clipView
                )
            }
        }

        applyRowBackgrounds()
    }

    @objc private func handleVisibleRowsChanged() {
        applyRowBackgrounds()
    }

    private func applyRowBackgrounds() {
        guard let tableView else { return }

        tableView.usesAlternatingRowBackgroundColors = !isEnabled

        for row in 0..<tableView.numberOfRows {
            guard let rowView = tableView.rowView(atRow: row, makeIfNecessary: false) else { continue }

            if isEnabled {
                rowView.backgroundColor = row.isMultiple(of: 2)
                    ? .clear
                    : NSColor(red: 0.025, green: 0.06, blue: 0.11, alpha: 0.46)
            } else {
                let colors = NSColor.alternatingContentBackgroundColors
                rowView.backgroundColor = colors[row % colors.count]
            }
        }
    }

    private func findTableView() -> NSTableView? {
        var view: NSView? = superview

        while let current = view {
            if let tableView = current as? NSTableView {
                return tableView
            }
            if let tableView = firstTableView(in: current) {
                return tableView
            }
            view = current.superview
        }

        return nil
    }

    private func firstTableView(in view: NSView) -> NSTableView? {
        for subview in view.subviews {
            if let tableView = subview as? NSTableView {
                return tableView
            }
            if let tableView = firstTableView(in: subview) {
                return tableView
            }
        }
        return nil
    }
}

private struct ScanLoadingPlaceholder: View {
    @Environment(MotionPreferences.self) private var motion
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @State private var highlightPosition = -0.8

    var body: some View {
        VStack(spacing: 10) {
            ForEach(0..<7, id: \.self) { index in
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 4)
                        .frame(width: 18, height: 18)
                    VStack(alignment: .leading, spacing: 5) {
                        RoundedRectangle(cornerRadius: 3)
                            .frame(width: index.isMultiple(of: 3) ? 172 : 230, height: 11)
                        RoundedRectangle(cornerRadius: 3)
                            .frame(width: 98, height: 8)
                    }
                    Spacer()
                    RoundedRectangle(cornerRadius: 3)
                        .frame(width: 52, height: 9)
                }
                .foregroundStyle(AppTheme.theme.textSecondary.opacity(0.16))
                .padding(.horizontal, 14)
                .frame(height: 34)
                .background {
                    GeometryReader { proxy in
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.16), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: proxy.size.width * 0.55)
                        .offset(x: highlightPosition * proxy.size.width)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding(.top, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .task {
            guard isMotionEnabled else { return }
            withAnimation(.linear(duration: 1.35).repeatForever(autoreverses: false)) {
                highlightPosition = 1.1
            }
        }
    }

    private var isMotionEnabled: Bool {
        !motion.reduceMotion && !systemReduceMotion
    }
}

private struct SpaceKeyMonitor: NSViewRepresentable {
    let onSpace: () -> Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(onSpace: onSpace)
    }

    func makeNSView(context: Context) -> NSView {
        context.coordinator.install()
        return NSView(frame: .zero)
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.onSpace = onSpace
        context.coordinator.install()
    }

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.uninstall()
    }

    final class Coordinator {
        var onSpace: () -> Bool
        private var monitor: Any?

        init(onSpace: @escaping () -> Bool) {
            self.onSpace = onSpace
        }

        func install() {
            guard monitor == nil else { return }
            monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard event.charactersIgnoringModifiers == " ",
                      !Self.isTextInputActive(),
                      event.modifierFlags.intersection([.command, .option, .control]).isEmpty
                else {
                    return event
                }

                guard !event.isARepeat else { return nil }
                return self?.onSpace() == true ? nil : event
            }
        }

        func uninstall() {
            if let monitor {
                NSEvent.removeMonitor(monitor)
            }
            monitor = nil
        }

        private static func isTextInputActive() -> Bool {
            NSApp.keyWindow?.firstResponder is NSTextView
        }
    }
}

private struct TagPickerPopover: View {
    @Environment(IndexViewModel.self) private var vm
    @Environment(\.dismiss) private var dismiss
    let entry: FileEntry
    @Binding var newTagName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tags")
                .font(.headline)

            if !suggestedTags.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Suggested")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.theme.textSecondary)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 6)], alignment: .leading, spacing: 6) {
                        ForEach(suggestedTags) { tag in
                            Button {
                                applySuggestedTag(tag)
                            } label: {
                                TagPill(tag: tag)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("tag-option-\(tag.title.lowercased())")
                        }
                    }
                }

                Divider()
            }

            ForEach(vm.availableTags) { tag in
                HStack {
                    Button {
                        toggleTag(tag)
                    } label: {
                        HStack {
                            Image(systemName: vm.hasTag(tag, for: entry) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(vm.hasTag(tag, for: entry) ? AppTheme.theme.accentColor : AppTheme.theme.textSecondary)
                            TagPill(tag: tag)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    if !FileTag.predefined.contains(where: { $0.title == tag.title }) {
                        Button {
                            dismissThenPerform {
                                vm.removeCustomTag(tag)
                            }
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(AppTheme.theme.textSecondary)
                    }
                }
            }

            Divider()

            HStack {
                TextField("Eigenes Tag", text: $newTagName)
                    .onSubmit(addTag)
                Button("Add") { addTag() }
                    .disabled(newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(14)
        .frame(width: 260)
    }

    private var suggestedTags: [FileTag] {
        var titles: [String] = []

        switch FilterPreset.normalize(entry.fileExtension) {
        case "mp4", "mov", "avi", "mkv", "m4v":
            titles.append("Video")
        case "mp3", "aac", "flac", "wav", "m4a":
            titles.append("Audio")
        case "jpg", "jpeg", "png", "gif", "heic", "raw", "cr2", "arw":
            titles.append("Foto")
        case "pdf", "docx", "doc", "pages":
            titles.append("Dokument")
        case "xlsx", "xls", "numbers", "csv":
            titles.append("Tabelle")
        case "pptx", "ppt", "key":
            titles.append("Präsentation")
        case "zip", "dmg", "rar", "7z":
            titles.append("Archiv")
        case "exe", "pkg", "msi", "apk":
            titles.append("Installer")
        case "app":
            titles.append("App")
        case "swift", "py", "js", "ts", "html", "css", "json":
            titles.append("Code")
        default:
            break
        }

        let folderPath = entry.path.deletingLastPathComponent().path(percentEncoded: false)
        let normalizedPath = folderPath.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        if normalizedPath.contains("rechnung") || normalizedPath.contains("invoice") {
            titles.append("Rechnung")
        }
        if normalizedPath.contains("backup") {
            titles.append("Backup")
        }
        if normalizedPath.contains("download") {
            titles.append("Download")
        }
        if normalizedPath.contains("desktop") {
            titles.append("Desktop")
        }

        var seen = Set<String>()
        return titles
            .map { FileTag($0) }
            .filter { !$0.title.isEmpty }
            .filter { tag in
                seen.insert(tag.title.lowercased()).inserted
                    && !vm.hasTag(tag, for: entry)
            }
    }

    private func applySuggestedTag(_ tag: FileTag) {
        applyTag(tag, addToCustomTags: true)
    }

    private func toggleTag(_ tag: FileTag) {
        applyTag(tag, addToCustomTags: false)
    }

    private func addTag() {
        let tag = FileTag(newTagName)
        applyTag(tag, addToCustomTags: true)
        newTagName = ""
    }

    private func applyTag(_ tag: FileTag, addToCustomTags: Bool) {
        guard !tag.title.isEmpty else {
            return
        }

        let isNewlyApplied = !vm.hasTag(tag, for: entry)

        dismissThenPerform {
            if addToCustomTags {
                vm.addCustomTag(tag.title)
            }

            if isNewlyApplied || !addToCustomTags {
                vm.toggleTag(tag, for: entry)
            }
        }
    }

    private func dismissThenPerform(_ action: @escaping @MainActor () -> Void) {
        dismiss()
        Task { @MainActor in
            action()
        }
    }
}

private struct TagPill: View {
    let tag: FileTag

    var body: some View {
        Text(tag.title)
            .font(.caption2.weight(.medium))
            .lineLimit(1)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .foregroundStyle(foreground)
            .background(background, in: Capsule())
    }

    private var foreground: Color {
        switch tag.title.lowercased() {
        case FileTag.important.title.lowercased(): return AppTheme.gold
        case FileTag.delete.title.lowercased(): return .red
        case FileTag.checked.title.lowercased(): return AppTheme.theme.accentColor
        case FileTag.favorite.title.lowercased(): return .purple
        default: return AppTheme.theme.secondaryColor
        }
    }

    private var background: Color { foreground.opacity(0.16) }
}
