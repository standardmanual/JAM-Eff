# 데이터 모델 — Paper Shader Effector

## 핵심 구조

```
EditSession
├── sourcePhoto: SourcePhoto
├── shaderStack: [ShaderLayer]      // 순서 중요 (위→아래로 렌더링)
├── overlayLayers: [OverlayLayer]   // 쉐이더 합성 후 최상단
└── exportSpec: ExportSpec
```

---

## 엔티티 상세

### SourcePhoto
```swift
struct SourcePhoto {
    var image: UIImage
    var originalSize: CGSize
    var texture: MTLTexture?        // Metal 렌더링용 변환본
}
```

### ShaderLayer
```swift
struct ShaderLayer: Identifiable {
    var id: UUID
    var effectType: ShaderEffect    // 열거형: .meshGradient, .waves, ...
    var params: [String: ShaderParam] // 파라미터 딕셔너리
    var opacity: Float              // 0.0 ~ 1.0
    var isEnabled: Bool
}

// 파라미터 값 타입 (paper-design 원본 타입 그대로)
enum ShaderParam {
    case float(value: Float, min: Float, max: Float)
    case color(value: SIMD4<Float>)
    case colors(values: [SIMD4<Float>])
    case bool(value: Bool)
    case int(value: Int, options: [String])
}
```

### ShaderEffect (전체 목록)
```swift
enum ShaderEffect: String, CaseIterable {
    // Image Filters
    case paperTexture = "Paper Texture"
    case flutedGlass = "Fluted Glass"
    case water = "Water"
    case imageDithering = "Image Dithering"
    case halftoneDots = "Halftone Dots"
    case halftoneCMYK = "Halftone CMYK"
    // Effects
    case meshGradient = "Mesh Gradient"
    case staticMeshGradient = "Static Mesh Gradient"
    case staticRadialGradient = "Static Radial Gradient"
    case dithering = "Dithering"
    case grainGradient = "Grain Gradient"
    case dotOrbit = "Dot Orbit"
    case dotGrid = "Dot Grid"
    case warp = "Warp"
    case spiral = "Spiral"
    case swirl = "Swirl"
    case waves = "Waves"
    case neuroNoise = "Neuro Noise"
    case perlinNoise = "Perlin Noise"
    case simplexNoise = "Simplex Noise"
    case voronoi = "Voronoi"
    case pulsingBorder = "Pulsing Border"
    case metaballs = "Metaballs"
    case colorPanels = "Color Panels"
    case smokeRing = "Smoke Ring"
    case godRays = "God Rays"
    // Logo Animations
    case heatmap = "Heatmap"
    case liquidMetal = "Liquid Metal"
    case gemSmoke = "Gem Smoke"
}
```

### OverlayLayer
```swift
struct OverlayLayer: Identifiable {
    var id: UUID
    var image: UIImage              // 투명 PNG
    var texture: MTLTexture?
    var position: CGPoint           // 정규화 좌표 (0~1)
    var scale: Float                // 1.0 = 원본 크기
    var opacity: Float
}
```

### ExportSpec
```swift
struct ExportSpec {
    var ratio: OutputRatio
    var format: OutputFormat

    enum OutputRatio {
        case fourFive    // 4:5 = 1080×1350
        case nineSixteen // 9:16 = 1080×1920
    }

    enum OutputFormat {
        case image(quality: Float)  // JPG 0.95 or PNG
        case video(duration: Int)   // 20초 고정
    }
}
```

---

## Metal 렌더링 파이프라인

```
SourcePhoto (MTLTexture)
    │
    ▼ ShaderLayer[0].render(inputTexture) → outputTexture
    ▼ ShaderLayer[1].render(inputTexture) → outputTexture
    ▼ ...
    ▼ ShaderLayer[n].render(inputTexture) → outputTexture
    │
    ▼ OverlayLayer 합성 (alpha blending)
    │
    ▼ 비율 크롭 (4:5 / 9:16)
    │
    ├─ 이미지 저장: MTLTexture → CGImage → UIImage → Photos
    └─ 동영상 저장: 매 프레임(1/30초) MTLTexture → CVPixelBuffer → AVAssetWriter
```

---

## 파라미터 레지스트리

> **전체 파라미터 목록 → [05_SHADER_PARAMS.md](05_SHADER_PARAMS.md)**  
> GitHub paper-design/shaders 소스 코드에서 직접 추출한 완전한 목록.  
> iOS 파라미터 패널 UI 구현 시 반드시 이 파일을 기준으로 한다.

### ShaderParam Swift 열거형 — 전체 타입

```swift
enum ShaderParam {
    case float(value: Float, min: Float, max: Float)
    case color(value: SIMD4<Float>)
    case colors(values: [SIMD4<Float>], maxCount: Int)  // maxCount: 쉐이더마다 다름
    case bool(value: Bool)
    case enumInt(value: Int, options: [String])         // enum 파라미터
}
```

### 공통 파라미터 (ShaderSizingParams — 모든 쉐이더에 포함)

| 파라미터 | Swift 타입 | 범위 |
|----------|-----------|------|
| fit | enumInt | none(0) / contain(1) / cover(2) |
| scale | float | 0.01 ~ 4 |
| rotation | float | 0 ~ 360 |
| originX | float | 0 ~ 1 |
| originY | float | 0 ~ 1 |
| offsetX | float | -1 ~ 1 |
| offsetY | float | -1 ~ 1 |
