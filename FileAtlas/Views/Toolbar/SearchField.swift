//
//  SearchField.swift
//  FileAtlas
//
//  Suchfeld der Toolbar. Akzeptiert Namen, „.ext" oder Größenausdrücke („> 10 MB").
//

import SwiftUI

struct SearchField: View {
    @Binding var text: String
    @Binding var searchAllFolders: Bool

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(AppTheme.theme.textSecondary)
                TextField("Search name, .ext or > 10 MB", text: $text)
                    .textFieldStyle(.plain)
                    .frame(minWidth: 200)
                if !text.isEmpty {
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(AppTheme.theme.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.quaternary, in: .rect(cornerRadius: 7))

            Toggle("Search all folders", isOn: $searchAllFolders)
                .toggleStyle(.button)
                .controlSize(.small)
                .help("Search all folders")
        }
    }
}
