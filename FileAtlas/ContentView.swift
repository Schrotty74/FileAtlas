//
//  ContentView.swift
//  FileAtlas
//
//  Drei-Spalten-Wurzel: Sidebar | Dateiliste | Detailpanel.
//

import AppKit
import SwiftUI

/// Gemeinsamer UI-Zustand (Sheets, Spaltensichtbarkeit, Preset-Editor).
@Observable
@MainActor
final class UIState {
    private static let fileListViewModeKey = "FileAtlas.fileListViewMode"

    var showFilterPanel = false
    var showSnapshotPicker = false
    var showDiff = false
    var showFolderCompare = false
    var showStorageAnalysis = false
    var showCleanupQueue = false
    var showAlertRuleResults = false
    var showSettingsPanel = false
    var isPresentingPresetEditor = false
    var editingPreset: FilterPreset? = nil
    var isPresentingSmartCollectionEditor = false
    var editingSmartCollection: SmartCollection? = nil
    var isSidebarVisible = true
    var fileListViewMode: FileListViewMode {
        didSet { UserDefaults.standard.set(fileListViewMode.rawValue, forKey: Self.fileListViewModeKey) }
    }

    // Backup
    var backupLocation: URL? = nil
    var showBackupSettings = false
    var selectionBackupEntries: [FileEntry] = []
    var showSelectionBackup = false

    init() {
        self.fileListViewMode = .list
    }
}

struct ContentView: View {
    @Environment(IndexViewModel.self) private var vm
    @Environment(UIState.self) private var ui
    @Environment(AppearanceManager.self) private var appearance
    @Environment(MotionPreferences.self) private var motion
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    var body: some View {
        @Bindable var vm = vm
        @Bindable var ui = ui

        ZStack {
            if AppTheme.usesWindowGlass {
                FullSurfaceGlassBackdrop(isGlowAnimated: motionEnabled && !vm.isScanning)
                    .allowsHitTesting(false)
            } else {
                AppTheme.windowBackground
            }

            Group {
                if vm.hasUserContent {
                    HSplitView {
                        if ui.isSidebarVisible {
                            SidebarView()
                                .frame(minWidth: 220, idealWidth: 244, maxWidth: 300)
                        }

                        FileListView()
                            .frame(minWidth: 480, idealWidth: 660)

                        DetailPanelView()
                            .frame(minWidth: 220, idealWidth: 250, maxWidth: 300)
                    }
                } else {
                    FirstLaunchHelpView()
                }
            }
        }
        .id(appearance.colorTheme)
        .animation(motionEnabled ? FileAtlasMotion.standard : nil, value: vm.hasUserContent)
        .animation(motionEnabled ? FileAtlasMotion.standard : nil, value: ui.isSidebarVisible)
        .toolbar {
            MainToolbar(vm: vm, ui: ui, searchText: $vm.searchText, searchAllFolders: $vm.searchAllFolders)
        }
        .sheet(isPresented: $ui.showFilterPanel) {
            FilterPanel()
        }
        .sheet(isPresented: $ui.isPresentingPresetEditor) {
            PresetEditorView(original: ui.editingPreset)
        }
        .sheet(isPresented: $ui.isPresentingSmartCollectionEditor) {
            SmartCollectionEditorView(original: ui.editingSmartCollection)
        }
        .sheet(isPresented: $ui.showSnapshotPicker) {
            SnapshotPickerView()
        }
        .sheet(isPresented: $ui.showDiff) {
            SnapshotDiffView()
        }
        .sheet(isPresented: $ui.showFolderCompare) {
            FolderCompareView()
        }
        .sheet(isPresented: $ui.showStorageAnalysis) {
            StorageAnalysisView()
        }
        .sheet(isPresented: $ui.showCleanupQueue) {
            CleanupQueueView()
        }
        .sheet(isPresented: $ui.showAlertRuleResults) {
            AlertRuleResultsView()
        }
        .sheet(isPresented: $ui.showSettingsPanel) {
            MainSettingsPanel()
        }
        .sheet(isPresented: $ui.showBackupSettings) {
            if let location = ui.backupLocation {
                BackupSettingsView(location: location)
            }
        }
        .sheet(isPresented: $ui.showSelectionBackup) {
            SelectionBackupView(entries: ui.selectionBackupEntries)
        }
        .overlay(alignment: .bottom) {
            VStack(spacing: 8) {
                AutoRescanBanner()
                ScanChangeSummaryBanner { ui.showDiff = true }
                AlertRuleBanner { ui.showAlertRuleResults = true }
                BackupProgressBanner()
            }
        }
    }

    private var motionEnabled: Bool {
        !motion.reduceMotion && !systemReduceMotion
    }
}

private struct FullSurfaceGlassBackdrop: NSViewRepresentable {
    let isGlowAnimated: Bool

    func makeNSView(context: Context) -> FullSurfaceGlassBackdropView {
        let view = FullSurfaceGlassBackdropView()
        view.setGlowAnimated(isGlowAnimated)
        return view
    }

    func updateNSView(_ view: FullSurfaceGlassBackdropView, context: Context) {
        view.setGlowAnimated(isGlowAnimated)
    }
}

private final class FullSurfaceGlassBackdropView: NSVisualEffectView {
    private let glowLayer = CAGradientLayer()
    private let sparkLayer = CALayer()
    private var isGlowAnimated = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    override func layout() {
        super.layout()
        // The glow rotates continuously, so keep it well beyond every visible edge.
        let horizontalInset = max(bounds.width * 0.85, 400)
        let verticalInset = max(bounds.height * 0.85, 400)
        let frame = bounds.insetBy(dx: -horizontalInset, dy: -verticalInset)
        guard glowLayer.frame != frame else { return }

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        glowLayer.frame = frame
        sparkLayer.frame = bounds
        CATransaction.commit()
        updateGlowAnimation()
        rebuildSparks()
    }

    func setGlowAnimated(_ animated: Bool) {
        guard isGlowAnimated != animated else { return }
        isGlowAnimated = animated
        updateGlowAnimation()
        rebuildSparks()
    }

    private func configure() {
        material = .sidebar
        blendingMode = .behindWindow
        state = .active
        wantsLayer = true
        layer?.masksToBounds = true

        glowLayer.startPoint = CGPoint(x: 0, y: 0.10)
        glowLayer.endPoint = CGPoint(x: 1, y: 0.90)
        glowLayer.locations = [0, 0.12, 0.34, 0.56, 0.78, 1]
        glowLayer.colors = [
            NSColor.clear.cgColor,
            NSColor.systemTeal.withAlphaComponent(0.26).cgColor,
            NSColor.systemCyan.withAlphaComponent(0.38).cgColor,
            NSColor.systemBlue.withAlphaComponent(0.30).cgColor,
            NSColor.systemPink.withAlphaComponent(0.18).cgColor,
            NSColor.clear.cgColor
        ]
        layer?.insertSublayer(glowLayer, at: 0)
        layer?.insertSublayer(sparkLayer, above: glowLayer)
    }

    private func updateGlowAnimation() {
        glowLayer.removeAnimation(forKey: "fullSurfaceGlowOpacity")
        glowLayer.removeAnimation(forKey: "fullSurfaceGlowRotation")
        glowLayer.opacity = isGlowAnimated ? 0.78 : 0.40

        guard isGlowAnimated, bounds.width > 0 else { return }

        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0.62
        animation.toValue = 0.78
        animation.duration = 1.6
        animation.autoreverses = true
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        glowLayer.add(animation, forKey: "fullSurfaceGlowOpacity")

        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.fromValue = 0
        rotation.toValue = CGFloat.pi * 2
        rotation.duration = 12
        rotation.repeatCount = .infinity
        rotation.timingFunction = CAMediaTimingFunction(name: .linear)
        glowLayer.add(rotation, forKey: "fullSurfaceGlowRotation")
    }

    private func rebuildSparks() {
        sparkLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        guard isGlowAnimated, bounds.width > 0, bounds.height > 0 else { return }

        let colors = [
            NSColor.systemCyan.cgColor,
            NSColor.systemTeal.cgColor,
            NSColor.systemBlue.cgColor,
            NSColor.systemPink.cgColor,
            NSColor.systemPurple.cgColor,
            NSColor.systemYellow.cgColor,
            NSColor.systemOrange.cgColor,
            NSColor.systemGreen.cgColor
        ]

        for index in 0..<108 {
            let spark = CAShapeLayer()
            let size = CGFloat(3 + (index * 5) % 5)
            spark.path = CGPath(ellipseIn: CGRect(x: -size / 2, y: -size / 2, width: size, height: size), transform: nil)
            spark.fillColor = colors[(index * 3 + index / 8) % colors.count]
            spark.shadowColor = spark.fillColor
            spark.shadowRadius = 10
            spark.shadowOpacity = 1
            spark.opacity = 0

            let center = sparkCenter(for: index)
            let end = sparkEnd(from: center, index: index)
            spark.position = center
            sparkLayer.addSublayer(spark)

            let movement = CAKeyframeAnimation(keyPath: "position")
            movement.values = [center, midpoint(from: center, to: end, index: index), end]
            movement.keyTimes = [0, 0.42, 1]

            let fade = CAKeyframeAnimation(keyPath: "opacity")
            fade.values = [0, 0.98, 0]
            fade.keyTimes = [0, 0.12, 1]

            let scale = CAKeyframeAnimation(keyPath: "transform.scale")
            scale.values = [0.35, 1.25, 0.45]
            scale.keyTimes = [0, 0.14, 1]

            let group = CAAnimationGroup()
            group.animations = [movement, fade, scale]
            group.duration = 4.4 + Double((index * 3) % 6) * 0.35
            group.repeatCount = .infinity
            group.timeOffset = group.duration * Double(index % 16) / 16
            group.timingFunction = CAMediaTimingFunction(name: .easeOut)
            spark.add(group, forKey: "glassSpark")
        }
    }

    private func sparkCenter(for index: Int) -> CGPoint {
        let horizontal = CGFloat((index * 47 + 13) % 97) / 96
        let vertical = CGFloat((index * 29 + 31) % 89) / 88
        return CGPoint(
            x: bounds.width * (0.035 + horizontal * 0.93),
            y: bounds.height * (0.05 + vertical * 0.90)
        )
    }

    private func sparkEnd(from center: CGPoint, index: Int) -> CGPoint {
        let angle = CGFloat((index * 73) % 360) * (.pi / 180)
        let distance = CGFloat(28 + (index * 11) % 44)
        return CGPoint(x: center.x + cos(angle) * distance, y: center.y + sin(angle) * distance)
    }

    private func midpoint(from start: CGPoint, to end: CGPoint, index: Int) -> CGPoint {
        CGPoint(
            x: (start.x + end.x) / 2 + CGFloat((index % 3) - 1) * 8,
            y: (start.y + end.y) / 2 + CGFloat((index % 5) - 2) * 5
        )
    }
}

private struct FirstLaunchHelpView: View {
    @Environment(IndexViewModel.self) private var vm
    @Environment(LanguageManager.self) private var language
    @Environment(MotionPreferences.self) private var motion
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @State private var hasAppeared = false

    private var content: FirstLaunchHelpContent {
        FirstLaunchHelpContent(language: language.effectiveLanguage)
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder.badge.gearshape")
                .font(.system(size: 58, weight: .medium))
                .foregroundStyle(AppTheme.theme.accentColor)

            Text(content.title)
                .font(.largeTitle.bold())

            Text(content.introduction)
                .font(.title3)
                .foregroundStyle(AppTheme.theme.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 580)

            HStack(spacing: 12) {
                Button {
                    vm.addFolders()
                } label: {
                    Label(content.addFolderTitle, systemImage: "folder.badge.plus")
                }
                .buttonStyle(.borderedProminent)

                Button {
                    FirstLaunchHelpAction.openManual(for: language.effectiveLanguage)
                } label: {
                    Label(content.manualButtonTitle, systemImage: "book")
                }
                .buttonStyle(.bordered)
            }

            VStack(spacing: 10) {
                Text(content.aiHeading)
                    .font(.headline)

                HStack(spacing: 12) {
                    ForEach(FirstLaunchAIService.allCases) { service in
                        FirstLaunchAIServiceButton(service: service) {
                            FirstLaunchHelpAction.copyPromptAndOpen(
                                service,
                                language: language.effectiveLanguage
                            )
                        }
                        .fileAtlasTooltip(text: Text(verbatim: content.serviceHelp(service)))
                    }
                }
            }

            Text(content.privacyNote)
                .font(.callout)
                .foregroundStyle(AppTheme.theme.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 620)
        }
        .opacity(hasAppeared || !motionEnabled ? 1 : 0)
        .offset(y: hasAppeared || !motionEnabled ? 0 : 18)
        .scaleEffect(hasAppeared || !motionEnabled ? 1 : 0.985)
        .animation(motionEnabled ? FileAtlasMotion.staged : nil, value: hasAppeared)
        .padding(36)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task { hasAppeared = true }
    }

    private var motionEnabled: Bool {
        !motion.reduceMotion && !systemReduceMotion
    }
}

private struct FirstLaunchAIServiceButton: View {
    @Environment(MotionPreferences.self) private var motion
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    let service: FirstLaunchAIService
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                AIServiceLogo(service: service)
                    .offset(y: isMotionEnabled && isHovered ? -1 : 0)
                Text(service.title)
            }
        }
        .buttonStyle(.bordered)
        .scaleEffect(isMotionEnabled && isHovered ? 1.025 : 1)
        .offset(y: isMotionEnabled && isHovered ? -2 : 0)
        .shadow(
            color: isMotionEnabled && isHovered ? AppTheme.theme.accentColor.opacity(0.24) : .clear,
            radius: 7,
            y: 3
        )
        .animation(isMotionEnabled ? FileAtlasMotion.quick : nil, value: isHovered)
        .onHover { isHovered = $0 }
    }

    private var isMotionEnabled: Bool {
        !motion.reduceMotion && !systemReduceMotion
    }
}

private struct AIServiceLogo: View {
    let service: FirstLaunchAIService

    var body: some View {
        Image(nsImage: image)
            .resizable()
            .scaledToFit()
            .frame(width: 18, height: 18)
            .accessibilityHidden(true)
    }

    private var image: NSImage {
        guard let url = Bundle.main.url(
            forResource: service.logoResource.name,
            withExtension: service.logoResource.fileExtension
        ) else {
            return NSImage()
        }
        return NSImage(contentsOf: url) ?? NSImage()
    }
}

private struct AlertRuleBanner: View {
    @Environment(IndexViewModel.self) private var vm
    let showDetails: () -> Void

    var body: some View {
        if vm.alertRuleMatchCount > 0 {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(AppTheme.gold)
                Text("Rules found \(vm.alertRuleMatchCount) matching item(s)")
                    .font(.callout)
                Button("Show") { showDetails() }
                    .controlSize(.small)
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(.regularMaterial, in: Capsule())
            .overlay(Capsule().stroke(AppTheme.stroke, lineWidth: 0.5))
            .padding(.bottom, 12)
        }
    }
}

private struct ScanChangeSummaryBanner: View {
    @Environment(IndexViewModel.self) private var vm
    let showDetails: () -> Void

    var body: some View {
        if let summary = vm.latestScanSummary {
            HStack(spacing: 8) {
                Image(systemName: summary.diff.isEmpty ? "checkmark.circle.fill" : "arrow.triangle.2.circlepath.circle.fill")
                    .foregroundStyle(summary.diff.isEmpty ? AppTheme.theme.accentColor : AppTheme.gold)
                Text(summary.diff.isEmpty
                    ? "No changes since the last scan"
                    : "Since last scan: \(summary.addedCount) new, \(summary.changedCount) changed, \(summary.removedCount) removed")
                    .font(.callout)
                if !summary.diff.isEmpty {
                    Button("Details") {
                        vm.showLatestScanChanges()
                        showDetails()
                    }
                    .controlSize(.small)
                }
                Button {
                    vm.dismissLatestScanSummary()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppTheme.theme.textSecondary)
                .fileAtlasTooltip("Dismiss")
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(.regularMaterial, in: Capsule())
            .overlay(Capsule().stroke(AppTheme.stroke, lineWidth: 0.5))
            .padding(.bottom, 12)
        }
    }
}

private struct AutoRescanBanner: View {
    @Environment(IndexViewModel.self) private var vm

    var body: some View {
        if let message = vm.lastAutoRescanMessage {
            HStack(spacing: 8) {
                Image(systemName: "arrow.clockwise.circle.fill")
                    .foregroundStyle(AppTheme.theme.accentColor)
                Text(message).font(.callout)
                Button {
                    vm.clearAutoRescanMessage()
                } label: { Image(systemName: "xmark.circle.fill") }
                    .buttonStyle(.plain)
                    .foregroundStyle(AppTheme.theme.textSecondary)
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(.regularMaterial, in: Capsule())
            .overlay(Capsule().stroke(AppTheme.stroke, lineWidth: 0.5))
            .padding(.bottom, 12)
        }
    }
}

/// Schmales Statusband am unteren Rand, während ein Backup läuft / nach Abschluss.
private struct BackupProgressBanner: View {
    @Environment(BackupManager.self) private var backup
    @Environment(MotionPreferences.self) private var motion
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    var body: some View {
        Group {
            if backup.isBackingUp {
                HStack(spacing: 10) {
                ProgressView(value: backup.progressFraction)
                    .frame(width: 140)
                    .animation(motionEnabled ? FileAtlasMotion.quick : nil, value: backup.progressFraction)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Backing up \(backup.activeSourceName)…")
                        .font(.callout.weight(.medium))
                    if !backup.currentItemName.isEmpty {
                        Text(backup.currentItemName)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .contentTransition(motionEnabled ? .opacity : .identity)
                    } else {
                        Text(backup.progressLabel)
                    }
                }
                .font(.caption)
                .foregroundStyle(AppTheme.theme.textSecondary)
                Text(backup.progressLabel)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(AppTheme.theme.textSecondary)
                    .contentTransition(motionEnabled ? .numericText() : .identity)
                if backup.isCancelling {
                    Label("Cancelling…", systemImage: "arrow.triangle.2.circlepath")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppTheme.theme.textSecondary)
                        .transition(.opacity.combined(with: .scale(scale: 0.94)))
                } else {
                    Button("Cancel") {
                        backup.cancelBackup()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .transition(.opacity.combined(with: .scale(scale: 0.94)))
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(.regularMaterial, in: Capsule())
            .overlay(Capsule().stroke(AppTheme.stroke, lineWidth: 0.5))
                .padding(.bottom, 12)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else if let message = backup.statusMessage {
                HStack(spacing: 10) {
                Image(systemName: backup.completedBackup == nil ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                    .foregroundStyle(backup.completedBackup == nil ? AppTheme.gold : AppTheme.theme.accentColor)
                    .symbolEffect(.bounce, value: backup.completedBackup != nil)
                VStack(alignment: .leading, spacing: 2) {
                    Text(message).font(.callout.weight(.medium))
                    if let completion = backup.completedBackup {
                        HStack(spacing: 7) {
                            Text(String(format: NSLocalizedString("%lld files", comment: ""), completion.itemCount))
                            Text(ByteCountFormatter.string(fromByteCount: completion.archiveSize, countStyle: .file))
                            Text(completion.destinationName)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(AppTheme.theme.textSecondary)
                        .contentTransition(motionEnabled ? .numericText() : .identity)
                    }
                }
                Button {
                    backup.dismissStatusMessage()
                } label: { Image(systemName: "xmark.circle.fill") }
                    .buttonStyle(.plain)
                    .foregroundStyle(AppTheme.theme.textSecondary)
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(.regularMaterial, in: Capsule())
            .overlay(Capsule().stroke(AppTheme.stroke, lineWidth: 0.5))
                .padding(.bottom, 12)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(motionEnabled ? FileAtlasMotion.standard : nil, value: backup.isBackingUp)
        .animation(motionEnabled ? FileAtlasMotion.quick : nil, value: backup.isCancelling)
        .animation(motionEnabled ? FileAtlasMotion.quick : nil, value: backup.statusMessage)
    }

    private var motionEnabled: Bool {
        !motion.reduceMotion && !systemReduceMotion
    }
}

#Preview {
    ContentView()
        .environment(IndexViewModel())
        .environment(AppearanceManager())
        .environment(LanguageManager())
        .environment(MotionPreferences())
        .environment(TooltipPreferences())
        .environment(UIState())
        .environment(BackupManager())
        .frame(width: 1100, height: 720)
        .preferredColorScheme(.dark)
}
