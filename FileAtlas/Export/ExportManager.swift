//
//  ExportManager.swift
//  FileAtlas
//
//  Koordiniert die drei Export-Formate (XLSX / PDF / CSV).
//

import Foundation

nonisolated struct ExportManager {

    /// Exportiert die aktuelle (gefilterte) Dateiliste.
    static func export(_ entries: [FileEntry], format: ExportFormat, roots: [URL]) throws -> Data {
        switch format {
        case .csv:  return CSVExporter.makeData(for: entries)
        case .xlsx: return XLSXExporter.makeData(for: entries)
        case .pdf:  return PDFExporter.makeData(for: entries, roots: roots)
        }
    }

    /// Exportiert einen Snapshot-Vergleich.
    static func exportDiff(_ diff: SnapshotDiff, format: ExportFormat) throws -> Data {
        switch format {
        case .csv:  return CSVExporter.makeDiffData(for: diff)
        case .xlsx: return XLSXExporter.makeDiffData(for: diff)
        case .pdf:  return PDFExporter.makeDiffData(for: diff)
        }
    }

    /// Dateiname im Schema `FileAtlas_Export_YYYY-MM-DD_HH-mm.<ext>`.
    static func suggestedFilename(format: ExportFormat) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd_HH-mm"
        return "FileAtlas_Export_\(df.string(from: Date())).\(format.fileExtension)"
    }
}
