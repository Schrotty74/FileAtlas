//
//  CSVExporter.swift
//  FileAtlas
//
//  Semikolon-getrennte CSV (deutsche Excel-Konvention), UTF-8 mit BOM.
//

import Foundation

nonisolated struct CSVExporter {

    static func makeData(for entries: [FileEntry]) -> Data {
        var rows: [[String]] = []
        rows.append(["Name", "Pfad", "Größe", "Erstellungsdatum", "Änderungsdatum", "Dateityp", "Duplikat"])
        for e in entries {
            rows.append([
                e.name,
                e.pathKey,
                e.formattedSize,
                Self.dateString(e.created),
                Self.dateString(e.modified),
                e.isDirectory ? "Ordner" : e.fileExtension.uppercased(),
                e.isDuplicate ? "Ja" : "Nein",
            ])
        }
        return encode(rows)
    }

    static func makeDiffData(for diff: SnapshotDiff) -> Data {
        var rows: [[String]] = []
        rows.append(["Status", "Name", "Pfad", "Größe", "Änderungsdatum", "Dateityp"])
        for change in diff.all {
            let e = change.entry
            rows.append([
                Self.statusLabel(change.status),
                e.name,
                e.pathKey,
                e.formattedSize,
                Self.dateString(e.modified),
                e.isDirectory ? "Ordner" : e.fileExtension.uppercased(),
            ])
        }
        return encode(rows)
    }

    // MARK: - Helpers

    private static func encode(_ rows: [[String]]) -> Data {
        let body = rows.map { row in
            row.map(escape).joined(separator: ";")
        }.joined(separator: "\r\n")

        var data = Data([0xEF, 0xBB, 0xBF])   // UTF-8 BOM
        data.append(Data(body.utf8))
        return data
    }

    private static func escape(_ field: String) -> String {
        if field.contains(";") || field.contains("\"") || field.contains("\n") {
            return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return field
    }

    private static func dateString(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "de_DE")
        df.dateFormat = "dd.MM.yyyy HH:mm"
        return df.string(from: date)
    }

    static func statusLabel(_ status: ChangeStatus) -> String {
        switch status {
        case .added:   return "Neu"
        case .removed: return "Entfernt"
        case .changed: return "Geändert"
        }
    }
}
