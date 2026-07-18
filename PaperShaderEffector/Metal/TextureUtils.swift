import Metal
import UIKit
import CoreImage

// MARK: - TextureUtils

enum TextureUtils {

    /// UIImage → MTLTexture (BGRA8Unorm)
    static func texture(from image: UIImage, device: MTLDevice) -> MTLTexture? {
        guard let cgImage = image.cgImage else { return nil }

        let width  = cgImage.width
        let height = cgImage.height

        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm,
            width:  width,
            height: height,
            mipmapped: false
        )
        descriptor.usage = [.shaderRead, .shaderWrite, .renderTarget]
        descriptor.storageMode = .shared

        guard let texture = device.makeTexture(descriptor: descriptor) else { return nil }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo.byteOrder32Little.rawValue |
                         CGImageAlphaInfo.premultipliedFirst.rawValue

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else { return nil }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let data = context.data else { return nil }
        texture.replace(
            region: MTLRegionMake2D(0, 0, width, height),
            mipmapLevel: 0,
            withBytes: data,
            bytesPerRow: width * 4
        )
        return texture
    }

    /// MTLTexture → UIImage
    static func image(from texture: MTLTexture) -> UIImage? {
        let width  = texture.width
        let height = texture.height
        let bytesPerRow = width * 4
        var bytes = [UInt8](repeating: 0, count: height * bytesPerRow)

        texture.getBytes(
            &bytes,
            bytesPerRow: bytesPerRow,
            from: MTLRegionMake2D(0, 0, width, height),
            mipmapLevel: 0
        )

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo.byteOrder32Little.rawValue |
                         CGImageAlphaInfo.premultipliedFirst.rawValue

        guard let context = CGContext(
            data: &bytes,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ), let cgImage = context.makeImage() else { return nil }

        return UIImage(cgImage: cgImage)
    }

    /// 사진을 캔버스 비율에 맞게 letterbox/pillarbox 합성 (contain 모드)
    static func fitImage(_ image: UIImage, canvasSize: CGSize) -> UIImage {
        let photoSize = image.size
        guard photoSize.width > 0, photoSize.height > 0 else { return image }
        let scaleX = canvasSize.width  / photoSize.width
        let scaleY = canvasSize.height / photoSize.height
        let scale  = min(scaleX, scaleY)
        let fittedW = photoSize.width  * scale
        let fittedH = photoSize.height * scale
        let offsetX = (canvasSize.width  - fittedW) / 2
        let offsetY = (canvasSize.height - fittedH) / 2

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: canvasSize, format: format).image { ctx in
            UIColor.black.setFill()
            ctx.fill(CGRect(origin: .zero, size: canvasSize))
            image.draw(in: CGRect(x: offsetX, y: offsetY, width: fittedW, height: fittedH))
        }
    }

    /// 이미지를 캔버스 크기에 contain-fit으로 배치한 RGBA 텍스처 생성 (투명 배경).
    /// 결과 텍스처는 encodeOverlay(scale=1.0)로 합성한다.
    static func canvasTexture(from image: UIImage, canvasSize: CGSize, device: MTLDevice) -> MTLTexture? {
        let photoSize = image.size
        guard photoSize.width > 0, photoSize.height > 0 else { return nil }

        let scale   = min(canvasSize.width / photoSize.width, canvasSize.height / photoSize.height)
        let fittedW = photoSize.width  * scale
        let fittedH = photoSize.height * scale
        let offsetX = (canvasSize.width  - fittedW) / 2
        let offsetY = (canvasSize.height - fittedH) / 2

        // UIGraphicsImageRenderer handles UIImage.imageOrientation automatically
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let canvas = UIGraphicsImageRenderer(size: canvasSize, format: format).image { _ in
            image.draw(in: CGRect(x: offsetX, y: offsetY, width: fittedW, height: fittedH))
        }

        guard let cgImage = canvas.cgImage else { return nil }
        let w = Int(canvasSize.width), h = Int(canvasSize.height)

        let desc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm, width: w, height: h, mipmapped: false)
        desc.usage = [.shaderRead, .shaderWrite]
        desc.storageMode = .shared
        guard let texture = device.makeTexture(descriptor: desc) else { return nil }

        var bytes = [UInt8](repeating: 0, count: w * h * 4)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: &bytes, width: w, height: h, bitsPerComponent: 8,
            bytesPerRow: w * 4, space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: w, height: h))

        texture.replace(region: MTLRegionMake2D(0, 0, w, h), mipmapLevel: 0,
                        withBytes: bytes, bytesPerRow: w * 4)
        return texture
    }

    /// 빈 렌더 타깃 텍스처 생성 (BGRA8Unorm)
    nonisolated static func makeRenderTarget(width: Int, height: Int, device: MTLDevice) -> MTLTexture? {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm,
            width: width,
            height: height,
            mipmapped: false
        )
        descriptor.usage = [.shaderRead, .shaderWrite, .renderTarget]
        descriptor.storageMode = .shared
        return device.makeTexture(descriptor: descriptor)
    }
}
