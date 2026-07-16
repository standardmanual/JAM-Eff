import Foundation
import UIKit
import Photos
import Metal

// MARK: - ImageExporter

enum ImageExporter {

    enum ExportError: LocalizedError {
        case renderFailed
        case imageConversionFailed
        case photoLibraryDenied

        var errorDescription: String? {
            switch self {
            case .renderFailed:           return "렌더링에 실패했습니다."
            case .imageConversionFailed:  return "이미지 변환에 실패했습니다."
            case .photoLibraryDenied:     return "사진 라이브러리 접근 권한이 필요합니다."
            }
        }
    }

    /// Metal 텍스처 → 카메라롤 저장 (async)
    static func exportToPhotoLibrary(
        renderer: Renderer,
        exportSpec: ExportSpec
    ) async throws {
        // 1. Request photo library permission
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw ExportError.photoLibraryDenied
        }

        // 2. Render at export resolution
        let size = exportSpec.ratio.pixelSize
        guard let texture = renderer.renderFrame(size: size) else {
            throw ExportError.renderFailed
        }

        // 3. Convert MTLTexture → UIImage
        guard let image = TextureUtils.image(from: texture) else {
            throw ExportError.imageConversionFailed
        }

        // 4. Determine format
        let imageData: Data?
        switch exportSpec.format {
        case .image(let quality):
            imageData = image.jpegData(compressionQuality: CGFloat(quality))
        case .video:
            imageData = image.jpegData(compressionQuality: 0.95)
        }

        guard let data = imageData else {
            throw ExportError.imageConversionFailed
        }

        // 5. Save to photo library
        try await PHPhotoLibrary.shared().performChanges {
            let creationRequest = PHAssetCreationRequest.forAsset()
            creationRequest.addResource(with: .photo, data: data, options: nil)
        }
    }
}
