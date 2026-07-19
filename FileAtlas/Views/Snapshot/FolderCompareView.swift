//
//  FolderCompareView.swift
//  FileAtlas
//

import SwiftUI
import AppKit

struct FolderCompareView: View {
    @Environment(IndexViewModel.self) private var vm
    @Environment(\.dismiss) private var dismiss
    @Environment(MotionPreferences.self) private var motion
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @State private var folderA: URL?
    @State private var folderB: URL?
    @State private var rows: [FolderCompareRow] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Ordner vergleichen")
                    .font(.headline)
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding()

            Divider()

            HStack(spacing: 12) {
                folderPicker(title: "Ordner A", url: folderA) { folderA = chooseFolder() }
                folderPicker(title: "Ordner B", url: folderB) { folderB = chooseFolder() }
                Button("Vergleichen") { compare() }
                    .disabled(folderA == nil || folderB == nil)
                    .buttonStyle(MotionButtonStyle())
            }
            .padding()

            Table(rows) {
                TableColumn("Status") { row in
                    Text(row.status.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(row.status.color)
                }
                .width(120)
                TableColumn("Pfad", value: \.relativePath)
                TableColumn("Größe") { row in
                    Text(row.sizeLabel)
                        .font(.caption.monospacedDigit())
                }
                .width(100)
            }
            .animation(isMotionEnabled ? FileAtlasMotion.standard : nil, value: rows.map(\.relativePath))
        }
        .frame(width: 760, height: 520)
    }

    private func folderPicker(title: String, url: URL?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption.weight(.semibold))
                Text(url?.lastPathComponent ?? "Auswählen…")
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(MotionButtonStyle())
    }

    private func chooseFolder() -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        return panel.runModal() == .OK ? panel.url : nil
    }

    private func compare() {
        guard let folderA, let folderB else { return }
        let ignored = Set(vm.skippedFolderNames.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }.filter { !$0.isEmpty })
        let a = FolderSnapshot.scan(folderA, ignoredFolderPrefixes: ignored)
        let b = FolderSnapshot.scan(folderB, ignoredFolderPrefixes: ignored)
        let keys = Set(a.keys).union(b.keys).sorted { $0.localizedStandardCompare($1) == .orderedAscending }
        rows = keys.map { key in
            let left = a[key]
            let right = b[key]
            let status: FolderCompareStatus
            if left != nil && right != nil { status = .both }
            else if left != nil { status = .onlyA }
            else { status = .onlyB }
            return FolderCompareRow(relativePath: key, status: status, size: left?.size ?? right?.size ?? 0)
        }
    }

    private var isMotionEnabled: Bool {
        !motion.reduceMotion && !systemReduceMotion
    }
}

private struct FolderSnapshot {
    let size: Int64

    static func scan(_ root: URL, ignoredFolderPrefixes: Set<String>) -> [String: FolderSnapshot] {
        let keys: [URLResourceKey] = [.isDirectoryKey, .isRegularFileKey, .fileSizeKey, .nameKey]
        guard let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: keys, options: [.skipsHiddenFiles]) else { return [:] }
        let rootPath = root.standardizedFileURL.path(percentEncoded: false)
        var result: [String: FolderSnapshot] = [:]
        for case let url as URL in enumerator {
            guard let values = try? url.resourceValues(forKeys: Set(keys)) else { continue }
            let name = values.name ?? url.lastPathComponent
            if name == ".DS_Store" { continue }
            if values.isDirectory == true {
                let lowerName = name.lowercased()
                if ignoredFolderPrefixes.contains(where: { lowerName.hasPrefix($0) }) {
                    enumerator.skipDescendants()
                }
                continue
            }
            guard values.isRegularFile == true else { continue }
            let path = url.standardizedFileURL.path(percentEncoded: false)
            let relative = path.replacingOccurrences(of: rootPath + "/", with: "")
            result[relative] = FolderSnapshot(size: Int64(values.fileSize ?? 0))
        }
        return result
    }
}

private struct FolderCompareRow: Identifiable {
    let id = UUID()
    let relativePath: String
    let status: FolderCompareStatus
    let size: Int64

    var sizeLabel: String { ByteCountFormatter.string(fromByteCount: size, countStyle: .file) }
}

private enum FolderCompareStatus {
    case onlyA
    case onlyB
    case both

    var title: String {
        switch self {
        case .onlyA: return "Nur in A"
        case .onlyB: return "Nur in B"
        case .both: return "In beiden"
        }
    }

    var color: Color {
        switch self {
        case .onlyA: return AppTheme.gold
        case .onlyB: return .red
        case .both: return AppTheme.theme.accentColor
        }
    }
}
