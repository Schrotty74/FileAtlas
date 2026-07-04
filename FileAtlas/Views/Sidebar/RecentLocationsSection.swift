//
//  RecentLocationsSection.swift
//  FileAtlas
//

import SwiftUI

struct RecentLocationsSection: View {
    @Environment(IndexViewModel.self) private var vm
    @State private var expandedPaths: Set<String> = []
    @State private var childrenByPath: [String: [URL]] = [:]
    @State private var loadingPaths: Set<String> = []
    @State private var hoveredPath: String?

    var body: some View {
        if !vm.recentScanRoots.isEmpty {
            Section {
                ForEach(nodes) { node in
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

    private var nodes: [LocationTreeNode] {
        vm.recentScanRoots.flatMap { url in
            nodes(for: url, level: 0, isSavedRoot: true, accessRoot: vm.securityScopedAccessRoot(for: url))
        }
    }

    private func nodes(for url: URL, level: Int, isSavedRoot: Bool, accessRoot: URL) -> [LocationTreeNode] {
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
}
