# PRD — Paper Shader Effector (iOS)

## 1. 제품 개요

**제품명:** Paper Shader Effector  
**플랫폼:** iOS 17+  
**대상 사용자:** 개인 사용 (단독 설치, 앱스토어 미출시)  
**핵심 가치:** paper-design/shaders의 20가지 GPU 쉐이더 효과를 네이티브 Metal로 구현해 내 사진에 실시간 적용하고, 여러 효과를 레이어로 합성해 4:5 / 9:16 비율 이미지 또는 20초 동영상으로 저장한다.

---

## 2. 문제 정의

- 기존 앱(VSCO, Instagram 필터 등)은 고정 필터만 제공하며, 쉐이더 파라미터를 직접 조절할 수 없다.
- paper-design/shaders는 웹 전용(JavaScript)으로 모바일 네이티브 저장이 불가능하다.
- 여러 쉐이더 효과를 레이어처럼 순서대로 합성하는 도구가 없다.

---

## 3. 핵심 기능 (전체 범위)

| 기능 | 설명 | Phase |
|------|------|-------|
| 사진 불러오기 | PhotosUI로 카메라롤에서 선택 | 1 |
| Metal 렌더링 파이프라인 | MTKView 기반 실시간 쉐이더 렌더링 | 1 |
| 쉐이더 효과 선택 (8종 우선) | 효과 목록 UI + 실시간 프리뷰 | 1 |
| 파라미터 조절 UI | paper-design 샘플 페이지와 동일한 슬라이더/컬러피커 | 1 |
| 4:5 / 9:16 비율 프리뷰 | 출력 비율 선택 및 크롭 미리보기 | 1 |
| 이미지 저장 (JPG/PNG) | Metal 텍스처 → 카메라롤 저장 | 1 |
| 전체 쉐이더 20종 | Image Filters + Effects + Logo Animations 전체 | 2 |
| 다중 쉐이더 합성 | 여러 효과를 순서대로 쌓는 레이어 스택 | 2 |
| PNG 오버레이 레이어 | 카메라롤에서 투명 PNG 불러와 합성 | 2 |
| 20초 동영상 저장 (MP4) | AVFoundation으로 애니메이션 프레임 인코딩 | 3 |

---

## 4. 쉐이더 효과 목록 (paper-design/shaders 기준)

### Image Filters
- Paper Texture, Fluted Glass, Water, Image Dithering, Halftone Dots, Halftone CMYK

### Effects (애니메이션)
- Mesh Gradient, Static Mesh Gradient, Static Radial Gradient, Dithering, Grain Gradient
- Dot Orbit, Dot Grid, Warp, Spiral, Swirl, Waves, Neuro Noise, Perlin Noise, Simplex Noise
- Voronoi, Pulsing Border, Metaballs, Color Panels, Smoke Ring, God Rays

### Logo Animations
- Heatmap, Liquid Metal, Gem Smoke

**구현 방식:** paper-design/shaders GitHub 소스의 GLSL 쉐이더 코드를 Metal Shading Language(MSL)로 포팅. 각 효과의 파라미터(colors, speed, distortion, scale 등)는 원본 샘플 페이지의 설정 방식을 그대로 유지한다.

**Phase 1 우선 8종 (토큰 효율 + 안정성 기준):**
1. Mesh Gradient (colors, distortion, swirl, speed)
2. Waves (amplitude, frequency, speed, color)
3. Perlin Noise (scale, speed, color)
4. Grain Gradient (grain, colors)
5. Halftone Dots (scale, color)
6. Paper Texture (intensity, color)
7. Pulsing Border (width, speed, color)
8. Dot Orbit (colors, scale)

---

## 5. 파라미터 UI 설계 원칙

paper-design 샘플 페이지(shaders.paper.design)의 설정 패널을 그대로 iOS UI로 구현:

| 파라미터 타입 | iOS 컴포넌트 |
|-------------|-------------|
| 숫자 범위 (0.0~1.0, 0~100 등) | Slider + 값 표시 Label |
| 색상 | ColorPicker (SwiftUI 네이티브) |
| 불리언 토글 | Toggle |
| 선택지 | Picker / SegmentedControl |

---

## 6. 출력 스펙

| 항목 | 스펙 |
|------|------|
| 이미지 비율 | 4:5 (1080×1350px) 또는 9:16 (1080×1920px) |
| 이미지 형식 | JPG (품질 95%) 또는 PNG |
| 동영상 길이 | 20초 고정 |
| 동영상 형식 | MP4 (H.264, 30fps) |
| 동영상 해상도 | 비율에 따라 1080×1350 또는 1080×1920 |
| 저장 위치 | 카메라롤 (Photos 라이브러리) |

---

## 7. UI/UX 요건

### 디자인 시스템

| 항목 | 스펙 |
|------|------|
| 디자인 언어 | iOS 26 Liquid Glass (반투명 유리 소재 레이어) |
| 색상 모드 | **라이트 모드 전용** (다크 모드 미지원) |
| 방향 | **세로 모드 전용** (가로 모드 미지원) |
| 최적화 타깃 | iPhone 15 Pro (393×852pt, @3x = 1290×2796px) |
| 기본 폰트 | SF Pro (Dynamic Type — 최소 body 크기 이상 유지) |
| 텍스트 최소 크기 | 라벨 16pt / 값 표시 15pt / 캡션 13pt |
| 터치 타깃 최소 크기 | 44×44pt |

### 화면 구성 — 전체 플로우

```
[홈 화면]
  └─ PhotosPicker → 사진 선택
       └─ [편집 화면 (EditorView)]
             └─ 저장 버튼 → [저장 액션 시트]
                             ├─ 이미지로 저장
                             └─ 동영상으로 저장 → [진행률 모달]
```

### 편집 화면 레이아웃 — iPhone 15 Pro 기준

세로 방향 고정. 4개 존(Zone)이 화면을 수직 분할:

```
┌─────────────────────────────────┐
│  Dynamic Island 영역 (59pt)     │
├─────────────────────────────────┤  ← Zone 1: 네비게이션 바
│  [← 뒤로]  Paper Shader  [저장↑]│  44pt | Liquid Glass 소재
├─────────────────────────────────┤
│                                 │
│         [미리보기 영역]          │  ← Zone 2: 프리뷰 (320pt 고정)
│      (MTKView 실시간 렌더)       │  선택 비율로 렌더링
│      ┌──────────────┐           │  여백은 검정 배경
│      │  4:5 or 9:16 │           │
│      └──────────────┘           │
│             [4:5  9:16] ←비율토글│  우하단 코너 Pill 버튼
├─────────────────────────────────┤
│                                 │  ← Zone 3: 레이어 스택 (96pt)
│  [레이어1] [레이어2] [+추가]  →  │  가로 스크롤 | Liquid Glass 트레이
│   (쉐이더명 + 미니썸네일)         │  레이어 칩 80×80pt
│                                 │
├─────────────────────────────────┤
│                                 │  ← Zone 4: 파라미터 패널
│  ▼ 색상                         │  나머지 공간 ~332pt
│  [colorFront ●] [colorBack ●]   │  세로 스크롤 가능
│                                 │  Liquid Glass 시트 소재
│  ▼ 조절                         │
│  frequency  ────●──────  0.80   │
│  amplitude  ──●────────  0.30   │
│  spacing    ────────●──  1.60   │
│                                 │
│  ▼ 레이아웃 (접기 기본)          │
│   scale / rotation / offset…   │
│                                 │
└─────────────────────────────────┘
   홈 인디케이터 영역 (34pt)
```

**총 높이 계산:** 59 + 44 + 320 + 96 + 332 + 34 = **885pt** (852pt 화면에서 Zone 4가 스크롤로 처리)

### Zone별 UI 상세

#### Zone 1: 네비게이션 바
- Liquid Glass 소재 배경 (반투명 흰색, blur 효과)
- 좌: 뒤로가기 버튼 (SF Symbol `chevron.left`, 18pt)
- 중앙: 타이틀 "편집" (17pt semibold)
- 우: 저장 버튼 (SF Symbol `square.and.arrow.up`, 18pt, 강조 색상)

#### Zone 2: 미리보기 영역
- **배경:** 순수 검정 (#000000) — 비율 외 영역
- **프리뷰 박스:** 선택된 비율(4:5 / 9:16)로 중앙 배치, 최대 너비 393pt
  - 4:5 선택 시: 너비 314pt × 높이 393pt → 320pt 존 안에서 상하 중앙 정렬 (위 너비 기준 계산)
  - 9:16 선택 시: 너비 180pt × 높이 320pt → 좌우 중앙 정렬
- **비율 토글:** 우하단 Pill 버튼, 높이 32pt, Liquid Glass 소재  
  `[  4:5  |  9:16  ]` — 선택된 쪽 강조

#### Zone 3: 레이어 스택 트레이
- Liquid Glass 트레이 (frosted glass, 상단 구분선 있음)
- 가로 스크롤 (`ScrollView(.horizontal)`)
- 레이어 칩 크기: **80×80pt**
  - 상단 4/5: 미니 썸네일 (쉐이더 효과 프리뷰)
  - 하단 1/5: 쉐이더 이름 (11pt, 1줄)
  - 우상단 코너: 활성화 토글 (작은 체크 아이콘)
  - 선택된 칩: 파란색 테두리 2pt
- `+` 버튼: 동일 80×80pt 크기, 점선 테두리
- 길게 누르기: 드래그로 순서 변경 (haptic feedback)
- 좌로 스와이프: 삭제 버튼 노출

#### Zone 4: 파라미터 패널
- Liquid Glass 시트 소재 (흰색 반투명, 둥근 상단 모서리 20pt)
- 섹션 3개로 그룹핑:

**색상 섹션 (`▼ 색상`)**
- `color` 파라미터: HStack — 이름(16pt) + 컬러 스와치(32×32pt 원형) + `ColorPicker` 연결
- `colors[]` 파라미터: 색상 스와치 가로 나열 + `+` / `-` 버튼

**조절 섹션 (`▼ 조절`)**
- 각 `float` 파라미터 행 높이: **52pt**
  - 이름 라벨: 16pt, 좌측 정렬 (너비 100pt)
  - Slider: 나머지 너비, thumb 28pt
  - 값 표시: 15pt monospaced, 우측 정렬 (너비 44pt, 소수점 2자리)
- `bool` 파라미터: Toggle (44pt 높이)
- `enum` 파라미터: Picker segmented 스타일 (44pt 높이)

**레이아웃 섹션 (`▷ 레이아웃` — 기본 접힘)**  
- scale, rotation, originX/Y, offsetX/Y, fit
- 탭으로 펼치기/접기

---

## 8. 화면 전환 / 상호작용 규칙

| 동작 | 피드백 |
|------|--------|
| 레이어 탭 (선택) | Soft haptic (`.soft`) |
| 레이어 길게 누르기 (드래그 시작) | Medium haptic + 칩 살짝 확대 |
| 파라미터 슬라이더 드래그 | 실시간 프리뷰 즉각 반영 (지연 없음) |
| 저장 완료 | Success haptic + "카메라롤에 저장됨" 토스트 |
| 쉐이더 추가 (`+`) | Bottom sheet로 쉐이더 그리드 표시 |

### 쉐이더 추가 시트 (AddShaderSheet)
- Modal Bottom Sheet — detent: `.medium` (화면 절반)
- 쉐이더 그리드: 3열, 아이템 크기 (393-48)/3 = ~115pt
- 각 셀: 쉐이더 미리보기 썸네일 + 이름(13pt) + 카테고리 배지
- 검색 바 상단 배치 (16pt 이상 폰트)

---

## 9. 비기능 요건

- **실시간 프리뷰:** 파라미터 변경 시 즉각 반영 (Metal GPU, CADisplayLink 60fps)
- **메모리:** MTLTexture 메모리 효율 관리 — 프리뷰는 축소 해상도, 저장 시만 풀 해상도
- **동영상 생성:** 백그라운드 처리 + Modal ProgressView (진행률 % 표시)
- **방향 잠금:** `UIInterfaceOrientationMask.portrait` 고정
- **다크 모드 차단:** `preferredColorScheme(.light)` 루트 뷰에 적용

---

## 10. 미결 사항 [NEEDS CLARIFICATION]

- [ ] PNG 오버레이의 블렌드 모드 지원 범위 (일반/곱하기/스크린 등)
- [ ] 쉐이더 레이어 간 블렌드 방식 (합산/평균/마스크)
- [ ] 파라미터 프리셋 저장 기능 필요 여부
- [ ] 동영상 배경음악 추가 여부
