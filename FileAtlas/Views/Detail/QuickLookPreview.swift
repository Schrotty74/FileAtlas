//
//  QuickLookPreview.swift
//  FileAtlas
//
//  Thumbnail via QLThumbnailGenerator + Vollbild-Vorschau via QLPreviewPanel.
//

import SwiftUI
import QuickLookThumbnailing
import Quartz

struct QuickLookPreview: View {
    let url: URL
    let fallbackIcon: String

    @State private var thumbnail: NSImage?
    @State private var didFail = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppTheme.theme.cornerRadius)
                .fill(AppTheme.surfaceRaised)

            if let thumbnail {
                Image(nsImage: thumbnail)
                    .resizable()
                    .scaledToFit()
                    .padding(8)
            } else if didFail {
                Image(systemName: fallbackIcon)
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(AppTheme.theme.accentColor)
            } else {
                ProgressView().controlSize(.small)
            }
        }
        .frame(height: 200)
        .task(id: url) { await loadThumbnail() }
    }

    private func loadThumbnail() async {
        thumbnail = nil
        didFail = false

        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }

        let request = QLThumbnailGenerator.Request(
            fileAt: url,
            size: CGSize(width: 400, height: 400),
            scale: 2,
            representationTypes: .all
        )
        do {
            let rep = try await QLThumbnailGenerator.shared.generateBestRepresentation(for: request)
            thumbnail = rep.nsImage
        } catch {
            didFail = true
        }
    }
}

/// Präsentiert die native Vollbild-Vorschau (Quick Look).
@MainActor
final class QuickLookPresenter: NSObject, QLPreviewPanelDataSource {
    static let shared = QuickLookPresenter()
    private var url: URL?

    func present(_ url: URL) {
        self.url = url
        guard let panel = QLPreviewPanel.shared() else { return }
        panel.dataSource = self
        panel.reloadData()
        panel.makeKeyAndOrderFront(nil)
    }

    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        url == nil ? 0 : 1
    }

    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> (any QLPreviewItem)! {
        url.map { $0 as NSURL }
    }
}
