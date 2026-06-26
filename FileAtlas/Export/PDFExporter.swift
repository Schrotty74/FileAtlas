//
//  PDFExporter.swift
//  FileAtlas
//
//  Professionelles Schwarz-Weiß-PDF via Core Graphics / PDFKit.
//

import Foundation
import AppKit
import PDFKit

nonisolated struct PDFExporter {

    // US-Letter
    private static let pageSize = CGSize(width: 612, height: 792)
    private static let margin: CGFloat = 40
    private static let rowHeight: CGFloat = 18

    static func makeData(for entries: [FileEntry], roots: [URL]) -> Data {
        let columns = [
            Column(title: "Dateiname", width: 150),
            Column(title: "Pfad", width: 200),
            Column(title: "Größe", width: 60),
            Column(title: "Geändert", width: 70),
            Column(title: "Typ", width: 52),
        ]
        let rows: [[String]] = entries.map { e in
            [e.name, e.pathKey, e.formattedSize, dateString(e.modified),
             e.isDirectory ? "Ordner" : e.fileExtension.uppercased()]
        }
        let subtitle = "Ordner: " + (roots.map { $0.lastPathComponent }.joined(separator: ", "))
        return render(columns: columns, rows: rows, subtitle: subtitle, count: entries.count)
    }

    static func makeDiffData(for diff: SnapshotDiff) -> Data {
        let columns = [
            Column(title: "Status", width: 60),
            Column(title: "Dateiname", width: 140),
            Column(title: "Pfad", width: 200),
            Column(title: "Größe", width: 60),
            Column(title: "Geändert", width: 72),
        ]
        let rows: [[String]] = diff.all.map { change in
            let e = change.entry
            return [CSVExporter.statusLabel(change.status), e.name, e.pathKey,
                    e.formattedSize, dateString(e.modified)]
        }
        return render(columns: columns, rows: rows, subtitle: "Snapshot-Vergleich", count: diff.all.count)
    }

    // MARK: - Rendering

    private struct Column { let title: String; let width: CGFloat }

    private static func render(columns: [Column], rows: [[String]], subtitle: String, count: Int) -> Data {
        let data = NSMutableData()
        var mediaBox = CGRect(origin: .zero, size: pageSize)
        guard let consumer = CGDataConsumer(data: data as CFMutableData),
              let ctx = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            return Data()
        }

        let rowsPerPage = Int((pageSize.height - margin * 2 - 80) / rowHeight)
        let totalPages = max(1, Int(ceil(Double(rows.count) / Double(max(1, rowsPerPage)))))

        var pageIndex = 0
        var rowIndex = 0
        while pageIndex < totalPages {
            ctx.beginPDFPage(nil)
            let nsCtx = NSGraphicsContext(cgContext: ctx, flipped: false)
            NSGraphicsContext.current = nsCtx

            drawHeader(subtitle: subtitle, count: count, page: pageIndex + 1, totalPages: totalPages)

            var y = pageSize.height - margin - 70
            drawRow(columns.map { $0.title }, columns: columns, y: y, bold: true)
            y -= rowHeight
            drawSeparator(y: y + rowHeight - 4)

            var drawn = 0
            while rowIndex < rows.count && drawn < rowsPerPage {
                drawRow(rows[rowIndex], columns: columns, y: y, bold: false)
                y -= rowHeight
                rowIndex += 1
                drawn += 1
            }

            drawFooter(page: pageIndex + 1, totalPages: totalPages)

            NSGraphicsContext.current = nil
            ctx.endPDFPage()
            pageIndex += 1
        }

        ctx.closePDF()
        return data as Data
    }

    private static func drawHeader(subtitle: String, count: Int, page: Int, totalPages: Int) {
        let title = "FileAtlas"
        title.draw(at: CGPoint(x: margin, y: pageSize.height - margin - 20),
                   withAttributes: [.font: NSFont.boldSystemFont(ofSize: 20),
                                    .foregroundColor: NSColor.black])

        let info = "\(dateString(Date()))  ·  \(count) Dateien"
        info.draw(at: CGPoint(x: margin, y: pageSize.height - margin - 38),
                  withAttributes: [.font: NSFont.systemFont(ofSize: 9),
                                   .foregroundColor: NSColor.darkGray])
        subtitle.draw(at: CGPoint(x: margin, y: pageSize.height - margin - 52),
                      withAttributes: [.font: NSFont.systemFont(ofSize: 9),
                                       .foregroundColor: NSColor.darkGray])
    }

    private static func drawRow(_ values: [String], columns: [Column], y: CGFloat, bold: Bool) {
        var x = margin
        let font = bold ? NSFont.boldSystemFont(ofSize: 8.5) : NSFont.systemFont(ofSize: 8.5)
        for (i, col) in columns.enumerated() where i < values.count {
            let rect = CGRect(x: x, y: y, width: col.width - 4, height: rowHeight)
            let para = NSMutableParagraphStyle()
            para.lineBreakMode = .byTruncatingMiddle
            values[i].draw(in: rect, withAttributes: [
                .font: font,
                .foregroundColor: NSColor.black,
                .paragraphStyle: para,
            ])
            x += col.width
        }
    }

    private static func drawSeparator(y: CGFloat) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        ctx.setStrokeColor(NSColor.black.cgColor)
        ctx.setLineWidth(0.5)
        ctx.move(to: CGPoint(x: margin, y: y))
        ctx.addLine(to: CGPoint(x: pageSize.width - margin, y: y))
        ctx.strokePath()
    }

    private static func drawFooter(page: Int, totalPages: Int) {
        let text = "Seite \(page) von \(totalPages)"
        let para = NSMutableParagraphStyle()
        para.alignment = .center
        let rect = CGRect(x: margin, y: margin - 14, width: pageSize.width - margin * 2, height: 14)
        text.draw(in: rect, withAttributes: [
            .font: NSFont.systemFont(ofSize: 8),
            .foregroundColor: NSColor.darkGray,
            .paragraphStyle: para,
        ])
    }

    private static func dateString(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "de_DE")
        df.dateFormat = "dd.MM.yyyy HH:mm"
        return df.string(from: date)
    }
}
