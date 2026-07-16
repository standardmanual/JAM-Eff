import SwiftUI
import MetalKit
import UIKit

// MARK: - MTKView UIViewRepresentable Wrapper

struct MetalPreviewView: UIViewRepresentable {
    @EnvironmentObject var session: EditSession
    let renderer: Renderer

    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.backgroundColor = .black
        // Renderer is already set up — delegate assignment done in Renderer.init
        return mtkView
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        // Sync session state to renderer each frame
        renderer.shaderStack    = session.shaderStack
        renderer.sourceTexture  = session.sourcePhoto?.texture
    }
}

// MARK: - PreviewZoneView (Zone 2, 320pt fixed)

struct PreviewZoneView: View {
    @EnvironmentObject var session: EditSession
    let renderer: Renderer

    private let zoneHeight: CGFloat = 320

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Black background
            Color.black.ignoresSafeArea(edges: [])

            // Preview box — sized by ratio
            previewBox

            // Ratio toggle pill (bottom-right)
            RatioToggle(ratio: $session.exportSpec.ratio)
                .padding(.bottom, 12)
                .padding(.trailing, 12)
        }
        .frame(height: zoneHeight)
    }

    @ViewBuilder
    private var previewBox: some View {
        GeometryReader { geo in
            let ratio = session.exportSpec.ratio.aspectRatio
            let maxW   = geo.size.width
            let maxH   = zoneHeight

            // Fit within zone: width-constrained for 4:5, height-constrained for 9:16
            let (boxW, boxH): (CGFloat, CGFloat) = {
                let wByH = maxH * ratio
                if wByH <= maxW {
                    return (wByH, maxH)
                } else {
                    return (maxW, maxW / ratio)
                }
            }()

            MetalPreviewView(renderer: renderer)
                .frame(width: boxW, height: boxH)
                .position(x: geo.size.width / 2, y: zoneHeight / 2)
        }
    }
}
