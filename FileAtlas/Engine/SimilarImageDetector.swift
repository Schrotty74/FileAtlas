import Foundation
import ImageIO
import Vision

@MainActor
struct SimilarImageGroup: Identifiable {
    let id = UUID()
    let entries: [FileEntry]
}

@MainActor
enum SimilarImageDetector {
    private static let supportedExtensions: Set<String> = ["jpg", "jpeg", "png", "heic", "heif", "tiff", "gif", "webp"]

    /// Vision feature prints remain entirely on-device. A bounded candidate set
    /// keeps opening the analysis predictable on large photo libraries.
    static func groups(in entries: [FileEntry], limit: Int = 250) -> [SimilarImageGroup] {
        let candidates = entries.filter {
            !$0.isDirectory && supportedExtensions.contains($0.fileExtension.lowercased())
        }.prefix(limit)

        var prints: [(FileEntry, VNFeaturePrintObservation)] = []
        for entry in candidates {
            guard let source = CGImageSourceCreateWithURL(entry.path as CFURL, nil),
                  let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
            else { continue }
            let request = VNGenerateImageFeaturePrintRequest()
            let handler = VNImageRequestHandler(cgImage: image)
            guard (try? handler.perform([request])) != nil,
                  let print = request.results?.first as? VNFeaturePrintObservation
            else { continue }
            prints.append((entry, print))
        }

        var groups: [[FileEntry]] = []
        var consumed = Set<FileEntry.ID>()
        for index in prints.indices where !consumed.contains(prints[index].0.id) {
            var matches = [prints[index].0]
            for candidate in prints.indices where candidate > index {
                var distance: Float = 1
                guard (try? prints[index].1.computeDistance(&distance, to: prints[candidate].1)) != nil,
                      distance < 0.18
                else { continue }
                matches.append(prints[candidate].0)
            }
            if matches.count > 1 {
                consumed.formUnion(matches.map(\.id))
                groups.append(matches)
            }
        }
        return groups.map { SimilarImageGroup(entries: $0) }
    }
}
