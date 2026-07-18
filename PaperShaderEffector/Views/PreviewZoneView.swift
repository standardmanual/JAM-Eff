import SwiftUI
import MetalKit
import UIKit

// MARK: - MTKView UIViewRepresentable Wrapper

struct MetalPreviewView: UIViewRepresentable {
    @EnvironmentObject var session: EditSession
    let renderer: Renderer

    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device                = renderer.device
        mtkView.delegate              = renderer
        mtkView.colorPixelFormat      = .bgra8Unorm
        mtkView.framebufferOnly       = false
        mtkView.isPaused              = true
        mtkView.enableSetNeedsDisplay = true
        mtkView.backgroundColor       = .black
        renderer.mtkView              = mtkView
        return mtkView
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        renderer.shaderStack = session.shaderStack

        // Update canvas pixel size and flush image texture cache on ratio change
        let ratioKey = session.exportSpec.ratio.rawValue
        if renderer.currentRatioKey != ratioKey {
            renderer.currentRatioKey = ratioKey
            renderer.canvasPixelSize = session.exportSpec.ratio.pixelSize
            renderer.imageTextureCache.removeAll()
        }

        // Sync selected layer transform for gesture targeting
        let selectedLayer = session.selectedLayer
        let newSelectedID = selectedLayer?.isImageLayer == true ? selectedLayer?.id : nil
        if renderer.selectedLayerID != newSelectedID {
            renderer.selectedLayerID = newSelectedID
            renderer.selectedLayerTransform = selectedLayer?.imageTransform ?? .identity
        }
    }
}

// MARK: - GestureOverlayView

struct GestureOverlayView: View {
    let renderer: Renderer
    let viewSize: CGSize
    @EnvironmentObject var session: EditSession

    @GestureState private var magnification: CGFloat = 1.0
    @GestureState private var rotationAngle: Angle = .zero
    @GestureState private var dragOffset: CGSize = .zero

    private var isTargetingImageLayer: Bool {
        session.selectedLayer?.isImageLayer == true
    }

    var body: some View {
        let magnifyGesture = MagnificationGesture()
            .updating($magnification) { value, state, _ in state = value }
            .onEnded { value in
                guard isTargetingImageLayer else { return }
                renderer.selectedLayerTransform.scale = max(0.05, renderer.selectedLayerTransform.scale * Float(value))
                syncTransformToSession()
            }

        let rotateGesture = RotationGesture()
            .updating($rotationAngle) { value, state, _ in state = value }
            .onEnded { value in
                guard isTargetingImageLayer else { return }
                renderer.selectedLayerTransform.rotation += Float(value.radians)
                syncTransformToSession()
            }

        let dragGesture = DragGesture(minimumDistance: 0)
            .updating($dragOffset) { value, state, _ in state = value.translation }
            .onEnded { value in
                guard isTargetingImageLayer else { return }
                let uvDX = Float(value.translation.width  / viewSize.width)
                let uvDY = Float(value.translation.height / viewSize.height)
                renderer.selectedLayerTransform.offsetX += uvDX
                renderer.selectedLayerTransform.offsetY += uvDY
                syncTransformToSession()
            }

        Color.clear
            .contentShape(Rectangle())
            .gesture(
                SimultaneousGesture(
                    SimultaneousGesture(magnifyGesture, rotateGesture),
                    dragGesture
                )
            )
    }

    private func syncTransformToSession() {
        guard let id = renderer.selectedLayerID,
              let idx = session.shaderStack.firstIndex(where: { $0.id == id })
        else { return }
        session.shaderStack[idx].imageTransform = renderer.selectedLayerTransform
    }
}

// MARK: - PreviewZoneView (Zone 2, 320pt fixed)

struct PreviewZoneView: View {
    @EnvironmentObject var session: EditSession
    let renderer: Renderer

    private let zoneHeight: CGFloat = 320

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.black.ignoresSafeArea(edges: [])

            previewBox

            // Ratio toggle pill (bottom-right)
            RatioToggle(ratio: $session.exportSpec.ratio)
                .padding(.bottom, 12)
                .padding(.trailing, 12)

            // Reset transform button (bottom-left) — only shown for image layers
            if session.selectedLayer?.isImageLayer == true {
                Button {
                    renderer.selectedLayerTransform = .identity
                    syncTransformToSession()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(8)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .padding(.bottom, 12)
                .padding(.leading, 12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }
        }
        .frame(height: zoneHeight)
    }

    @ViewBuilder
    private var previewBox: some View {
        GeometryReader { geo in
            let ratio  = session.exportSpec.ratio.aspectRatio
            let maxW   = geo.size.width
            let maxH   = zoneHeight
            let (boxW, boxH): (CGFloat, CGFloat) = {
                let wByH = maxH * ratio
                return wByH <= maxW ? (wByH, maxH) : (maxW, maxW / ratio)
            }()

            MetalPreviewView(renderer: renderer)
                .frame(width: boxW, height: boxH)
                .position(x: geo.size.width / 2, y: zoneHeight / 2)
                .overlay(
                    GestureOverlayView(renderer: renderer, viewSize: CGSize(width: boxW, height: boxH))
                        .environmentObject(session)
                )
        }
    }

    private func syncTransformToSession() {
        guard let id = renderer.selectedLayerID,
              let idx = session.shaderStack.firstIndex(where: { $0.id == id })
        else { return }
        session.shaderStack[idx].imageTransform = renderer.selectedLayerTransform
    }
}
