# 아키텍처 설계 노트 — Paper Shader Effector

작성: lead / 2026-07-16

---

## Xcode 프로젝트 설정

| 항목 | 값 |
|------|-----|
| Product Name | PaperShaderEffector |
| Bundle ID | com.standardmanual.PaperShaderEffector |
| Deployment Target | iOS 17.0 |
| Swift Version | 5.10 |
| Interface | SwiftUI |
| Language | Swift |
| Orientation | Portrait only (Info.plist) |

---

## 디렉토리 / 파일 역할

```
PaperShaderEffector/
├── App/
│   ├── PaperShaderEffectorApp.swift   — @main, WindowGroup, .preferredColorScheme(.light)
│   └── ContentView.swift              — 앱 루트: HomeView / EditorView 전환
├── Views/
│   ├── HomeView.swift                 — PhotosPicker 전체화면, 사진 선택 후 EditorView push
│   ├── EditorView.swift               — 4-Zone 레이아웃 컨테이너 (NavBar+Preview+Tray+Params)
│   ├── PreviewZoneView.swift          — Zone2: MTKView 래퍼 + RatioToggle
│   ├── LayerTrayView.swift            — Zone3: 가로 스크롤, LayerChip 80×80pt
│   ├── ParamPanelView.swift           — Zone4: 섹션(색상/조절/레이아웃) 세로 스크롤
│   ├── AddShaderSheet.swift           — Bottom Sheet: 쉐이더 3열 그리드 선택
│   ├── ParamRows/
│   │   ├── FloatParamRow.swift        — Slider 행 52pt
│   │   ├── ColorParamRow.swift        — ColorPicker 행 52pt
│   │   ├── ColorsParamRow.swift       — ColorPicker 배열 + +/- 버튼
│   │   ├── BoolParamRow.swift         — Toggle 행 44pt
│   │   └── EnumParamRow.swift         — Picker(segmented/menu) 행 44pt
│   └── Components/
│       ├── RatioToggle.swift          — 4:5 / 9:16 Pill 버튼
│       ├── LayerChip.swift            — 80×80pt 레이어 칩
│       └── ToastView.swift            — 저장 완료 토스트
├── Metal/
│   ├── Renderer.swift                 — MTKViewDelegate, CADisplayLink, 렌더 루프
│   ├── ShaderPipeline.swift           — MTLRenderPipelineState 생성/캐시
│   ├── TextureUtils.swift             — UIImage ↔ MTLTexture 변환
│   └── Shaders/
│       ├── MeshGradient.metal         — Mesh Gradient MSL (Phase 1)
│       └── Waves.metal                — Waves MSL (Phase 1)
├── Models/
│   ├── EditSession.swift              — 전체 편집 상태 (ObservableObject)
│   ├── ShaderLayer.swift              — 단일 레이어 (effectType + params + opacity)
│   ├── ShaderEffect.swift             — ShaderEffect enum 29종 + 기본 파라미터 팩토리
│   └── ExportSpec.swift               — OutputRatio / OutputFormat
└── Export/
    └── ImageExporter.swift            — MTLTexture → CGImage → PHPhotoLibrary
```

---

## 데이터 플로우

```
사용자 입력
    │
    ▼
EditSession (ObservableObject)
    ├── sourcePhoto: SourcePhoto
    ├── shaderStack: [ShaderLayer]   ← 레이어 추가/삭제/순서변경
    ├── selectedLayerIndex: Int
    └── exportSpec: ExportSpec       ← 비율 전환 (4:5 / 9:16)

    ↓ @Published 변화 감지
    ↓
Renderer (MTKViewDelegate)
    ├── time: Float (CADisplayLink)
    ├── inputTexture: MTLTexture     ← sourcePhoto
    └── renderLoop():
          for layer in shaderStack:
              ShaderPipeline.encode(layer, inputTex) → outputTex
          blit(outputTex → drawable)

    ↓ 저장 버튼
    ↓
ImageExporter.export(renderer, exportSpec)
    → MTLTexture (full res) → CGImage → UIImage → PHPhotoLibrary
```

---

## Metal 렌더링 설계

### 텍스처 해상도
- Preview: 393×(ratio)pt @ 3x → ~1179px 기준 프리뷰 텍스처
- Export: 1080px 기준 (1080×1350 for 4:5, 1080×1920 for 9:16)

### 파이프라인 상태 (ShaderPipeline)
- ShaderEffect별로 1개 MTLRenderPipelineState 캐시
- vertex function: `vertexPassthrough` (공통 — fullscreen quad)
- fragment function: 각 효과별 (e.g. `meshGradientFragment`)

### Uniform Buffer 레이아웃
```metal
struct CommonUniforms {
    float time;
    float2 resolution;
    float scale;
    float rotation;
    float originX; float originY;
    float offsetX; float offsetY;
    int fit; // 0=none, 1=contain, 2=cover
};
// 각 쉐이더별 추가 uniform struct는 별도 buffer(1)
```

### Vertex (공통 fullscreen quad)
```
buffer(0): 4개 꼭짓점 [position + texCoord]
```

---

## SwiftUI 뷰 계층

```
ContentView
 └─ NavigationStack
     ├─ HomeView                    (.navigationDestination)
     └─ EditorView
         ├─ Zone1: NavBar (HStack, 44pt)
         ├─ Zone2: PreviewZoneView (320pt fixed)
         │   ├─ MTKViewRepresentable
         │   └─ RatioToggle (우하단 overlay)
         ├─ Zone3: LayerTrayView (96pt fixed)
         │   └─ ScrollView(.horizontal) → LazyHStack → LayerChip × n → AddButton
         └─ Zone4: ParamPanelView (remaining, ScrollView)
             ├─ Section "색상"
             │   ├─ ColorParamRow × n
             │   └─ ColorsParamRow × n
             ├─ Section "조절"
             │   ├─ FloatParamRow × n
             │   ├─ BoolParamRow × n
             │   └─ EnumParamRow × n
             └─ Section "레이아웃" (접기 기본)
                 └─ FloatParamRow × 7 (공통 파라미터)
```

---

## 주요 아키텍처 결정

1. **EditSession은 @StateObject로 EditorView에 생성**, 자식 뷰에는 @EnvironmentObject로 주입
2. **Renderer는 EditorView의 Coordinator**가 소유 — MTKView.delegate = renderer
3. **ShaderPipeline은 싱글턴** — MTLDevice 공유, pipelineState 캐시 딕셔너리
4. **파라미터 변경은 즉시 반영** — ShaderLayer.params 변경 → @Published → Renderer가 다음 draw()에서 사용
5. **시간 uniform**: CADisplayLink가 Renderer.time을 누적 증가 → draw()에서 MTLBuffer에 씀
6. **Export**: 별도 Texture (export 해상도) 생성 → 동일 파이프라인으로 1회 렌더 → CGImage 변환
