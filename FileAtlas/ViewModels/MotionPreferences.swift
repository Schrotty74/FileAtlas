//
//  MotionPreferences.swift
//  FileAtlas
//
//  Persisted user preference for non-essential interface motion.
//

import Foundation
import SwiftUI

@Observable
@MainActor
final class MotionPreferences {
    private static let reduceMotionKey = "FileAtlas.reduceMotion"
    private let defaults: UserDefaults

    var reduceMotion: Bool {
        didSet { defaults.set(reduceMotion, forKey: Self.reduceMotionKey) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        reduceMotion = defaults.bool(forKey: Self.reduceMotionKey)
    }
}

@Observable
@MainActor
final class TooltipPreferences {
    private static let showTooltipsKey = "FileAtlas.showTooltips"
    private let defaults: UserDefaults

    var showTooltips: Bool {
        didSet { defaults.set(showTooltips, forKey: Self.showTooltipsKey) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        showTooltips = defaults.object(forKey: Self.showTooltipsKey) as? Bool ?? true
    }
}

private struct FileAtlasTooltipModifier: ViewModifier {
    @Environment(TooltipPreferences.self) private var preferences
    let title: Text

    @ViewBuilder
    func body(content: Content) -> some View {
        if preferences.showTooltips {
            content.help(title)
        } else {
            content
        }
    }
}

extension View {
    func fileAtlasTooltip(_ title: LocalizedStringKey) -> some View {
        modifier(FileAtlasTooltipModifier(title: Text(title)))
    }

    func fileAtlasTooltip(text title: Text) -> some View {
        modifier(FileAtlasTooltipModifier(title: title))
    }
}

enum FileAtlasMotion {
    static let quick = Animation.easeOut(duration: 0.18)
    static let standard = Animation.easeInOut(duration: 0.28)
    static let emphasis = Animation.spring(response: 0.38, dampingFraction: 0.82)
    static let staged = Animation.spring(response: 0.48, dampingFraction: 0.78)
}

struct MotionButtonStyle: ButtonStyle {
    @Environment(MotionPreferences.self) private var motion
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(isMotionEnabled && configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.82 : 1)
            .animation(isMotionEnabled ? FileAtlasMotion.quick : nil, value: configuration.isPressed)
    }

    private var isMotionEnabled: Bool {
        !motion.reduceMotion && !systemReduceMotion
    }
}
