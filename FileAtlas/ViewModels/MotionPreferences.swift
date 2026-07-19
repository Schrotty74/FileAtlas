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
