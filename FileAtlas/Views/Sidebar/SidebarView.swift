//
//  SidebarView.swift
//  FileAtlas
//
//  Native macOS sidebar material with SwiftUI sidebar content hosted inside it.
//

import SwiftUI
import AppKit

struct SidebarView: View {
    @Environment(IndexViewModel.self) private var vm
    @Environment(BackupManager.self) private var backup
    @Environment(UIState.self) private var ui
    @Environment(AppearanceManager.self) private var appearance
    @Environment(LanguageManager.self) private var language
    @Environment(\.locale) private var locale

    var body: some View {
        NativeSidebarContainer {
            SidebarContent()
                .environment(vm)
                .environment(backup)
                .environment(ui)
                .environment(appearance)
                .environment(language)
                .environment(\.locale, locale)
        }
    }
}

private struct SidebarContent: View {
    @Environment(IndexViewModel.self) private var vm

    var body: some View {
        @Bindable var vm = vm

        List {
            header

            RecentLocationsSection()
            SavedLocationsSection()
            PresetsSection()

            if vm.duplicateCount > 0 {
                Section {
                    Toggle(isOn: $vm.showOnlyDuplicates) {
                        Label("Only duplicates", systemImage: "doc.on.doc")
                    }
                    .toggleStyle(.switch)
                    .tint(AppTheme.theme.accentColor)
                } header: {
                    Text("Duplicates")
                }
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            AppearanceToggle()
        }
        .tint(AppTheme.theme.accentColor)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "chart.pie.fill")
            Text("FileAtlas")
                .font(.headline)
        }
        .foregroundStyle(AppTheme.theme.accentColor)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .listRowInsets(EdgeInsets(top: 6, leading: 4, bottom: 10, trailing: 4))
        .listRowSeparator(.hidden)
        .listRowBackground(EmptyView())
    }
}

private struct NativeSidebarContainer<Content: View>: NSViewRepresentable {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    func makeNSView(context: Context) -> NativeSidebarRootView<Content> {
        let view = NativeSidebarRootView<Content>()
        view.setRootView(content)
        return view
    }

    func updateNSView(_ nsView: NativeSidebarRootView<Content>, context: Context) {
        nsView.setRootView(content)
        nsView.scheduleReconfigure()
    }
}

private final class NativeSidebarRootView<Content: View>: NSVisualEffectView {
    private var hostingView: NSHostingView<Content>?
    private var isReconfigureScheduled = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        configureMaterial()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureMaterial()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        scheduleReconfigure()
    }

    override func layout() {
        super.layout()
        scheduleReconfigure()
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        scheduleReconfigure()
    }

    func setRootView(_ rootView: Content) {
        if let hostingView {
            hostingView.rootView = rootView
        } else {
            let hostingView = NSHostingView(rootView: rootView)
            hostingView.translatesAutoresizingMaskIntoConstraints = false
            hostingView.wantsLayer = true
            hostingView.layer?.backgroundColor = NSColor.clear.cgColor
            addSubview(hostingView)

            NSLayoutConstraint.activate([
                hostingView.leadingAnchor.constraint(equalTo: leadingAnchor),
                hostingView.trailingAnchor.constraint(equalTo: trailingAnchor),
                hostingView.topAnchor.constraint(equalTo: topAnchor),
                hostingView.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])

            self.hostingView = hostingView
        }

        scheduleReconfigure()
    }

    func scheduleReconfigure() {
        guard !isReconfigureScheduled else { return }
        isReconfigureScheduled = true

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.isReconfigureScheduled = false
            self.reconfigureSidebar()
        }
    }

    private func configureMaterial() {
        material = .sidebar
        blendingMode = .behindWindow
        state = .active
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    private func reconfigureSidebar() {
        configureMaterial()

        hostingView?.layer?.backgroundColor = NSColor.clear.cgColor
        clearHostedSwiftUIBackgrounds(in: self)
    }

    private func clearHostedSwiftUIBackgrounds(in view: NSView) {
        if let scrollView = view as? NSScrollView {
            scrollView.drawsBackground = false
            scrollView.backgroundColor = .clear
        }

        if let clipView = view as? NSClipView {
            clipView.drawsBackground = false
            clipView.backgroundColor = .clear
        }

        if let tableView = view as? NSTableView {
            tableView.backgroundColor = .clear
            tableView.usesAlternatingRowBackgroundColors = false
        }

        if let visualEffectView = view as? NSVisualEffectView, visualEffectView !== self {
            visualEffectView.material = .sidebar
            visualEffectView.blendingMode = .behindWindow
            visualEffectView.state = .active
        }

        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.clear.cgColor

        for subview in view.subviews {
            clearHostedSwiftUIBackgrounds(in: subview)
        }
    }
}
