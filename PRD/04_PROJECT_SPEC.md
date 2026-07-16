# 프로젝트 스펙 — Paper Shader Effector

## Git / 버전 관리 원칙

| 항목 | 값 |
|------|-----|
| GitHub 저장소 | https://github.com/standardmanual/JAM-Eff |
| 기본 브랜치 | `main` |

### 커밋 & 푸시 규칙

- **Phase 완료 시:** 해당 Phase의 Done 체크리스트(03_PHASES.md) 항목이 모두 충족되면 즉시 커밋 & 푸시
- **기능 단위 변경 시:** 독립적으로 동작하는 기능 하나가 완성될 때마다 커밋 & 푸시  
  (예: 새 쉐이더 1종 추가, 파라미터 패널 UI 완성, 내보내기 기능 추가 등)
- **커밋 메시지 형식:**

```
[Phase N] 기능명 — 한 줄 요약

예시:
[Phase 1] Metal 렌더링 파이프라인 기본 구성
[Phase 1] Mesh Gradient MSL 쉐이더 구현
[Phase 2] 다중 레이어 스택 렌더 패스 추가
[Phase 3] AVAssetWriter 동영상 내보내기 완성
```

- **절대 하지 말 것:** 미완성 상태(빌드 에러, 크래시 재현 가능)로 커밋하지 않는다.
- **푸시 대상:** `origin main` (force push 금지)

---

## 기술 스택

| 항목 | 선택 | 이유 |
|------|------|------|
| 언어 | Swift 5.10+ | iOS 네이티브 표준 |
| UI 프레임워크 | SwiftUI | iOS 17 최적화, 코드량 적음 |
| GPU 렌더링 | Metal (MSL) | Apple 네이티브 GPU API, 최고 성능 |
| 렌더 뷰 | MTKView | Metal 렌더링 전용 뷰 |
| 사진 접근 | PhotosUI (PhotosPicker) | iOS 17 권장 방식 |
| 동영상 인코딩 | AVFoundation (AVAssetWriter) | Apple 네이티브 동영상 저장 |
| 최소 지원 | iOS 17.0 | Metal 4, SwiftUI 5 최신 기능 활용 |
| 외부 의존성 | 없음 | SPM 패키지 최소화 |

---

## 파일/폴더 구조

```
PaperShaderEffector/
├── App/
│   ├── PaperShaderEffectorApp.swift
│   └── ContentView.swift
├── Views/
│   ├── HomeView.swift              # 사진 선택 (PhotosPicker 전체화면)
│   ├── EditorView.swift            # 메인 편집 화면 (4-Zone 레이아웃)
│   ├── PreviewZoneView.swift       # Zone 2: MTKView 래퍼 + 비율 토글
│   ├── LayerTrayView.swift         # Zone 3: 레이어 칩 가로 스크롤 트레이
│   ├── ParamPanelView.swift        # Zone 4: 파라미터 패널 (섹션 그룹핑)
│   ├── AddShaderSheet.swift        # 쉐이더 추가 Bottom Sheet (3열 그리드)
│   ├── ParamRows/
│   │   ├── FloatParamRow.swift     # Slider + 값 표시 행 (높이 52pt)
│   │   ├── ColorParamRow.swift     # ColorPicker 행
│   │   ├── ColorsParamRow.swift    # ColorPicker 배열 행
│   │   ├── BoolParamRow.swift      # Toggle 행
│   │   └── EnumParamRow.swift      # Picker(segmented/menu) 행
│   └── Components/
│       ├── RatioToggle.swift       # 4:5/9:16 Pill 버튼
│       ├── LayerChip.swift         # 80×80pt 레이어 칩
│       └── ToastView.swift         # 저장 완료 토스트
├── Metal/
│   ├── Renderer.swift              # MTKView delegate, 렌더 루프
│   ├── ShaderPipeline.swift        # MTLRenderPipelineState 관리
│   ├── Shaders/                    # .metal 파일들
│   │   ├── MeshGradient.metal
│   │   ├── Waves.metal
│   │   └── ... (효과별 1파일)
│   └── TextureUtils.swift          # UIImage ↔ MTLTexture 변환
├── Models/
│   ├── EditSession.swift
│   ├── ShaderLayer.swift
│   ├── ShaderEffect.swift          # 전체 효과 열거형 + 기본 파라미터
│   └── ExportSpec.swift
├── Export/
│   ├── ImageExporter.swift         # MTLTexture → Photos
│   └── VideoExporter.swift         # AVAssetWriter 파이프라인
└── Info.plist                      # NSPhotoLibraryUsageDescription 필수
```

---

## AI 행동 규칙 (Claude Code 사용 시)

### 반드시 할 것

- **쉐이더 포팅 기준:** paper-design/shaders GitHub의 GLSL 코드를 MSL로 직역 변환. 파라미터 이름과 범위를 원본과 동일하게 유지한다.
- **렌더링 단위:** 각 ShaderLayer는 독립적인 `MTLRenderCommandEncoder`로 처리하고, 이전 레이어의 출력 텍스처를 다음 레이어의 입력으로 넘긴다.
- **시간 uniform:** 모든 애니메이션 쉐이더는 `float time` uniform을 받고, `CADisplayLink`로 누적 시간을 업데이트한다.
- **해상도:** 항상 출력 해상도(1080px 기준)로 렌더링. 프리뷰는 스케일 다운된 동일 파이프라인 사용.
- **Photo 권한:** `NSPhotoLibraryUsageDescription`과 `NSPhotoLibraryAddUsageDescription` 둘 다 Info.plist에 추가.

### 절대 하지 말 것

- WKWebView나 JavaScript 브릿지로 paper-design 웹 버전을 래핑하지 않는다. (동영상 저장 불가)
- UIKit 기반 렌더 루프를 만들지 않는다. MTKView의 `draw()` 메서드만 사용.
- 전체 쉐이더를 단일 .metal 파일에 몰아넣지 않는다. 효과별로 파일 분리.
- AVCaptureSession을 사용하지 않는다. (카메라 촬영 앱이 아님)
- 서버, 클라우드, 외부 API와 통신하지 않는다.
- 불필요한 외부 SPM 패키지를 추가하지 않는다.
- 다크 모드 스타일을 구현하지 않는다. 모든 뷰에 `.preferredColorScheme(.light)` 적용.
- 가로 모드 레이아웃을 구현하지 않는다. `Info.plist`에서 Portrait만 허용.
- 텍스트를 13pt 미만으로 설정하지 않는다.
- 터치 타깃을 44×44pt 미만으로 만들지 않는다.

---

## GLSL → MSL 변환 규칙

| GLSL | MSL |
|------|-----|
| `vec2` | `float2` |
| `vec3` | `float3` |
| `vec4` | `float4` |
| `mat2/3/4` | `float2x2/3x3/4x4` |
| `fract()` | `fract()` (동일) |
| `mix()` | `mix()` (동일) |
| `texture2D(sampler, uv)` | `texture.sample(sampler, uv)` |
| `gl_FragCoord` | `in.position` |
| `varying vec2 vUv` | `in.texCoord` (vertex → fragment) |
| `uniform float time` | `constant float& time [[buffer(0)]]` |

---

## UI 구현 규칙

### Liquid Glass 소재 적용
```swift
// 네비게이션 바, 레이어 트레이, 파라미터 패널: 시스템 소재 사용
.background(.regularMaterial)   // Liquid Glass 효과
// 비율 토글 Pill, 추가 버튼 등
.background(.thinMaterial)
```

### 방향 잠금 (Info.plist)
```xml
<key>UISupportedInterfaceOrientations</key>
<array>
    <string>UIInterfaceOrientationPortrait</string>
</array>
```

### 라이트 모드 고정
```swift
// App 진입점 또는 ContentView 루트
.preferredColorScheme(.light)
```

### 편집 화면 Zone 높이 상수
```swift
enum EditorLayout {
    static let navBarHeight: CGFloat = 44
    static let previewZoneHeight: CGFloat = 320
    static let layerTrayHeight: CGFloat = 96
    // Zone 4 (파라미터 패널): 나머지 전체 (스크롤)

    // iPhone 15 Pro 기준 (852pt 논리 해상도)
    // 사용 가능: 852 - 59(DynamicIsland) - 34(HomeIndicator) = 759pt
    // Zone 1+2+3 합계: 44+320+96 = 460pt
    // Zone 4 가시 영역: 759 - 460 = 299pt (내부 스크롤로 더 표시)
}
```

### 레이어 칩 (LayerChip)
```swift
// 크기: 80×80pt
// 선택 상태: overlay border Color.blue, lineWidth: 2
// 비활성: opacity 0.4
// 이름 폰트: .caption (11pt), lineLimit: 1, truncationMode: .tail
```

### 파라미터 패널 UI 규칙
```swift
// 섹션 헤더: .headline (17pt), 좌측 정렬
// 섹션 3개: "색상" / "조절" / "레이아웃 (접기 기본)"

// float 파라미터 행 (FloatParamRow): 높이 52pt
HStack {
    Text(name)                  // 16pt, width: 100pt, leading
    Slider(value: $v, in: min...max)  // 나머지 너비
    Text(String(format:"%.2f", v))   // 15pt monospaced, width: 44pt
}
.frame(height: 52)

// color 파라미터 행 (ColorParamRow): 높이 52pt
HStack {
    Text(name)                  // 16pt
    Spacer()
    ColorPicker("", selection: $color)
        .frame(width: 44, height: 44)  // 터치 타깃 보장
}

// colors[] 파라미터 행 (ColorsParamRow)
// 색상 스와치 32×32pt 원형 + 탭으로 ColorPicker
// 우측에 + / - 버튼 (최대 maxCount 제한)

// bool 파라미터 행: Toggle, 높이 44pt
// enum 파라미터 행: Picker(.segmented) 옵션 ≤3, Picker(.menu) 옵션 ≥4, 높이 44pt
```

---

## 동영상 인코딩 스펙

```
프레임 수: 600 (20초 × 30fps)
코덱: H.264 (AVVideoCodecType.h264)
비트레이트: 8 Mbps
픽셀 포맷: kCVPixelFormatType_32BGRA
time uniform: 0.0 → 20.0 (매 프레임 += 1/30)
진행률: 현재프레임 / 600
```

---

## 주요 권한 (Info.plist)

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>사진을 불러오고 결과물을 저장하기 위해 사용합니다.</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>편집한 이미지와 동영상을 카메라롤에 저장합니다.</string>
```

---

## Phase 1 시작 프롬프트 (Claude Code용)

```
Paper Shader Effector iOS 앱을 만들어줘.

기술 스택: SwiftUI + Metal, iOS 17+, 외부 패키지 없음
PRD 위치: PRD/ 폴더 참고 (01_PRD.md, 04_PROJECT_SPEC.md, 05_SHADER_PARAMS.md)

Phase 1 범위:
1. Xcode 프로젝트 생성 (PaperShaderEffector, iOS 17, Portrait only)
2. PhotosUI로 사진 선택 (HomeView)
3. EditorView: 4-Zone 레이아웃 구현
   - Zone 1: 네비게이션 바 (.regularMaterial)
   - Zone 2: PreviewZoneView — MTKView 320pt + 비율 토글 Pill
   - Zone 3: LayerTrayView — 레이어 칩 80×80pt 가로 스크롤 트레이
   - Zone 4: ParamPanelView — 섹션 그룹핑 파라미터 패널 (스크롤)
4. Metal 렌더링 파이프라인 (ShaderPipeline.swift, Renderer.swift)
5. Mesh Gradient .metal 구현 (GLSL → MSL, 05_SHADER_PARAMS.md 파라미터 기준)
6. Waves .metal 구현
7. FloatParamRow (52pt), ColorParamRow (44pt), EnumParamRow 구현
8. 4:5 / 9:16 비율 전환 (RatioToggle)
9. 이미지 카메라롤 저장 + 토스트 피드백

UI 필수 규칙:
- .preferredColorScheme(.light) 루트 적용 (다크 모드 없음)
- Portrait 전용 (Info.plist UISupportedInterfaceOrientations)
- 텍스트 최소 13pt, 터치 타깃 최소 44×44pt
- Liquid Glass: .background(.regularMaterial) / .thinMaterial 활용
- iPhone 15 Pro (393×852pt) 기준 레이아웃

Git 규칙:
- 저장소: https://github.com/standardmanual/JAM-Eff
- 기능 하나 완성될 때마다 커밋 & 푸시 (빌드 성공 상태만)
- 커밋 메시지 형식: "[Phase 1] 기능명 — 한 줄 요약"

04_PROJECT_SPEC.md의 모든 행동 규칙을 반드시 준수할 것.
```
