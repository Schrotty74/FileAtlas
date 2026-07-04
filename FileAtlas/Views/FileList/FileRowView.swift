//
//  FileRowView.swift
//  FileAtlas
//
//  Kompakte Tabellenzeile (rowHeight 28) im Midnight-Teal-Stil.
//

import SwiftUI

/// Gemeinsame Spaltenbreiten für Header und Zeilen.
enum FileColumnWidth {
    static let kind: CGFloat = 90
    static let status: CGFloat = 92
    static let size: CGFloat = 80
    static let modified: CGFloat = 140
}

struct FileRowView: View {
    let entry: FileEntry

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 8) {
                SystemFileIconView(entry: entry, size: 16)
                Text(entry.name)
                    .font(.callout)
                    .tracking(-0.2)
                    .foregroundStyle(AppTheme.theme.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(entry.isDirectory ? "Folder" : entry.fileExtension.uppercased())
                .font(.caption)
                .foregroundStyle(AppTheme.theme.textSecondary)
                .lineLimit(1)
                .frame(width: FileColumnWidth.kind, alignment: .leading)

            Group {
                if entry.isDuplicate {
                    DuplicateBadge()
                } else {
                    Text("—").foregroundStyle(AppTheme.theme.textSecondary.opacity(0.5))
                }
            }
            .frame(width: FileColumnWidth.status, alignment: .leading)

            Text(entry.formattedSize)
                .font(.caption.monospacedDigit())
                .foregroundStyle(AppTheme.theme.textSecondary)
                .frame(width: FileColumnWidth.size, alignment: .trailing)

            Text(Self.dateString(entry.modified))
                .font(.caption.monospacedDigit())
                .foregroundStyle(AppTheme.theme.textSecondary)
                .frame(width: FileColumnWidth.modified, alignment: .trailing)
        }
        .frame(height: AppTheme.theme.rowHeight)
        .padding(.horizontal, 12)
    }

    // MARK: - Helpers

    static func dateString(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .short
        df.timeStyle = .short
        return df.string(from: date)
    }

    static func icon(for entry: FileEntry) -> String {
        if entry.isDirectory { return "folder.fill" }
        switch entry.fileExtension.lowercased() {
        case "jpg", "jpeg", "png", "heic", "gif", "webp", "tiff": return "photo"
        case "pdf": return "doc.richtext"
        case "doc", "docx", "pages", "rtf": return "doc.text"
        case "xls", "xlsx", "numbers", "csv": return "tablecells"
        case "key", "ppt", "pptx": return "rectangle.on.rectangle"
        case "mov", "mp4", "m4v", "avi": return "film"
        case "mp3", "wav", "aac", "m4a": return "waveform"
        case "zip", "tar", "gz", "dmg": return "archivebox"
        case "swift", "py", "js", "ts", "java", "c", "cpp", "rs", "go": return "chevron.left.forwardslash.chevron.right"
        case "txt", "md": return "doc.plaintext"
        default: return "doc"
        }
    }
}
