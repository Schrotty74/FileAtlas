import Foundation

nonisolated struct BatchRenamePlan: Identifiable, Sendable, Equatable {
    let source: URL
    let destination: URL

    var id: URL { source }
}

nonisolated struct BatchRenameResult: Sendable, Equatable {
    let renamedCount: Int
    let failures: [String]
}

nonisolated enum BatchRenamePlanner {
    static func plans(
        for entries: [FileEntry],
        prefix: String,
        suffix: String,
        addsNumber: Bool,
        startingAt: Int
    ) -> [BatchRenamePlan] {
        entries
            .sorted { $0.pathKey.localizedStandardCompare($1.pathKey) == .orderedAscending }
            .enumerated()
            .map { index, entry in
                let originalName = entry.path.lastPathComponent
                let extensionPart = entry.isDirectory || entry.fileExtension.isEmpty ? "" : ".\(entry.fileExtension)"
                let baseName = extensionPart.isEmpty
                    ? originalName
                    : String(originalName.dropLast(extensionPart.count))
                let numberPart = addsNumber ? String(format: " - %03d", startingAt + index) : ""
                let newName = "\(prefix)\(baseName)\(suffix)\(numberPart)\(extensionPart)"
                return BatchRenamePlan(source: entry.path, destination: entry.path.deletingLastPathComponent().appendingPathComponent(newName))
            }
    }

    static func validationError(for plans: [BatchRenamePlan]) -> String? {
        guard !plans.isEmpty else { return "No items were selected." }
        var destinationPaths = Set<String>()

        for plan in plans {
            let source = normalizedPath(plan.source)
            let destination = normalizedPath(plan.destination)
            guard plan.destination.lastPathComponent.isEmpty == false,
                  !plan.destination.lastPathComponent.contains("/")
            else { return "A new name is invalid." }
            guard source != destination else { return "At least one name would not change." }
            guard destinationPaths.insert(destination.lowercased()).inserted else {
                return "Two items would receive the same name."
            }
            if FileManager.default.fileExists(atPath: plan.destination.path(percentEncoded: false)) {
                return "\(plan.destination.lastPathComponent) already exists."
            }
        }
        return nil
    }

    private static func normalizedPath(_ url: URL) -> String {
        url.standardizedFileURL.resolvingSymlinksInPath().path(percentEncoded: false)
    }
}

nonisolated enum BatchRenameExecutor {
    static func apply(_ plans: [BatchRenamePlan]) -> BatchRenameResult {
        guard let validationError = BatchRenamePlanner.validationError(for: plans) else {
            var renamedCount = 0
            var failures: [String] = []
            for plan in plans {
                do {
                    try FileManager.default.moveItem(at: plan.source, to: plan.destination)
                    renamedCount += 1
                } catch {
                    failures.append("\(plan.source.lastPathComponent): \(error.localizedDescription)")
                }
            }
            return BatchRenameResult(renamedCount: renamedCount, failures: failures)
        }
        return BatchRenameResult(renamedCount: 0, failures: [validationError])
    }
}
