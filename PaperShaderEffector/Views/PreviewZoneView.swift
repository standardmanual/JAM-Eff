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
// isEditingMode=true일 때만 제스처를 활성화합니다.
// onChanged로 renderer에 직접 기록 → CADisplayLink가 다음 프레임에서 읽음 (60fps).

struct GestureOverlayView: View {
    let renderer: Renderer
    let viewSize: CGSize
    var isEditingMode: Bool
    @EnvironmentObject var session: EditSession

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
        if isEditingMode {
            gestureLayer
        } else {
            Color.clear  // 터치 불통 — 제스처 비활성
        }
    }

    @ViewBuilder
    private var gestureLayer: some View {
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

// MARK: - PreviewZoneView (Zone 2)

struct PreviewZoneView: View {
    @EnvironmentObject var session: EditSession
    let renderer: Renderer
    var isEditingMode: Bool = false

    private let normalHeight: CGFloat = 320

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.black

            previewBox

            // Ratio toggle — 항상 표시
            RatioToggle(ratio: $session.exportSpec.ratio)
                .padding(.bottom, 12)
                .padding(.trailing, 12)

            // Reset transform — 편집 모드에서 이미지 레이어 선택 시
            if isEditingMode && session.selectedLayer?.isImageLayer == true {
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

            // 편집 모드 힌트 (이미지 레이어 선택 시 상단)
            if isEditingMode && session.selectedLayer?.isImageLayer == true {
                Text("핀치·드래그로 조정")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.35))
                    .clipShape(Capsule())
                    .padding(.top, 12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: isEditingMode ? nil : normalHeight, alignment: .center)
        .frame(maxHeight: isEditingMode ? .infinity : normalHeight)
    }

    @ViewBuilder
    private var previewBox: some View {
        GeometryReader { geo in
            let ratio   = session.exportSpec.ratio.aspectRatio
            let maxW    = geo.size.width
            let maxH    = geo.size.height
            let (boxW, boxH): (CGFloat, CGFloat) = {
                let wByH = maxH * ratio
                return wByH <= maxW ? (wByH, maxH) : (maxW, maxW / ratio)
            }()

            MetalPreviewView(renderer: renderer)
                .frame(width: boxW, height: boxH)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
                .overlay(
                    GestureOverlayView(
                        renderer: renderer,
                        viewSize: CGSize(width: boxW, height: boxH),
                        isEditingMode: isEditingMode
                    )
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
