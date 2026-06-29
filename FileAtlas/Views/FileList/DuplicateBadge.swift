//
//  DuplicateBadge.swift
//  FileAtlas
//
//  Goldenes Status-Badge (Midnight-Teal-Signatur) für Duplikate.
//

import SwiftUI

struct DuplicateBadge: View {
    var body: some View {
        Text("Duplicate")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(AppTheme.gold)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(Capsule().fill(AppTheme.gold.opacity(0.16)))
            .overlay(Capsule().stroke(AppTheme.gold.opacity(0.4), lineWidth: 0.5))
    }
}
