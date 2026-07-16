import Foundation
import CoreGraphics

// MARK: - ExportSpec

struct ExportSpec {
    var ratio: OutputRatio = .fourFive
    var format: OutputFormat = .image(quality: 0.95)

    enum OutputRatio: String, CaseIterable {
        case fourFive    = "4:5"
        case nineSixteen = "9:16"

        var pixelSize: CGSize {
            switch self {
            case .fourFive:    return CGSize(width: 1080, height: 1350)
            case .nineSixteen: return CGSize(width: 1080, height: 1920)
            }
        }

        var aspectRatio: CGFloat {
            switch self {
            case .fourFive:    return 4.0 / 5.0
            case .nineSixteen: return 9.0 / 16.0
            }
        }
    }

    enum OutputFormat {
        case image(quality: Float)
        case video(duration: Int)
    }
}
