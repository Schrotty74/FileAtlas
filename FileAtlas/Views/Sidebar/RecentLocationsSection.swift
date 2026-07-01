//
//  RecentLocationsSection.swift
//  FileAtlas
//

import SwiftUI

struct RecentLocationsSection: View {
    @Environment(IndexViewModel.self) private var vm
    let searchText: String
    @State private var expandedPaths: Set<String> = []
    @State private var childrenByPath: [String: [URL]] = [:]
    @State private var loadingPaths: Set<String> = []
    @State private var hoveredPath: String?

    var body: some View {
        if !vm.recentScanRoots.isEmpty {
            Section {
                ForEach(visibleNodes) { node in
                    LocationTreeRow(
                        url: node.url,
                        level: node.level,
                        isSavedRoot: node.isSavedRoot,
                        kind: .quickAccess,
                        accessRoot: node.accessRoot,
                        expandedPaths: $expandedPaths,
                        childrenByPath: $childrenByPath,
                        loadingPaths: $loadingPaths,
                        hoveredPath: $hoveredPath
                    )
                }
            } header: {
                Text("Schnellzugriff")
            }
        }
    }

    private var visibleNodes: [LocationTreeNode] {
        vm.recentScanRoots.flatMap { url in
            nodes(for: url, level: 0, isSavedRoot: true, accessRoot: vm.securityScopedAccessRoot(for: url))
        }
    }

    private func nodes(for url: URL, level: Int, isSavedRoot: Bool, accessRoot: URL) -> [LocationTreeNode] {
        guard matchesSearch(url) else { return [] }
        let key = pathKey(for: url)
        var nodes = [
            LocationTreeNode(
                id: key,
                url: url,
                level: level,
                isSavedRoot: isSavedRoot,
                accessRoot: accessRoot
            )
        ]

        guard expandedPaths.contains(key),
              let children = childrenByPath[key] else { return nodes }

        for child in children {
            nodes.append(contentsOf: self.nodes(for: child, level: level + 1, isSavedRoot: false, accessRoot: accessRoot))
        }

        return nodes
    }

    private func pathKey(for url: URL) -> String {
        url.path(percentEncoded: false)
    }

    private func matchesSearch(_ url: URL) -> Bool {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return true }
        return url.lastPathComponent.localizedCaseInsensitiveContains(query)
    }
}
