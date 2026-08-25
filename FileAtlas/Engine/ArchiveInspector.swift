import CryptoKit
import Foundation

nonisolated enum HashManifestVerification: Sendable, Equatable {
    case notPresent
    case verified(fileCount: Int)
    case failed(reason: String)
}

nonisolated struct ArchiveInspection: Sendable {
    let entries: [String]
    let isValid: Bool
    let hasHashManifest: Bool
    let hashManifestVerification: HashManifestVerification
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
        let manifestVerification = verifyHashManifest(at: manifestURL, in: archiveURL)
        let message: String
        if valid {
            switch manifestVerification {
            case .notPresent:
                message = "Archive structure is valid."
            case .verified(let fileCount):
                message = "Archive structure and SHA-256 manifest verified for \(fileCount) files."
            case .failed(let reason):
                message = "Archive structure is valid, but SHA-256 verification failed: \(reason)"
            }
        } else {
            message = test.output.isEmpty ? "Archive could not be verified." : test.output
        }
        return ArchiveInspection(
            entries: entries,
            isValid: valid,
            hasHashManifest: hasManifest,
            hashManifestVerification: manifestVerification,
            message: message
        )
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

    private static func verifyHashManifest(at manifestURL: URL, in archiveURL: URL) -> HashManifestVerification {
        guard FileManager.default.fileExists(atPath: manifestURL.path(percentEncoded: false)) else {
            return .notPresent
        }
        guard let manifest = try? String(contentsOf: manifestURL, encoding: .utf8) else {
            return .failed(reason: "The manifest could not be read.")
        }

        let records = manifest
            .split(whereSeparator: \.isNewline)
            .filter { !$0.hasPrefix("#") && !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .compactMap { line -> (hash: String, path: String)? in
                let components = line.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
                guard components.count == 2 else { return nil }
                let hash = String(components[0]).lowercased()
                let path = String(components[1]).trimmingCharacters(in: .whitespaces)
                guard hash.count == 64,
                      hash.allSatisfy({ $0.isHexDigit }),
                      !path.isEmpty
                else { return nil }
                return (hash, path)
            }

        guard !records.isEmpty else {
            return .failed(reason: "The manifest has no valid hash records.")
        }

        for record in records {
            let extracted = runData("/usr/bin/unzip", ["-p", archiveURL.path(percentEncoded: false), record.path])
            guard extracted.status == 0 else {
                return .failed(reason: "\(record.path) could not be read from the archive.")
            }
            let digest = SHA256.hash(data: extracted.data).map { String(format: "%02x", $0) }.joined()
            guard digest == record.hash else {
                return .failed(reason: "The hash for \(record.path) does not match.")
            }
        }
        return .verified(fileCount: records.count)
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

    private static func runData(_ executable: String, _ arguments: [String]) -> (status: Int32, data: Data) {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            return (process.terminationStatus, data)
        } catch {
            return (1, Data())
        }
    }
}
