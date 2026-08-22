import Foundation

nonisolated struct ArchiveInspection: Sendable {
    let entries: [String]
    let isValid: Bool
    let hasHashManifest: Bool
    let message: String
}

/// Uses the system ZIP tools only for reading existing archives. FileAtlas keeps
/// writing archives itself and never sends archive contents anywhere.
nonisolated enum ArchiveInspector {
    static func inspect(_ archiveURL: URL) -> ArchiveInspection {
        let entriesResult = run("/usr/bin/unzip", ["-Z1", archiveURL.path(percentEncoded: false)])
        let entries = entriesResult.output
            .split(whereSeparator: \.isNewline)
            .map(String.init)
            .filter { !$0.isEmpty }
        let test = run("/usr/bin/unzip", ["-tqq", archiveURL.path(percentEncoded: false)])
        let manifestURL = archiveURL.deletingPathExtension().appendingPathExtension("sha256")
        let hasManifest = FileManager.default.fileExists(atPath: manifestURL.path(percentEncoded: false))
        let valid = test.status == 0 && !entries.isEmpty
        let message: String
        if valid {
            message = hasManifest ? "Archive and SHA-256 manifest found." : "Archive structure is valid."
        } else {
            message = test.output.isEmpty ? "Archive could not be verified." : test.output
        }
        return ArchiveInspection(entries: entries, isValid: valid, hasHashManifest: hasManifest, message: message)
    }

    static func restore(_ entries: [String], from archiveURL: URL, to destination: URL) throws {
        guard !entries.isEmpty else { return }
        let result = run("/usr/bin/unzip", ["-o", archiveURL.path(percentEncoded: false)] + entries + ["-d", destination.path(percentEncoded: false)])
        guard result.status == 0 else {
            throw ArchiveError.restoreFailed(result.output)
        }
    }

    enum ArchiveError: LocalizedError, Sendable {
        case restoreFailed(String)

        var errorDescription: String? {
            switch self {
            case .restoreFailed(let message): return message.isEmpty ? "Archive restore failed." : message
            }
        }
    }

    private static func run(_ executable: String, _ arguments: [String]) -> (status: Int32, output: String) {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = pipe
        process.standardError = pipe
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return (1, error.localizedDescription)
        }
        let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        return (process.terminationStatus, output)
    }
}
