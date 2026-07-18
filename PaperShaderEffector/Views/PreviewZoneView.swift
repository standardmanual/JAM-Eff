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
//
// onChanged로 renderer에 직접 기록 → CADisplayLink가 다음 프레임에서 읽음 (60fps).
// SwiftUI를 거치지 않으므로 뚝뚝 끊기지 않는다.

struct GestureOverlayView: View {
    let renderer: Renderer
    let viewSize: CGSize
    @EnvironmentObject var session: EditSession

    // 각 제스처가 시작될 때 캡처한 기준값 (제스처 도중 SwiftUI 재렌더 없이 유지)
    @State private var pinchBaseScale: Float = 1.0
    @State private var rotBaseAngle: Float   = 0.0
    @State private var dragBaseX: Float      = 0.0
    @State private var dragBaseY: Float      = 0.0
    @State private var isPinching  = false
    @State private var isRotating  = false
    @State private var isDragging  = false

    private var isTargetingImageLayer: Bool {
        session.selectedLayer?.isImageLayer == true
    }

    var body: some View {
        // 핀치 → 균일 스케일 (aspect ratio 유지)
        let magnifyGesture = MagnificationGesture()
            .onChanged { value in
                guard isTargetingImageLayer else { return }
                if !isPinching {
                    isPinching = true
                    pinchBaseScale = renderer.selectedLayerTransform.scale
                }
                renderer.selectedLayerTransform.scale = max(0.05, pinchBaseScale * Float(value))
            }
            .onEnded { value in
                defer { isPinching = false }
                guard isTargetingImageLayer else { return }
                renderer.selectedLayerTransform.scale = max(0.05, pinchBaseScale * Float(value))
                syncTransformToSession()
            }

        // 두 손가락 회전
        let rotateGesture = RotationGesture()
            .onChanged { value in
                guard isTargetingImageLayer else { return }
                if !isRotating {
                    isRotating = true
                    rotBaseAngle = renderer.selectedLayerTransform.rotation
                }
                renderer.selectedLayerTransform.rotation = rotBaseAngle + Float(value.radians)
            }
            .onEnded { value in
                defer { isRotating = false }
                guard isTargetingImageLayer else { return }
                renderer.selectedLayerTransform.rotation = rotBaseAngle + Float(value.radians)
                syncTransformToSession()
            }

        // 드래그 → 오프셋 이동
        let dragGesture = DragGesture(minimumDistance: 1)
            .onChanged { value in
                guard isTargetingImageLayer else { return }
                if !isDragging {
                    isDragging = true
                    dragBaseX = renderer.selectedLayerTransform.offsetX
                    dragBaseY = renderer.selectedLayerTransform.offsetY
                }
                renderer.selectedLayerTransform.offsetX = dragBaseX + Float(value.translation.width  / viewSize.width)
                renderer.selectedLayerTransform.offsetY = dragBaseY + Float(value.translation.height / viewSize.height)
            }
            .onEnded { value in
                defer { isDragging = false }
                guard isTargetingImageLayer else { return }
                renderer.selectedLayerTransform.offsetX = dragBaseX + Float(value.translation.width  / viewSize.width)
                renderer.selectedLayerTransform.offsetY = dragBaseY + Float(value.translation.height / viewSize.height)
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
