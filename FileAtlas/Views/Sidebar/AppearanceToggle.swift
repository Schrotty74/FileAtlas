//
//  AppearanceToggle.swift
//  FileAtlas
//
//  Hell / Dunkel / System direkt in der Sidebar.
//

import SwiftUI

struct AppearanceToggle: View {
    @Environment(AppearanceManager.self) private var appearance

    var body: some View {
        @Bindable var appearance = appearance
        VStack(alignment: .leading, spacing: 6) {
            Divider()
            Text("Appearance")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.theme.textSecondary)
            Picker("Appearance", selection: $appearance.mode) {
                Label("Light", systemImage: "sun.max").tag(AppearanceMode.light)
                Label("Dark", systemImage: "moon").tag(AppearanceMode.dark)
                Label("System", systemImage: "circle.lefthalf.filled").tag(AppearanceMode.system)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
