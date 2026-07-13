import AppKit
import SwiftUI

struct GitHubMark: View {
    @Environment(\.colorScheme) private var colorScheme

    let size: CGFloat

    var body: some View {
        Button {
            NSWorkspace.shared.open(URL(string: "https://github.com/Schrotty74/FileAtlas")!)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.96) : Color.black.opacity(0.88))
                    .overlay {
                        RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                            .strokeBorder(colorScheme == .dark ? Color.white.opacity(0.72) : Color.black.opacity(0.42), lineWidth: 1)
                    }

                Image(nsImage: image(named: colorScheme == .dark ? "github-invertocat-black" : "github-invertocat-white"))
                    .resizable()
                    .scaledToFit()
                    .padding(size * 0.12)
            }
            .frame(width: size, height: size)
        }
        .buttonStyle(.plain)
        .help("FileAtlas auf GitHub")
        .accessibilityLabel("FileAtlas auf GitHub")
    }
}

struct DiscordMark: View {
    let size: CGFloat

    var body: some View {
        Button {
            NSWorkspace.shared.open(URL(string: "https://discord.gg/RbsvqRCPQ")!)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                    .fill(Color(red: 0.35, green: 0.40, blue: 0.95))

                Image(nsImage: image(named: "discord-mark-white"))
                    .resizable()
                    .scaledToFit()
                    .padding(size * 0.14)
            }
            .frame(width: size, height: size)
        }
        .buttonStyle(.plain)
        .help("FileAtlas-Community auf Discord")
        .accessibilityLabel("FileAtlas-Community auf Discord")
    }
}

private func image(named name: String) -> NSImage {
    guard let url = Bundle.main.url(forResource: name, withExtension: "svg") else {
        return NSImage()
    }
    return NSImage(contentsOf: url) ?? NSImage()
}
