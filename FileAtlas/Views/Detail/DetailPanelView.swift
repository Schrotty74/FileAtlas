//
//  DetailPanelView.swift
//  FileAtlas
//
//  Rechte Spalte: Vorschau + Metadaten der ausgewählten Datei / des Ordners.
//

import SwiftUI
import AppKit
import Security

private struct AppBundleMetadata: Sendable, Equatable {
    let appName: String?
    let version: String?
    let developer: String?
    let bundleIdentifier: String?

    nonisolated var hasVisibleValues: Bool {
        appName != nil || version != nil || developer != nil || bundleIdentifier != nil
    }
}

struct DetailPanelView: View {
    @Environment(IndexViewModel.self) private var vm
    @State private var appBundleMetadata: AppBundleMetadata?

    var body: some View {
        Group {
            if let entry = vm.selectedEntry {
                detail(for: entry)
            } else {
                placeholder
            }
        }
        .background(AppTheme.surface)
    }

    // MARK: - Detail

    private func detail(for entry: FileEntry) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if entry.isDirectory {
                    folderHeader(entry)
                } else {
                    QuickLookPreview(
                        url: entry.path,
                        accessURL: vm.securityScopedAccessRoot(for: entry.path),
                        fallbackIcon: FileRowView.icon(for: entry)
                    )
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(entry.name)
                            .font(.headline)
                            .foregroundStyle(AppTheme.theme.textPrimary)
                            .lineLimit(2)
                        if entry.isDuplicate { DuplicateBadge() }
                    }
                    Text(entry.isDirectory ? "Folder" : entry.fileExtension.uppercased())
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.theme.textSecondary)
                }

                metadata(entry)

                if let appBundleMetadata {
                    appMetadata(appBundleMetadata)
                }

                if entry.isDuplicate {
                    duplicatesGroup(entry)
                }

                actions(entry)

                Spacer(minLength: 0)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .task(id: entry.id) {
            await loadAppBundleMetadata(for: entry)
        }
    }

    private func folderHeader(_ entry: FileEntry) -> some View {
        let contained = vm.entries.filter {
            $0.id != entry.id && $0.pathKey.hasPrefix(entry.pathKey + "/")
        }
        let total = contained.reduce(Int64(0)) { $0 + $1.size }
        return VStack(spacing: 10) {
            Image(systemName: "folder.fill")
                .font(.system(size: 52))
                .foregroundStyle(AppTheme.theme.accentColor)
            Text("\(contained.count) items · \(ByteCountFormatter.string(fromByteCount: total, countStyle: .file))")
                .font(.caption)
                .foregroundStyle(AppTheme.theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 160)
        .background(AppTheme.surfaceRaised, in: .rect(cornerRadius: AppTheme.theme.cornerRadius))
    }

    @ViewBuilder
    private func appMetadata(_ metadata: AppBundleMetadata) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("App Metadata")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.theme.textSecondary)

            if let appName = metadata.appName {
                metaRow("App Name", appName)
            }
            if let version = metadata.version {
                metaRow("Version", version)
            }
            if let developer = metadata.developer {
                metaRow("Developer", developer)
            }
            if let bundleIdentifier = metadata.bundleIdentifier {
                metaRow("Bundle ID", bundleIdentifier)
            }
        }
        .padding(14)
        .background(AppTheme.surfaceRaised, in: .rect(cornerRadius: AppTheme.theme.cornerRadius))
    }

    private func metadata(_ entry: FileEntry) -> some View {
        VStack(spacing: 9) {
            metaRow("Path", entry.pathKey)
            metaRow("Size", entry.formattedSize)
            metaRow("Created", dateString(entry.created))
            metaRow("Modified", dateString(entry.modified))
            metaRow("Type", entry.isDirectory ? "Folder" : entry.fileExtension.uppercased())
        }
        .padding(14)
        .background(AppTheme.surfaceRaised, in: .rect(cornerRadius: AppTheme.theme.cornerRadius))
    }

    private func metaRow(_ label: LocalizedStringKey, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.caption)
                .foregroundStyle(AppTheme.theme.textSecondary)
            Spacer()
            Text(value)
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.theme.textPrimary)
                .multilineTextAlignment(.trailing)
                .textSelection(.enabled)
                .lineLimit(3)
                .truncationMode(.middle)
        }
    }

    private func duplicatesGroup(_ entry: FileEntry) -> some View {
        let others = vm.entries.filter {
            $0.duplicateGroupID != nil && $0.duplicateGroupID == entry.duplicateGroupID && $0.id != entry.id
        }
        return VStack(alignment: .leading, spacing: 6) {
            Text("Identical files")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.gold)
            ForEach(others) { other in
                Text(other.pathKey)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.theme.textSecondary)
                    .lineLimit(2)
                    .truncationMode(.middle)
                    .textSelection(.enabled)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(AppTheme.gold.opacity(0.08), in: .rect(cornerRadius: AppTheme.theme.cornerRadius))
    }

    private func actions(_ entry: FileEntry) -> some View {
        VStack(spacing: 8) {
            Button {
                NSWorkspace.shared.activateFileViewerSelecting([entry.path])
            } label: {
                Label("Show in Finder", systemImage: "folder")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            if !entry.isDirectory {
                Button {
                    vm.quickLookSelectedEntry()
                } label: {
                    Label("Open Quick Look", systemImage: "eye")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.theme.accentColor)
            }
        }
    }

    // MARK: - Placeholder

    private var placeholder: some View {
        VStack(spacing: 10) {
            Image(systemName: "sidebar.right")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(AppTheme.theme.textSecondary)
            Text("Select a file to preview")
                .font(.callout)
                .foregroundStyle(AppTheme.theme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func dateString(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df.string(from: date)
    }

    private func loadAppBundleMetadata(for entry: FileEntry) async {
        guard Self.isAppBundle(entry) else {
            appBundleMetadata = nil
            return
        }

        appBundleMetadata = nil
        let url = entry.path
        let metadata = await Task.detached(priority: .utility) {
            Self.readAppBundleMetadata(from: url)
        }.value

        guard vm.selectedEntry?.id == entry.id else { return }
        appBundleMetadata = metadata
    }

    private nonisolated static func isAppBundle(_ entry: FileEntry) -> Bool {
        guard entry.isDirectory,
              entry.path.pathExtension.caseInsensitiveCompare("app") == .orderedSame
        else { return false }

        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(
            atPath: entry.path.path(percentEncoded: false),
            isDirectory: &isDirectory
        )
        return exists && isDirectory.boolValue
    }

    private nonisolated static func readAppBundleMetadata(from url: URL) -> AppBundleMetadata? {
        guard let bundle = Bundle(url: url),
              let info = bundle.infoDictionary
        else { return nil }

        let bundleIdentifier = trimmed(info["CFBundleIdentifier"] as? String)
        let displayName = trimmed(info["CFBundleDisplayName"] as? String)
        let bundleName = trimmed(info["CFBundleName"] as? String)
        let version = trimmed(info["CFBundleShortVersionString"] as? String)
        let developer = signingDeveloper(for: url) ?? developerFallback(from: bundleIdentifier)

        let metadata = AppBundleMetadata(
            appName: displayName ?? bundleName,
            version: version,
            developer: developer,
            bundleIdentifier: bundleIdentifier
        )
        return metadata.hasVisibleValues ? metadata : nil
    }

    private nonisolated static func signingDeveloper(for url: URL) -> String? {
        var staticCode: SecStaticCode?
        guard SecStaticCodeCreateWithPath(url as CFURL, SecCSFlags(), &staticCode) == errSecSuccess,
              let staticCode
        else { return nil }

        var signingInfo: CFDictionary?
        let flags = SecCSFlags(rawValue: kSecCSSigningInformation)
        guard SecCodeCopySigningInformation(staticCode, flags, &signingInfo) == errSecSuccess,
              let info = signingInfo as? [String: Any]
        else { return nil }

        return trimmed(info[kSecCodeInfoTeamIdentifier as String] as? String)
    }

    private nonisolated static func developerFallback(from bundleIdentifier: String?) -> String? {
        guard let bundleIdentifier else { return nil }
        let parts = bundleIdentifier.split(separator: ".")
        guard parts.count >= 2 else { return nil }
        return parts.prefix(2).joined(separator: ".")
    }

    private nonisolated static func trimmed(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty ? nil : trimmedValue
    }
}
