//
//  SystemFileIconView.swift
//  FileAtlas
//
//  Lazy geladene System-Icons für Dateien, Apps und Ordner.
//

import SwiftUI
import AppKit

struct SystemFileIconView: View {
    @Environment(IndexViewModel.self) private var vm

    let entry: FileEntry
    var size: CGFloat = 16

    @State private var icon: NSImage?

    var body: some View {
        Group {
            if vm.iconDisplayMode == .real, let icon {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                genericIcon
            }
        }
        .frame(width: size, height: size)
        .task(id: taskKey) {
            guard vm.iconDisplayMode == .real else {
                icon = nil
                return
            }
            icon = await SystemFileIconCache.shared.icon(for: entry)
        }
    }

    private var genericIcon: some View {
        Image(systemName: FileRowView.icon(for: entry))
            .font(.system(size: max(12, size - 2)))
            .foregroundStyle(AppTheme.theme.accentColor)
    }

    private var taskKey: String {
        vm.iconDisplayMode.rawValue + ":" + cacheKey
    }

    private var cacheKey: String {
        SystemFileIconCache.cacheKey(for: entry)
    }
}

private actor SystemFileIconCache {
    static let shared = SystemFileIconCache()

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
        if entry.isDirectory || FilterPreset.normalize(entry.fileExtension) == "app" {
            return "path:" + entry.path.path(percentEncoded: false)
        }

        let ext = FilterPreset.normalize(entry.fileExtension)
        return ext.isEmpty ? "path:" + entry.path.path(percentEncoded: false) : "ext:" + ext
    }
}
