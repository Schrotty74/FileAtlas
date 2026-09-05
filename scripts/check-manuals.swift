import AppKit
import PDFKit
import CryptoKit

// Run from the repository root: swift scripts/check-manuals.swift
// Baseline updates require a visual review of every changed page first.
struct PageRecord: Codable, Equatable {
    let width: Double
    let height: Double
    let digest: String
    let fonts: [String]
}
struct Baseline: Codable {
    let schema: Int
    let documents: [String: [PageRecord]]
    let sources: [String: String]
}
struct Inspection {
    let pages: [PageRecord]
    let errors: [String]
}
enum CheckError: Error { case invalid(String) }

let manuals = ["FileAtlas-Handbuch.pdf", "FileAtlas-Manual-EN.pdf"]
let baselineURL = URL(fileURLWithPath: "scripts/manual-baseline.json")

func inspect(_ url: URL) throws -> Inspection {
    guard let pdf = PDFDocument(url: url), !pdf.isLocked, pdf.pageCount > 0 else {
        throw CheckError.invalid("Cannot read PDF: \(url.lastPathComponent)")
    }
    var records: [PageRecord] = []
    var errors: [String] = []
    for index in 0..<pdf.pageCount {
        guard let page = pdf.page(at: index) else {
            throw CheckError.invalid("Missing page \(index + 1)")
        }
        let label = "\(url.lastPathComponent), page \(index + 1)"
        let bounds = page.bounds(for: .mediaBox)
        if abs(bounds.width - 595.276) > 1 || abs(bounds.height - 841.89) > 1 {
            errors.append("\(label): expected portrait A4")
        }
        // Fixed RGB bitmap: hashes compare rendered appearance, not PDF metadata.
        let width = 420, height = 594
        var pixels = [UInt8](repeating: 255, count: width * height * 4)
        try pixels.withUnsafeMutableBytes { bytes in
        guard let context = CGContext(data: bytes.baseAddress, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            throw CheckError.invalid("Cannot render \(label)")
        }
        context.setFillColor(CGColor(gray: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        context.scaleBy(x: CGFloat(width) / bounds.width, y: CGFloat(height) / bounds.height)
        context.translateBy(x: -bounds.minX, y: -bounds.minY)
        page.draw(with: .mediaBox, to: context)
        }
        var dark = 0, bright = 0
        for i in stride(from: 0, to: pixels.count, by: 4) {
            let luminance = (Int(pixels[i]) * 2126 + Int(pixels[i+1]) * 7152 + Int(pixels[i+2]) * 722) / 10000
            if luminance < 100 { dark += 1 }
            if luminance > 150 { bright += 1 }
        }
        let total = Double(width * height)
        if Double(dark) / total < 0.70 {
            errors.append("\(label): dark background missing (\(Int(Double(dark) / total * 100))% dark pixels)")
        }
        if Double(bright) / total < 0.0005 {
            errors.append("\(label): no visible light content; page may be blank or unreadable")
        }
        var fonts = Set<String>()
        if let text = page.attributedString, text.length > 0 {
            text.enumerateAttribute(.font, in: NSRange(location: 0, length: text.length)) { value, _, _ in
                if let font = value as? NSFont { fonts.insert(font.familyName ?? font.fontName) }
            }
        }
        records.append(PageRecord(width: Double(bounds.width), height: Double(bounds.height),
            digest: SHA256.hash(data: Data(pixels)).map { String(format: "%02x", $0) }.joined(),
            fonts: fonts.sorted()))
    }
    return Inspection(pages: records, errors: errors)
}

func compare(_ current: [String: [PageRecord]], _ baseline: Baseline, sources: [String: String] = [:]) -> [String] {
    var errors: [String] = []
    guard baseline.schema == 1 else { return ["Unsupported baseline schema"] }
    for name in manuals {
        guard let pages = current[name], let previous = baseline.documents[name], !previous.isEmpty else {
            errors.append("\(name): missing current document or approved baseline")
            continue
        }
        if pages.count != previous.count {
            errors.append("\(name): page count changed (\(previous.count) -> \(pages.count)); visual review required")
        }
        // Identical PDF bytes need no pixel comparison. This avoids false alarms
        // from different macOS font rasterizers in CI for unchanged documents.
        if let source = sources[name], source == baseline.sources[name] { continue }
        let allowedFonts = Set(previous.flatMap(\.fonts))
        for (index, page) in pages.enumerated() {
            if !Set(page.fonts).isSubset(of: allowedFonts) {
                errors.append("\(name), page \(index + 1): new font family; visual review required")
            }
            if index < previous.count, page != previous[index] {
                errors.append("\(name), page \(index + 1): appearance or typography changed; visual review required")
            }
        }
    }
    if current[manuals[0]]?.count != current[manuals[1]]?.count {
        errors.append("German and English manuals have different page counts")
    }
    return errors
}

func selfTest() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent("FileAtlas-ManualChecks-\(UUID())")
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    func fixture(_ name: String, dark: Bool, text: String = "Synthetic manual", width: CGFloat = 595.276, font: String = "Helvetica") throws -> URL {
        let url = directory.appendingPathComponent(name + ".pdf")
        var box = CGRect(x: 0, y: 0, width: width, height: 841.89)
        guard let context = CGContext(url as CFURL, mediaBox: &box, nil) else { throw CheckError.invalid("Fixture failure") }
        context.beginPDFPage(nil)
        context.setFillColor(CGColor(gray: dark ? 0.08 : 1, alpha: 1))
        context.fill(box)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
        (text as NSString).draw(at: NSPoint(x: 60, y: 700), withAttributes: [.font: NSFont(name: font, size: 24)!, .foregroundColor: dark ? NSColor.white : NSColor.black])
        NSGraphicsContext.restoreGraphicsState()
        context.endPDFPage()
        context.closePDF()
        return url
    }
    func require(_ condition: Bool, _ message: String) throws {
        if !condition { throw CheckError.invalid("Self-test failed: " + message) }
        print("PASS: " + message)
    }
    let valid = try inspect(fixture("dark", dark: true))
    try require(valid.errors.isEmpty, "dark A4 page accepted")
    let baseline = Baseline(schema: 1, documents: Dictionary(uniqueKeysWithValues: manuals.map { ($0, valid.pages) }), sources: [:])
    let current = baseline.documents
    try require(compare(current, baseline).isEmpty, "unchanged manuals accepted")
    try require(!(try inspect(fixture("white", dark: false))).errors.isEmpty, "white page rejected")
    try require(!(try inspect(fixture("size", dark: true, width: 500))).errors.isEmpty, "wrong page size rejected")
    try require(!(try inspect(fixture("blank", dark: true, text: ""))).errors.isEmpty, "blank page rejected")
    var changed = current
    changed[manuals[0]] = try inspect(fixture("changed", dark: true, text: "Unintended change")).pages
    try require(!compare(changed, baseline).isEmpty, "changed existing page rejected")
    changed = current
    changed[manuals[0]] = try inspect(fixture("font", dark: true, font: "Courier")).pages
    try require(compare(changed, baseline).contains { $0.contains("font") }, "new font rejected")
    changed = current
    changed.removeValue(forKey: manuals[1])
    try require(!compare(changed, baseline).isEmpty, "missing language rejected")
    changed = current
    changed[manuals[0]] = valid.pages + valid.pages
    try require(!compare(changed, baseline).isEmpty, "unreviewed extra page rejected")
}

do {
    let args = Array(CommandLine.arguments.dropFirst())
    if args == ["--self-test"] {
        try selfTest()
    } else {
        guard args.isEmpty || args == ["--record-reviewed-baseline"] else {
            throw CheckError.invalid("Usage: swift scripts/check-manuals.swift [--self-test | --record-reviewed-baseline]")
        }
        var records: [String: [PageRecord]] = [:]
        var sources: [String: String] = [:]
        var errors: [String] = []
        for name in manuals {
            let url = URL(fileURLWithPath: "output/pdf/" + name)
            sources[name] = SHA256.hash(data: try Data(contentsOf: url)).map { String(format: "%02x", $0) }.joined()
            let result = try inspect(url)
            records[name] = result.pages
            errors += result.errors
        }
        if records[manuals[0]]?.count != records[manuals[1]]?.count {
            errors.append("Language versions have different page counts")
        }
        if args.isEmpty {
            let baseline = try JSONDecoder().decode(Baseline.self, from: Data(contentsOf: baselineURL))
            errors += compare(records, baseline, sources: sources)
        }
        if !args.isEmpty {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(Baseline(schema: 1, documents: records, sources: sources)).write(to: baselineURL, options: .atomic)
            print("Recorded visual reference. Structural and theme failures still block the check; recording does not exempt them.")
        }
        guard errors.isEmpty else { throw CheckError.invalid(errors.joined(separator: "\n")) }
        if args.isEmpty {
            print("PASS: both manuals match the approved appearance; all \(records.values.reduce(0) { $0 + $1.count }) pages passed structural and dark-theme checks.")
        }
    }
} catch {
    fputs("Manual check failed: \(error)\n", stderr)
    exit(1)
}
