//
//  QuickLookPreview.swift
//  FileAtlas
//
//  Inline-Vorschau via QLPreviewView + Vollbild-Vorschau via QLPreviewPanel.
//

import SwiftUI
import Quartz
import QuickLookThumbnailing

struct QuickLookPreview: View {
    let url: URL
    let accessURL: URL?
    let fallbackIcon: String

    init(url: URL, accessURL: URL? = nil, fallbackIcon: String) {
        self.url = url
        self.accessURL = accessURL
        self.fallbackIcon = fallbackIcon
    }

    private static let unsupportedPreviewExtensions: Set<String> = [
        "app", "bundle", "framework", "xcodeproj", "xcworkspace", "playground",
        "plugin", "kext", "appex", "xpc", "qlgenerator", "prefpane", "component",
        "mdimporter", "photoslibrary", "fcpbundle", "tvlibrary", "scptd", "pkg",
        "mpkg", "dmg", "zip", "ipa", "tar", "gz", "rar", "7z"
    ]

    @State private var canPreview = false
    @State private var didFail = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppTheme.theme.cornerRadius)
                .fill(AppTheme.surfaceRaised)

            if canPreview {
                InlineQuickLookPreview(url: url, accessURL: accessURL ?? url)
                    .clipShape(.rect(cornerRadius: AppTheme.theme.cornerRadius))
            } else if didFail {
                Image(systemName: fallbackIcon)
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(AppTheme.theme.accentColor)
            } else {
                ProgressView().controlSize(.small)
            }
        }
        .frame(height: 200)
        .task(id: url) { await validatePreview() }
    }

    private func validatePreview() async {
        canPreview = false
        didFail = false

        let fileExtension = url.pathExtension.lowercased()
        guard !Self.unsupportedPreviewExtensions.contains(fileExtension) else {
            didFail = true
            return
        }

        let accessURL = accessURL ?? url
        let scoped = accessURL.startAccessingSecurityScopedResource()
        defer { if scoped { accessURL.stopAccessingSecurityScopedResource() } }

        let request = QLThumbnailGenerator.Request(
            fileAt: url,
            size: CGSize(width: 400, height: 400),
            scale: 2,
            representationTypes: .thumbnail
        )
        do {
            _ = try await QLThumbnailGenerator.shared.generateBestRepresentation(for: request)
            guard !Task.isCancelled else { return }
            canPreview = true
        } catch {
            guard !Task.isCancelled else { return }
            didFail = true
        }
    }
}

private struct InlineQuickLookPreview: NSViewRepresentable {
    let url: URL
    let accessURL: URL

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> QLPreviewView {
        let view = QLPreviewView(frame: .zero, style: .normal)
        view?.autostarts = true
        configure(view, context: context)
        return view ?? QLPreviewView()
    }

    func updateNSView(_ nsView: QLPreviewView, context: Context) {
        configure(nsView, context: context)
    }

    static func dismantleNSView(_ nsView: QLPreviewView, coordinator: Coordinator) {
        coordinator.stopAccessing()
        nsView.previewItem = nil
    }

    private func configure(_ previewView: QLPreviewView?, context: Context) {
        guard let previewView else { return }
        context.coordinator.updateAccess(for: accessURL)
        previewView.previewItem = url as NSURL
        previewView.refreshPreviewItem()
    }

    final class Coordinator {
        private var accessedURL: URL?
        private var isAccessing = false

        func updateAccess(for url: URL) {
            guard accessedURL != url else { return }
            stopAccessing()
            accessedURL = url
            isAccessing = url.startAccessingSecurityScopedResource()
        }

        func stopAccessing() {
            if isAccessing {
                accessedURL?.stopAccessingSecurityScopedResource()
            }
            accessedURL = nil
            isAccessing = false
        }
    }
}

/// Präsentiert die native Vollbild-Vorschau (Quick Look).
@MainActor
final class QuickLookPresenter: NSObject, QLPreviewPanelDataSource, QLPreviewPanelDelegate {
    static let shared = QuickLookPresenter()
    private var url: URL?
    private var accessedURL: URL?
    private var isAccessing = false

    var isPreviewVisible: Bool {
        guard QLPreviewPanel.sharedPreviewPanelExists(),
              let panel = QLPreviewPanel.shared()
        else { return false }
        return panel.isVisible
    }

    func present(_ url: URL, accessURL: URL? = nil) {
        stopAccessing()
        self.url = url
        let accessURL = accessURL ?? url
        accessedURL = accessURL
        isAccessing = accessURL.startAccessingSecurityScopedResource()

        guard let panel = QLPreviewPanel.shared() else { return }
        panel.dataSource = self
        panel.delegate = self
        panel.reloadData()
        panel.makeKeyAndOrderFront(nil)
    }

    func close() {
        QLPreviewPanel.shared()?.orderOut(nil)
        stopAccessing()
        url = nil
    }

    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        url == nil ? 0 : 1
    }

    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> (any QLPreviewItem)! {
        url.map { $0 as NSURL }
    }

    func previewPanelWillClose(_ panel: QLPreviewPanel!) {
        stopAccessing()
        url = nil
    }

    private func stopAccessing() {
        if isAccessing {
            accessedURL?.stopAccessingSecurityScopedResource()
        }
        accessedURL = nil
        isAccessing = false
    }
}
