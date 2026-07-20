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
    @Environment(MotionPreferences.self) private var motion
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    var body: some View {
        if appearance.colorTheme == .glass {
            sidebarContent
                .background(AppTheme.windowBackground)
        } else {
            NativeSidebarContainer(theme: appearance.colorTheme, isGlowAnimated: isGlowAnimated) {
                sidebarContent
            }
        }
    }

    private var sidebarContent: some View {
        SidebarContent()
            .environment(vm)
            .environment(backup)
            .environment(ui)
            .environment(appearance)
            .environment(language)
            .environment(\.locale, locale)
    }

    private var isGlowAnimated: Bool {
        !motion.reduceMotion && !systemReduceMotion && !vm.isScanning && appearance.colorTheme != .glass
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
            SmartCollectionsSection()

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
    let theme: ColorTheme
    let isGlowAnimated: Bool

    init(theme: ColorTheme, isGlowAnimated: Bool, @ViewBuilder content: () -> Content) {
        self.theme = theme
        self.isGlowAnimated = isGlowAnimated
        self.content = content()
    }

    func makeNSView(context: Context) -> NativeSidebarRootView<Content> {
        let view = NativeSidebarRootView<Content>()
        view.setRootView(content)
        view.setTheme(theme)
        view.setGlowAnimated(isGlowAnimated)
        return view
    }

    func updateNSView(_ nsView: NativeSidebarRootView<Content>, context: Context) {
        nsView.setRootView(content)
        nsView.setTheme(theme)
        nsView.setGlowAnimated(isGlowAnimated)
        nsView.scheduleReconfigure()
    }
}

private final class NativeSidebarRootView<Content: View>: NSVisualEffectView {
    private var hostingView: NSHostingView<Content>?
    private var isReconfigureScheduled = false
    private let glowLayer = CAGradientLayer()
    private let particleLayer = CALayer()
    private var isGlowAnimated = false
    private var theme: ColorTheme = .midnightTeal

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
        layoutGlowLayer()
        layoutParticleLayer()
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

    func setGlowAnimated(_ animated: Bool) {
        guard isGlowAnimated != animated else { return }
        isGlowAnimated = animated
        updateGlowAnimation()
        updateParticleAnimation()
    }

    func setTheme(_ theme: ColorTheme) {
        guard self.theme != theme else { return }
        self.theme = theme
        configureGlowColors()
        rebuildParticles()
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
        layer?.masksToBounds = true
        configureGlowColors()

        if glowLayer.superlayer == nil {
            layer?.insertSublayer(glowLayer, at: 0)
        }
        if particleLayer.superlayer == nil {
            layer?.insertSublayer(particleLayer, above: glowLayer)
        }
    }

    private func reconfigureSidebar() {
        configureMaterial()

        hostingView?.layer?.backgroundColor = NSColor.clear.cgColor
        clearHostedSwiftUIBackgrounds(in: self)
    }

    private func configureGlowColors() {
        glowLayer.startPoint = CGPoint(x: 0, y: 0.15)
        glowLayer.endPoint = CGPoint(x: 1, y: 0.85)
        glowLayer.locations = [0, 0.37, 0.56, 1]
        let colors: (NSColor, NSColor)
        switch theme {
        case .midnightTeal:
            colors = (.systemTeal, .systemCyan)
        case .retro:
            colors = (NSColor(red: 0.82, green: 0.50, blue: 0.20, alpha: 1), NSColor(red: 0.48, green: 0.62, blue: 0.38, alpha: 1))
        case .graphiteLime:
            colors = (NSColor(red: 0.50, green: 0.82, blue: 0.20, alpha: 1), NSColor(red: 0.72, green: 0.94, blue: 0.30, alpha: 1))
        case .autumn:
            colors = (NSColor(red: 0.82, green: 0.29, blue: 0.16, alpha: 1), NSColor(red: 0.92, green: 0.62, blue: 0.15, alpha: 1))
        case .winter:
            colors = (NSColor(red: 0.30, green: 0.68, blue: 0.90, alpha: 1), NSColor.white)
        case .glass:
            colors = (.systemTeal, .systemCyan)
        }
        glowLayer.colors = [
            NSColor.clear.cgColor,
            colors.0.withAlphaComponent(0.07).cgColor,
            colors.1.withAlphaComponent(0.18).cgColor,
            NSColor.clear.cgColor
        ]
    }

    private func layoutGlowLayer() {
        let horizontalInset = max(bounds.width * 0.7, 180)
        let verticalInset = max(bounds.height * 0.12, 80)
        let frame = bounds.insetBy(dx: -horizontalInset, dy: -verticalInset)
        guard glowLayer.frame != frame else { return }

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        glowLayer.frame = frame
        CATransaction.commit()
        updateGlowAnimation()
    }

    private func updateGlowAnimation() {
        glowLayer.removeAnimation(forKey: "sidebarGlow")

        guard theme != .glass else {
            glowLayer.opacity = 0
            return
        }

        glowLayer.opacity = isGlowAnimated ? 1 : 0.45

        guard isGlowAnimated, bounds.width > 0 else { return }

        let offset = max(bounds.width * 0.75, 180)
        let animation = CABasicAnimation(keyPath: "transform.translation.x")
        animation.fromValue = -offset
        animation.toValue = offset
        animation.duration = 12
        animation.autoreverses = true
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        glowLayer.add(animation, forKey: "sidebarGlow")
    }

    private func layoutParticleLayer() {
        guard particleLayer.frame != bounds else { return }

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        particleLayer.frame = bounds
        CATransaction.commit()
        rebuildParticles()
    }

    private func updateParticleAnimation() {
        if isGlowAnimated {
            rebuildParticles()
        } else {
            particleLayer.sublayers?.forEach { $0.removeAllAnimations() }
            particleLayer.sublayers?.forEach { $0.isHidden = true }
        }
    }

    private func rebuildParticles() {
        particleLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        guard isGlowAnimated, bounds.width > 0, bounds.height > 0 else { return }

        switch theme {
        case .midnightTeal:
            break
        case .retro:
            addDustParticles()
        case .graphiteLime:
            addLimeFireflies()
        case .autumn:
            addAutumnLeaves()
        case .winter:
            addSnowflakes()
        case .glass:
            break
        }
    }

    private func addDustParticles() {
        let color = NSColor(red: 0.90, green: 0.68, blue: 0.32, alpha: 1).cgColor
        for index in 0..<15 {
            let size = CGFloat(3 + (index * 5) % 4)
            let path = CGPath(ellipseIn: CGRect(x: -size / 2, y: -size / 2, width: size, height: size), transform: nil)
            addParticle(path: path, color: color, index: index, count: 15, duration: 12 + Double((index * 3) % 5), start: dustStart(index), end: dustEnd(index), rotation: 0, drift: CGFloat((index % 4) - 2) * 12, peakOpacity: 0.48)
        }
    }

    private func addLimeFireflies() {
        let colors = [
            NSColor(red: 0.74, green: 0.96, blue: 0.32, alpha: 1).cgColor,
            NSColor(red: 0.42, green: 0.82, blue: 0.18, alpha: 1).cgColor
        ]
        for index in 0..<10 {
            let size = CGFloat(3 + (index * 3) % 4)
            let path = CGPath(ellipseIn: CGRect(x: -size / 2, y: -size / 2, width: size, height: size), transform: nil)
            addParticle(path: path, color: colors[index % colors.count], index: index, count: 10, duration: 11 + Double((index * 5) % 5), start: fireflyStart(index), end: fireflyEnd(index), rotation: 0, drift: CGFloat(index.isMultiple(of: 2) ? 24 : -24), peakOpacity: 0.42, glow: true)
        }
    }

    private func addAutumnLeaves() {
        let colors = [
            NSColor(red: 0.95, green: 0.67, blue: 0.13, alpha: 1).cgColor,
            NSColor(red: 0.88, green: 0.38, blue: 0.10, alpha: 1).cgColor,
            NSColor(red: 0.72, green: 0.16, blue: 0.10, alpha: 1).cgColor,
            NSColor(red: 0.61, green: 0.31, blue: 0.08, alpha: 1).cgColor,
            NSColor(red: 0.77, green: 0.48, blue: 0.12, alpha: 1).cgColor
        ]
        for index in 0..<7 {
            let rotation: CGFloat = index.isMultiple(of: 2) ? CGFloat.pi * 2 : -CGFloat.pi * 2
            let scale = CGFloat(1.35 + Double((index * 7) % 6) * 0.16)
            addParticle(
                path: leafPath(scale: scale),
                color: colors[index % colors.count],
                index: index,
                count: 7,
                duration: 10.5 + Double((index * 5) % 5) * 1.15,
                start: leafStart(index),
                end: leafEnd(index),
                rotation: rotation,
                drift: index.isMultiple(of: 2) ? 32 : -38
            )
        }
    }

    private func addSnowflakes() {
        let colors = [NSColor.white.cgColor, NSColor.systemCyan.cgColor]
        for index in 0..<12 {
            let scale = CGFloat(1.35 + Double((index * 5) % 5) * 0.18)
            addParticle(
                path: snowflakePath(scale: scale),
                color: colors[index % colors.count],
                index: index,
                count: 12,
                duration: 9.5 + Double((index * 7) % 6) * 1.05,
                start: snowStart(index),
                end: snowEnd(index),
                rotation: .pi,
                drift: CGFloat((index % 4) - 2) * 18
            )
        }
    }

    private func addParticle(path: CGPath, color: CGColor, index: Int, count: Int, duration: CFTimeInterval, start: CGPoint, end: CGPoint, rotation: CGFloat, drift: CGFloat = 0, peakOpacity: CGFloat? = nil, glow: Bool = false) {
        let particle = CAShapeLayer()
        particle.path = path
        particle.fillColor = color
        particle.strokeColor = color
        particle.lineWidth = 0.8
        particle.opacity = 0
        particle.position = start
        if glow {
            particle.shadowColor = color
            particle.shadowRadius = 6
            particle.shadowOpacity = 0.85
        }
        particleLayer.addSublayer(particle)

        let movement = CAKeyframeAnimation(keyPath: "position")
        let midpoint = CGPoint(
            x: (start.x + end.x) / 2 + drift,
            y: (start.y + end.y) / 2 + CGFloat((index % 3) - 1) * 20
        )
        movement.values = [start, midpoint, end]
        movement.keyTimes = [0, 0.52, 1]

        let fade = CAKeyframeAnimation(keyPath: "opacity")
        let resolvedPeakOpacity = peakOpacity ?? (0.24 + CGFloat((index * 3) % 4) * 0.035)
        fade.values = [0, resolvedPeakOpacity, resolvedPeakOpacity * 0.76, 0]
        fade.keyTimes = [0, 0.14, 0.79, 1]

        let turn = CABasicAnimation(keyPath: "transform.rotation")
        turn.fromValue = 0
        turn.toValue = rotation

        let group = CAAnimationGroup()
        group.animations = [movement, fade, turn]
        group.duration = duration
        group.repeatCount = .infinity
        group.timeOffset = duration * Double(index) / Double(count)
        group.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        particle.add(group, forKey: "sidebarParticle")
    }

    private func leafPath(scale: CGFloat) -> CGPath {
        let radius = 6 * scale
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: -radius))
        path.addCurve(to: CGPoint(x: radius * 0.82, y: 0), control1: CGPoint(x: radius * 0.68, y: -radius * 0.86), control2: CGPoint(x: radius, y: -radius * 0.32))
        path.addCurve(to: CGPoint(x: 0, y: radius), control1: CGPoint(x: radius * 0.68, y: radius * 0.42), control2: CGPoint(x: radius * 0.18, y: radius))
        path.addCurve(to: CGPoint(x: -radius * 0.82, y: 0), control1: CGPoint(x: -radius * 0.34, y: radius * 0.84), control2: CGPoint(x: -radius, y: radius * 0.30))
        path.addCurve(to: CGPoint(x: 0, y: -radius), control1: CGPoint(x: -radius * 0.70, y: -radius * 0.43), control2: CGPoint(x: -radius * 0.18, y: -radius))
        return path
    }

    private func snowflakePath(scale: CGFloat) -> CGPath {
        let radius = 4 * scale
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -radius, y: 0))
        path.addLine(to: CGPoint(x: radius, y: 0))
        path.move(to: CGPoint(x: 0, y: -radius))
        path.addLine(to: CGPoint(x: 0, y: radius))
        path.move(to: CGPoint(x: -radius * 0.7, y: -radius * 0.7))
        path.addLine(to: CGPoint(x: radius * 0.7, y: radius * 0.7))
        path.move(to: CGPoint(x: -radius * 0.7, y: radius * 0.7))
        path.addLine(to: CGPoint(x: radius * 0.7, y: -radius * 0.7))
        return path
    }

    private func dustStart(_ index: Int) -> CGPoint {
        CGPoint(x: bounds.width * CGFloat((index * 7) % 17 + 1) / 18, y: bounds.height * CGFloat((index * 3) % 13) / 13)
    }

    private func dustEnd(_ index: Int) -> CGPoint {
        CGPoint(x: dustStart(index).x + CGFloat((index % 5) - 2) * 18, y: dustStart(index).y - 105)
    }

    private func fireflyStart(_ index: Int) -> CGPoint {
        CGPoint(x: bounds.width * CGFloat((index * 7) % 12 + 1) / 13, y: bounds.height * CGFloat((index * 5) % 11 + 1) / 12)
    }

    private func fireflyEnd(_ index: Int) -> CGPoint {
        CGPoint(x: fireflyStart(index).x + CGFloat((index % 3) - 1) * 38, y: fireflyStart(index).y + CGFloat((index % 4) - 2) * 30)
    }

    private func leafStart(_ index: Int) -> CGPoint {
        CGPoint(
            x: bounds.width * CGFloat((index * 5) % 9 + 1) / 10,
            y: bounds.height + 20 + CGFloat((index * 11) % 4) * 34
        )
    }

    private func leafEnd(_ index: Int) -> CGPoint {
        CGPoint(
            x: leafStart(index).x + (index.isMultiple(of: 2) ? 58 : -64),
            y: -24 - CGFloat((index * 7) % 3) * 26
        )
    }

    private func snowStart(_ index: Int) -> CGPoint {
        CGPoint(
            x: bounds.width * CGFloat((index * 7) % 15 + 1) / 16,
            y: bounds.height + 16 + CGFloat((index * 13) % 5) * 28
        )
    }

    private func snowEnd(_ index: Int) -> CGPoint {
        CGPoint(
            x: snowStart(index).x + CGFloat((index % 5) - 2) * 26,
            y: -18 - CGFloat((index * 3) % 4) * 22
        )
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
