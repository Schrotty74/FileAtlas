//
//  XLSXExporter.swift
//  FileAtlas
//
//  Erzeugt eine .xlsx-Datei (OOXML) ohne externe Abhängigkeiten.
//  Das .xlsx ist ein ZIP-Container; hier mit „stored" (unkomprimiert) erzeugt —
//  von Excel und Numbers problemlos lesbar.
//

import Foundation

nonisolated struct XLSXExporter {

    static func makeData(for entries: [FileEntry]) -> Data {
        let header = ["Name", "Pfad", "Größe", "Erstellungsdatum", "Änderungsdatum", "Dateityp", "Duplikat"]
        let rows: [[String]] = entries.map { e in
            [
                e.name,
                e.pathKey,
                e.formattedSize,
                dateString(e.created),
                dateString(e.modified),
                e.isDirectory ? "Ordner" : e.fileExtension.uppercased(),
                e.isDuplicate ? "Ja" : "Nein",
            ]
        }
        let widths: [Double] = [34, 60, 14, 20, 20, 14, 10]
        return build(header: header, rows: rows, widths: widths)
    }

    static func makeDiffData(for diff: SnapshotDiff) -> Data {
        let header = ["Status", "Name", "Pfad", "Größe", "Änderungsdatum", "Dateityp"]
        let rows: [[String]] = diff.all.map { change in
            let e = change.entry
            return [
                CSVExporter.statusLabel(change.status),
                e.name,
                e.pathKey,
                e.formattedSize,
                dateString(e.modified),
                e.isDirectory ? "Ordner" : e.fileExtension.uppercased(),
            ]
        }
        let widths: [Double] = [12, 34, 60, 14, 20, 14]
        return build(header: header, rows: rows, widths: widths)
    }

    // MARK: - OOXML-Aufbau

    private static func build(header: [String], rows: [[String]], widths: [Double]) -> Data {
        var zip = ZipArchive()
        zip.add(path: "[Content_Types].xml", string: contentTypesXML)
        zip.add(path: "_rels/.rels", string: rootRelsXML)
        zip.add(path: "xl/workbook.xml", string: workbookXML)
        zip.add(path: "xl/_rels/workbook.xml.rels", string: workbookRelsXML)
        zip.add(path: "xl/styles.xml", string: stylesXML)
        zip.add(path: "xl/worksheets/sheet1.xml", string: sheetXML(header: header, rows: rows, widths: widths))
        return zip.finalize()
    }

    private static func sheetXML(header: [String], rows: [[String]], widths: [Double]) -> String {
        func cell(_ value: String, row: Int, col: Int, styleHeader: Bool) -> String {
            let ref = "\(columnLetter(col))\(row)"
            let style = styleHeader ? " s=\"1\"" : ""
            return "<c r=\"\(ref)\" t=\"inlineStr\"\(style)><is><t xml:space=\"preserve\">\(escapeXML(value))</t></is></c>"
        }

        var cols = "<cols>"
        for (i, w) in widths.enumerated() {
            cols += "<col min=\"\(i + 1)\" max=\"\(i + 1)\" width=\"\(w)\" customWidth=\"1\"/>"
        }
        cols += "</cols>"

        var sheetData = "<sheetData>"
        // Headerzeile
        sheetData += "<row r=\"1\">"
        for (c, value) in header.enumerated() {
            sheetData += cell(value, row: 1, col: c, styleHeader: true)
        }
        sheetData += "</row>"
        // Datenzeilen
        for (r, row) in rows.enumerated() {
            let rowNum = r + 2
            sheetData += "<row r=\"\(rowNum)\">"
            for (c, value) in row.enumerated() {
                sheetData += cell(value, row: rowNum, col: c, styleHeader: false)
            }
            sheetData += "</row>"
        }
        sheetData += "</sheetData>"

        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">\(cols)\(sheetData)</worksheet>
        """
    }

    // MARK: - Statische XML-Bausteine

    private static let contentTypesXML = """
    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
    <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
    <Default Extension="xml" ContentType="application/xml"/>
    <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
    <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
    <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
    </Types>
    """

    private static let rootRelsXML = """
    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
    <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
    </Relationships>
    """

    private static let workbookXML = """
    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
    <sheets><sheet name="FileAtlas" sheetId="1" r:id="rId1"/></sheets>
    </workbook>
    """

    private static let workbookRelsXML = """
    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
    <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
    <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
    </Relationships>
    """

    // Style 0 = Standard, Style 1 = fett mit Hintergrundfüllung (Headerzeile).
    private static let stylesXML = """
    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
    <fonts count="2"><font><sz val="11"/><name val="Calibri"/></font><font><b/><sz val="11"/><color rgb="FFFFFFFF"/><name val="Calibri"/></font></fonts>
    <fills count="3"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill><fill><patternFill patternType="solid"><fgColor rgb="FF21A89E"/></patternFill></fill></fills>
    <borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>
    <cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
    <cellXfs count="2"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/><xf numFmtId="0" fontId="1" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1"/></cellXfs>
    </styleSheet>
    """

    // MARK: - Hilfsfunktionen

    private static func columnLetter(_ index: Int) -> String {
        var n = index
        var result = ""
        repeat {
            result = String(UnicodeScalar(UInt8(65 + n % 26))) + result
            n = n / 26 - 1
        } while n >= 0
        return result
    }

    private static func escapeXML(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }

    private static func dateString(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "de_DE")
        df.dateFormat = "dd.MM.yyyy HH:mm"
        return df.string(from: date)
    }
}

// MARK: - Minimaler ZIP-Writer (stored / unkomprimiert)

private nonisolated struct ZipArchive {

    private struct Entry {
        let name: String
        let data: Data
        let crc: UInt32
        let offset: UInt32
    }

    private var entries: [Entry] = []
    private var buffer = Data()

    mutating func add(path: String, string: String) {
        let data = Data(string.utf8)
        let crc = ZipArchive.crc32(data)
        let offset = UInt32(buffer.count)

        var local = Data()
        local.appendLE(UInt32(0x04034b50))   // local file header signature
        local.appendLE(UInt16(20))           // version needed
        local.appendLE(UInt16(0))            // flags
        local.appendLE(UInt16(0))            // method: stored
        local.appendLE(UInt16(0))            // mod time
        local.appendLE(UInt16(0))            // mod date
        local.appendLE(crc)
        local.appendLE(UInt32(data.count))   // compressed size
        local.appendLE(UInt32(data.count))   // uncompressed size
        let nameBytes = Data(path.utf8)
        local.appendLE(UInt16(nameBytes.count))
        local.appendLE(UInt16(0))            // extra length
        local.append(nameBytes)
        local.append(data)

        buffer.append(local)
        entries.append(Entry(name: path, data: data, crc: crc, offset: offset))
    }

    mutating func finalize() -> Data {
        let centralStart = UInt32(buffer.count)
        var central = Data()

        for e in entries {
            var header = Data()
            header.appendLE(UInt32(0x02014b50))   // central directory signature
            header.appendLE(UInt16(20))           // version made by
            header.appendLE(UInt16(20))           // version needed
            header.appendLE(UInt16(0))            // flags
            header.appendLE(UInt16(0))            // method
            header.appendLE(UInt16(0))            // mod time
            header.appendLE(UInt16(0))            // mod date
            header.appendLE(e.crc)
            header.appendLE(UInt32(e.data.count))
            header.appendLE(UInt32(e.data.count))
            let nameBytes = Data(e.name.utf8)
            header.appendLE(UInt16(nameBytes.count))
            header.appendLE(UInt16(0))            // extra length
            header.appendLE(UInt16(0))            // comment length
            header.appendLE(UInt16(0))            // disk number start
            header.appendLE(UInt16(0))            // internal attrs
            header.appendLE(UInt32(0))            // external attrs
            header.appendLE(e.offset)             // local header offset
            header.append(nameBytes)
            central.append(header)
        }

        buffer.append(central)

        var eocd = Data()
        eocd.appendLE(UInt32(0x06054b50))        // EOCD signature
        eocd.appendLE(UInt16(0))                 // disk number
        eocd.appendLE(UInt16(0))                 // disk with central dir
        eocd.appendLE(UInt16(entries.count))     // entries on this disk
        eocd.appendLE(UInt16(entries.count))     // total entries
        eocd.appendLE(UInt32(central.count))     // central dir size
        eocd.appendLE(centralStart)              // central dir offset
        eocd.appendLE(UInt16(0))                 // comment length
        buffer.append(eocd)

        return buffer
    }

    // CRC-32 (IEEE 802.3)
    private static let crcTable: [UInt32] = {
        (0..<256).map { i -> UInt32 in
            var c = UInt32(i)
            for _ in 0..<8 {
                c = (c & 1 != 0) ? (0xEDB88320 ^ (c >> 1)) : (c >> 1)
            }
            return c
        }
    }()

    private static func crc32(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFFFFFF
        for byte in data {
            let index = Int((crc ^ UInt32(byte)) & 0xFF)
            crc = crcTable[index] ^ (crc >> 8)
        }
        return crc ^ 0xFFFFFFFF
    }
}

private extension Data {
    nonisolated mutating func appendLE(_ value: UInt16) {
        append(UInt8(value & 0xFF))
        append(UInt8((value >> 8) & 0xFF))
    }
    nonisolated mutating func appendLE(_ value: UInt32) {
        append(UInt8(value & 0xFF))
        append(UInt8((value >> 8) & 0xFF))
        append(UInt8((value >> 16) & 0xFF))
        append(UInt8((value >> 24) & 0xFF))
    }
}
