//
//  SystemFileIconView.swift
//  FileAtlas
//
//  Lazy geladene System-Icons für Dateien, Apps und Ordner.
//

import SwiftUI
import AppKit

struct SystemFileIconView: View {
    let entry: FileEntry
    var size: CGFloat = 16
    var iconDisplayMode: IconDisplayMode = .real

    @State private var icon: NSImage?

    var body: some View {
        Group {
            if iconDisplayMode == .real,
               !SystemFileIconCache.usesFallbackIcon(for: entry),
               let icon {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                genericIcon
            }
        }
        .frame(width: size, height: size)
        .task(id: taskKey) {
            guard iconDisplayMode == .real,
                  !SystemFileIconCache.usesFallbackIcon(for: entry) else {
                icon = nil
                return
            }
            icon = await SystemFileIconCache.shared.icon(for: entry)
        }
    }

    private var genericIcon: some View {
        Image(systemName: fallbackIconName)
            .font(.system(size: max(12, size - 2)))
            .foregroundStyle(fallbackIconColor)
    }

    private var taskKey: String {
        iconDisplayMode.rawValue + ":" + cacheKey
    }

    private var cacheKey: String {
        SystemFileIconCache.cacheKey(for: entry)
    }

    private var fallbackIconName: String {
        if iconDisplayMode == .real, SystemFileIconCache.usesFallbackIcon(for: entry) {
            return "film"
        }
        return FileRowView.icon(for: entry)
    }

    private var fallbackIconColor: Color {
        if iconDisplayMode == .real, SystemFileIconCache.usesFallbackIcon(for: entry) {
            return AppTheme.gold
        }
        return AppTheme.theme.accentColor
    }
}

private actor SystemFileIconCache {
    static let shared = SystemFileIconCache()
    private nonisolated static let fallbackIconExtensions: Set<String> = ["mkv"]

    private var icons: [String: NSImage] = [:]

    func icon(for entry: FileEntry) -> NSImage {
        let key = Self.cacheKey(for: entry)
        if let cached = icons[key] {
            return cached
        }

        let image = NSWorkspace.shared.icon(forFile: entry.path.path(percentEncoded: false))
        icons[key] = image
        return image
    }

    nonisolated static func cacheKey(for entry: FileEntry) -> String {
        if usesFallbackIcon(for: entry) {
            return "fallback-ext:" + FilterPreset.normalize(entry.fileExtension)
        }

        if entry.isDirectory || FilterPreset.normalize(entry.fileExtension) == "app" {
            return "path:" + entry.path.path(percentEncoded: false)
        }

        let ext = FilterPreset.normalize(entry.fileExtension)
        return ext.isEmpty ? "path:" + entry.path.path(percentEncoded: false) : "ext:" + ext
    }

    nonisolated static func usesFallbackIcon(for entry: FileEntry) -> Bool {
        fallbackIconExtensions.contains(FilterPreset.normalize(entry.fileExtension))
    }
}
