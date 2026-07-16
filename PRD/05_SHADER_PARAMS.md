# 쉐이더 파라미터 전체 레퍼런스

> 출처: github.com/paper-design/shaders — 각 `.ts` 소스 파일 직접 추출  
> iOS 구현 시 이 목록 기준으로 파라미터 패널 UI를 빠짐없이 구성한다.

---

## 공통 파라미터 (모든 쉐이더에 포함)

출처: `ShaderSizingParams`

| 파라미터 | 타입 | 범위 / 옵션 | iOS UI |
|----------|------|-------------|--------|
| `fit` | enum | `none` / `contain` / `cover` | Picker |
| `scale` | float | 0.01 ~ 4 | Slider |
| `rotation` | float | 0 ~ 360 | Slider |
| `originX` | float | 0 ~ 1 | Slider |
| `originY` | float | 0 ~ 1 | Slider |
| `offsetX` | float | -1 ~ 1 | Slider |
| `offsetY` | float | -1 ~ 1 | Slider |

---

## Image Filters (원본 사진 픽셀 변환형)

> 이 그룹은 `image` 파라미터로 원본 사진을 입력받아 변환한다.  
> iOS 구현: `sourcePhoto`를 `image` 파라미터로 자동 연결 (UI에 노출 불필요)

---

### Paper Texture

| 파라미터 | 타입 | 범위 | iOS UI |
|----------|------|------|--------|
| `colorFront` | color | — | ColorPicker |
| `colorBack` | color | — | ColorPicker |
| `contrast` | float | 0 ~ 1 | Slider |
| `roughness` | float | 0 ~ 1 | Slider |
| `fiber` | float | 0 ~ 1 | Slider |
| `fiberSize` | float | 0 ~ 1 | Slider |
| `crumples` | float | 0 ~ 1 | Slider |
| `foldCount` | float | 1 ~ 15 | Slider |
| `folds` | float | 0 ~ 1 | Slider |
| `fade` | float | 0 ~ 1 | Slider |
| `crumpleSize` | float | 0 ~ 1 | Slider |
| `drops` | float | 0 ~ 1 | Slider |
| `seed` | float | — | Slider |
| + 공통 파라미터 | | | |

---

### Fluted Glass

| 파라미터 | 타입 | 범위 / 옵션 | iOS UI |
|----------|------|-------------|--------|
| `colorBack` | color | — | ColorPicker |
| `colorShadow` | color | — | ColorPicker |
| `colorHighlight` | color | — | ColorPicker |
| `shadows` | float | 0 ~ 1 | Slider |
| `highlights` | float | 0 ~ 1 | Slider |
| `size` | float | — | Slider |
| `angle` | float | 0 ~ 360 | Slider |
| `distortion` | float | 0 ~ 1 | Slider |
| `shift` | float | — | Slider |
| `blur` | float | 0 ~ 1 | Slider |
| `edges` | float | 0 ~ 1 | Slider |
| `margin` | float | — | Slider |
| `marginLeft` | float | — | Slider |
| `marginRight` | float | — | Slider |
| `marginTop` | float | — | Slider |
| `marginBottom` | float | — | Slider |
| `stretch` | float | — | Slider |
| `distortionShape` | enum | (GlassDistortionShape 옵션) | Picker |
| `shape` | enum | (GlassGridShape 옵션) | Picker |
| `grainMixer` | float | 0 ~ 1 | Slider |
| `grainOverlay` | float | 0 ~ 1 | Slider |
| + 공통 파라미터 | | | |

---

### Water

| 파라미터 | 타입 | 범위 | iOS UI |
|----------|------|------|--------|
| `colorBack` | color | — | ColorPicker |
| `colorHighlight` | color | — | ColorPicker |
| `highlights` | float | 0 ~ 1 | Slider |
| `layering` | float | 0 ~ 1 | Slider |
| `edges` | float | 0 ~ 1 | Slider |
| `caustic` | float | 0 ~ 1 | Slider |
| `waves` | float | 0 ~ 1 | Slider |
| `size` | float | 0.01 ~ 7 | Slider |
| + 공통 파라미터 | | | |

---

### Image Dithering

| 파라미터 | 타입 | 범위 / 옵션 | iOS UI |
|----------|------|-------------|--------|
| `colorFront` | color | — | ColorPicker |
| `colorBack` | color | — | ColorPicker |
| `colorHighlight` | color | — | ColorPicker |
| `type` | enum | `random` / `2x2` / `4x4` / `8x8` | Picker |
| `size` | float | — | Slider |
| `colorSteps` | float | — | Slider |
| `originalColors` | bool | — | Toggle |
| `inverted` | bool | — | Toggle |
| + 공통 파라미터 | | | |

---

### Halftone Dots

| 파라미터 | 타입 | 범위 / 옵션 | iOS UI |
|----------|------|-------------|--------|
| `colorFront` | color | — | ColorPicker |
| `colorBack` | color | — | ColorPicker |
| `type` | enum | `classic` / `gooey` / `holes` / `soft` | Picker |
| `grid` | enum | `square` / `hex` | Picker |
| `size` | float | 0 ~ 1 | Slider |
| `radius` | float | 0 ~ 2 | Slider |
| `contrast` | float | 0 ~ 1 | Slider |
| `originalColors` | bool | — | Toggle |
| `inverted` | bool | — | Toggle |
| `grainMixer` | float | 0 ~ 1 | Slider |
| `grainOverlay` | float | 0 ~ 1 | Slider |
| `grainSize` | float | 0 ~ 1 | Slider |
| + 공통 파라미터 | | | |

---

### Halftone CMYK

| 파라미터 | 타입 | 범위 / 옵션 | iOS UI |
|----------|------|-------------|--------|
| `colorBack` | color | — | ColorPicker |
| `colorC` | color | — | ColorPicker |
| `colorM` | color | — | ColorPicker |
| `colorY` | color | — | ColorPicker |
| `colorK` | color | — | ColorPicker |
| `type` | enum | (HalftoneCmykType 옵션) | Picker |
| `size` | float | — | Slider |
| `contrast` | float | 0 ~ 1 | Slider |
| `softness` | float | 0 ~ 1 | Slider |
| `grainSize` | float | 0 ~ 1 | Slider |
| `grainMixer` | float | 0 ~ 1 | Slider |
| `grainOverlay` | float | 0 ~ 1 | Slider |
| `gridNoise` | float | 0 ~ 1 | Slider |
| `floodC` | float | 0 ~ 1 | Slider |
| `floodM` | float | 0 ~ 1 | Slider |
| `floodY` | float | 0 ~ 1 | Slider |
| `floodK` | float | 0 ~ 1 | Slider |
| `gainC` | float | — | Slider |
| `gainM` | float | — | Slider |
| `gainY` | float | — | Slider |
| `gainK` | float | — | Slider |
| + 공통 파라미터 | | | |

---

## Effects (배경/오버레이형 애니메이션)

---

### Mesh Gradient

| 파라미터 | 타입 | 범위 | iOS UI |
|----------|------|------|--------|
| `colors` | color[] | 최대 10개 | ColorPicker 배열 |
| `distortion` | float | 0 ~ 1 | Slider |
| `swirl` | float | 0 ~ 1 | Slider |
| `grainMixer` | float | 0 ~ 1 | Slider |
| `grainOverlay` | float | 0 ~ 1 | Slider |
| + 공통 파라미터 | | | |

---

### Static Mesh Gradient

| 파라미터 | 타입 | 범위 | iOS UI |
|----------|------|------|--------|
| `colors` | color[] | 최대 10개 | ColorPicker 배열 |
| `positions` | float | — | Slider |
| `waveX` | float | — | Slider |
| `waveXShift` | float | — | Slider |
| `waveY` | float | — | Slider |
| `waveYShift` | float | — | Slider |
| `mixing` | float | — | Slider |
| `grainMixer` | float | 0 ~ 1 | Slider |
| `grainOverlay` | float | 0 ~ 1 | Slider |
| + 공통 파라미터 | | | |

---

### Static Radial Gradient

| 파라미터 | 타입 | 범위 | iOS UI |
|----------|------|------|--------|
| `colorBack` | color | — | ColorPicker |
| `colors` | color[] | 최대 10개 | ColorPicker 배열 |
| `radius` | float | — | Slider |
| `focalDistance` | float | — | Slider |
| `focalAngle` | float | — | Slider |
| `falloff` | float | — | Slider |
| `mixing` | float | — | Slider |
| `distortion` | float | — | Slider |
| `distortionShift` | float | — | Slider |
| `distortionFreq` | float | — | Slider |
| `grainMixer` | float | 0 ~ 1 | Slider |
| `grainOverlay` | float | 0 ~ 1 | Slider |
| + 공통 파라미터 | | | |

---

### Dithering

| 파라미터 | 타입 | 범위 / 옵션 | iOS UI |
|----------|------|-------------|--------|
| `colorBack` | color | — | ColorPicker |
| `colorFront` | color | — | ColorPicker |
| `shape` | enum | `simplex` / `warp` / `dots` / `wave` / `ripple` / `swirl` / `sphere` | Picker |
| `type` | enum | `random` / `2x2` / `4x4` / `8x8` | Picker |
| `size` | float | — | Slider |
| + 공통 파라미터 | | | |

---

### Grain Gradient

| 파라미터 | 타입 | 범위 / 옵션 | iOS UI |
|----------|------|-------------|--------|
| `colorBack` | color | — | ColorPicker |
| `colors` | color[] | — | ColorPicker 배열 |
| `shape` | enum | `wave` / `dots` / `truchet` / `corners` / `ripple` / `blob` / `sphere` | Picker |
| `softness` | float | 0 ~ 1 | Slider |
| `intensity` | float | 0 ~ 1 | Slider |
| `noise` | float | 0 ~ 1 | Slider |
| + 공통 파라미터 | | | |

---

### Dot Orbit

| 파라미터 | 타입 | 범위 | iOS UI |
|----------|------|------|--------|
| `colorBack` | color | — | ColorPicker |
| `colors` | color[] | 최대 10개 | ColorPicker 배열 |
| `size` | float | — | Slider |
| `sizeRange` | float | — | Slider |
| `spreading` | float | — | Slider |
| `stepsPerColor` | float | — | Slider |
| + 공통 파라미터 | | | |

---

### Dot Grid

| 파라미터 | 타입 | 범위 / 옵션 | iOS UI |
|----------|------|-------------|--------|
| `colorBack` | color | — | ColorPicker |
| `colorFill` | color | — | ColorPicker |
| `colorStroke` | color | — | ColorPicker |
| `shape` | enum | `circle` / `diamond` / `square` / `triangle` | Picker |
| `size` | float | — | Slider |
| `gapX` | float | — | Slider |
| `gapY` | float | — | Slider |
| `strokeWidth` | float | — | Slider |
| `sizeRange` | float | 0 ~ 1 | Slider |
| `opacityRange` | float | 0 ~ 1 | Slider |
| + 공통 파라미터 | | | |

---

### Warp

| 파라미터 | 타입 | 범위 / 옵션 | iOS UI |
|----------|------|-------------|--------|
| `colors` | color[] | 최대 10개 | ColorPicker 배열 |
| `shape` | enum | `checks` / `stripes` / `edge` | Picker |
| `proportion` | float | 0 ~ 1 | Slider |
| `softness` | float | 0 ~ 1 | Slider |
| `shapeScale` | float | 0 ~ 1 | Slider |
| `distortion` | float | 0 ~ 1 | Slider |
| `swirl` | float | 0 ~ 1 | Slider |
| `swirlIterations` | float | 0 ~ 20 | Slider |
| + 공통 파라미터 | | | |

---

### Spiral

| 파라미터 | 타입 | 범위 | iOS UI |
|----------|------|------|--------|
| `colorBack` | color | — | ColorPicker |
| `colorFront` | color | — | ColorPicker |
| `density` | float | — | Slider |
| `distortion` | float | — | Slider |
| `strokeWidth` | float | — | Slider |
| `strokeTaper` | float | — | Slider |
| `strokeCap` | float | — | Slider |
| `noise` | float | — | Slider |
| `noiseFrequency` | float | — | Slider |
| `softness` | float | 0 ~ 1 | Slider |
| + 공통 파라미터 | | | |

---

### Swirl

| 파라미터 | 타입 | 범위 | iOS UI |
|----------|------|------|--------|
| `colorBack` | color | — | ColorPicker |
| `colors` | color[] | — | ColorPicker 배열 |
| `bandCount` | float | 0 ~ 15 | Slider |
| `twist` | float | 0 ~ 1 | Slider |
| `center` | float | 0 ~ 1 | Slider |
| `proportion` | float | 0 ~ 1 | Slider |
| `softness` | float | 0 ~ 1 | Slider |
| `noiseFrequency` | float | 0 ~ 1 | Slider |
| `noise` | float | 0 ~ 1 | Slider |
| + 공통 파라미터 | | | |

---

### Waves

| 파라미터 | 타입 | 범위 | iOS UI |
|----------|------|------|--------|
| `colorFront` | color | — | ColorPicker |
| `colorBack` | color | — | ColorPicker |
| `shape` | float | 0 ~ 3 | Slider (zigzag/sine/waves 모핑) |
| `frequency` | float | 0 ~ 2 | Slider |
| `amplitude` | float | 0 ~ 1 | Slider |
| `spacing` | float | 0 ~ 2 | Slider |
| `proportion` | float | 0 ~ 1 | Slider |
| `softness` | float | 0 ~ 1 | Slider |
| + 공통 파라미터 | | | |

---

### Neuro Noise

| 파라미터 | 타입 | 범위 | iOS UI |
|----------|------|------|--------|
| `colorFront` | color | — | ColorPicker |
| `colorMid` | color | — | ColorPicker |
| `colorBack` | color | — | ColorPicker |
| `brightness` | float | — | Slider |
| `contrast` | float | — | Slider |
| + 공통 파라미터 | | | |

---

### Perlin Noise

| 파라미터 | 타입 | 범위 | iOS UI |
|----------|------|------|--------|
| `colorFront` | color | — | ColorPicker |
| `colorBack` | color | — | ColorPicker |
| `proportion` | float | 0 ~ 1 | Slider |
| `softness` | float | 0 ~ 1 | Slider |
| `octaveCount` | float | 1 ~ 8 | Slider |
| `persistence` | float | 0.3 ~ 1 | Slider |
| `lacunarity` | float | 1.5 ~ 10 | Slider |
| + 공통 파라미터 | | | |

---

### Simplex Noise

| 파라미터 | 타입 | 범위 | iOS UI |
|----------|------|------|--------|
| `colors` | color[] | 최대 10개 | ColorPicker 배열 |
| `stepsPerColor` | float | — | Slider |
| `softness` | float | 0 ~ 1 | Slider |
| + 공통 파라미터 | | | |

---

### Voronoi

| 파라미터 | 타입 | 범위 | iOS UI |
|----------|------|------|--------|
| `colors` | color[] | 최대 5개 | ColorPicker 배열 |
| `colorGap` | color | — | ColorPicker |
| `colorGlow` | color | — | ColorPicker |
| `stepsPerColor` | float | — | Slider |
| `distortion` | float | — | Slider |
| `gap` | float | — | Slider |
| `glow` | float | — | Slider |
| + 공통 파라미터 | | | |

---

### Pulsing Border

| 파라미터 | 타입 | 범위 / 옵션 | iOS UI |
|----------|------|-------------|--------|
| `colorBack` | color | — | ColorPicker |
| `colors` | color[] | — | ColorPicker 배열 |
| `aspectRatio` | enum | `auto` / `square` | Picker |
| `roundness` | float | — | Slider |
| `thickness` | float | — | Slider |
| `margin` | float | — | Slider |
| `marginLeft` | float | — | Slider |
| `marginRight` | float | — | Slider |
| `marginTop` | float | — | Slider |
| `marginBottom` | float | — | Slider |
| `softness` | float | 0 ~ 1 | Slider |
| `intensity` | float | 0 ~ 1 | Slider |
| `bloom` | float | 0 ~ 1 | Slider |
| `spots` | float | — | Slider |
| `spotSize` | float | — | Slider |
| `pulse` | float | — | Slider |
| `smoke` | float | — | Slider |
| `smokeSize` | float | — | Slider |
| + 공통 파라미터 | | | |

---

### Metaballs

| 파라미터 | 타입 | 범위 | iOS UI |
|----------|------|------|--------|
| `colorBack` | color | — | ColorPicker |
| `colors` | color[] | 최대 8개 | ColorPicker 배열 |
| `count` | float | 1 ~ 20 | Slider |
| `size` | float | — | Slider |
| + 공통 파라미터 | | | |

---

### Color Panels

| 파라미터 | 타입 | 범위 | iOS UI |
|----------|------|------|--------|
| `colorBack` | color | — | ColorPicker |
| `colors` | color[] | 최대 7개 | ColorPicker 배열 |
| `angle1` | float | — | Slider |
| `angle2` | float | — | Slider |
| `length` | float | — | Slider |
| `edges` | bool | — | Toggle |
| `blur` | float | 0 ~ 0.5 | Slider |
| `fadeIn` | float | — | Slider |
| `fadeOut` | float | — | Slider |
| `density` | float | 0.25 ~ 7 | Slider |
| `gradient` | float | — | Slider |
| + 공통 파라미터 | | | |

---

### Smoke Ring

| 파라미터 | 타입 | 범위 | iOS UI |
|----------|------|------|--------|
| `colorBack` | color | — | ColorPicker |
| `colors` | color[] | 최대 10개 | ColorPicker 배열 |
| `noiseScale` | float | — | Slider |
| `thickness` | float | — | Slider |
| `radius` | float | — | Slider |
| `innerShape` | float | — | Slider |
| `noiseIterations` | float | 1 ~ 8 | Slider |
| + 공통 파라미터 | | | |

---

### God Rays

| 파라미터 | 타입 | 범위 | iOS UI |
|----------|------|------|--------|
| `colorBack` | color | — | ColorPicker |
| `colorBloom` | color | — | ColorPicker |
| `colors` | color[] | — | ColorPicker 배열 |
| `spotty` | float | — | Slider |
| `midSize` | float | — | Slider |
| `midIntensity` | float | — | Slider |
| `density` | float | — | Slider |
| `intensity` | float | — | Slider |
| `bloom` | float | — | Slider |
| + 공통 파라미터 | | | |

---

## Logo Animations

> 이 그룹은 `image` 파라미터로 PNG/SVG 로고를 마스크로 사용한다.  
> iOS 구현: PNG 오버레이 레이어의 이미지를 `image` 파라미터로 자동 연결 가능

---

### Heatmap

| 파라미터 | 타입 | 범위 | iOS UI |
|----------|------|------|--------|
| `colorBack` | color | — | ColorPicker |
| `colors` | color[] | 최대 10개 | ColorPicker 배열 |
| `contour` | float | — | Slider |
| `angle` | float | — | Slider |
| `noise` | float | — | Slider |
| `innerGlow` | float | — | Slider |
| `outerGlow` | float | — | Slider |
| + 공통 파라미터 | | | |

---

### Liquid Metal

| 파라미터 | 타입 | 범위 / 옵션 | iOS UI |
|----------|------|-------------|--------|
| `colorBack` | color | — | ColorPicker |
| `colorTint` | color | — | ColorPicker |
| `shape` | enum | `none` / `circle` / `daisy` / `diamond` / `metaballs` | Picker |
| `repetition` | float | — | Slider |
| `shiftRed` | float | — | Slider |
| `shiftBlue` | float | — | Slider |
| `contour` | float | — | Slider |
| `softness` | float | 0 ~ 1 | Slider |
| `distortion` | float | — | Slider |
| `angle` | float | 0 ~ 360 | Slider |
| + 공통 파라미터 | | | |

---

### Gem Smoke

| 파라미터 | 타입 | 범위 / 옵션 | iOS UI |
|----------|------|-------------|--------|
| `colorBack` | color | — | ColorPicker |
| `colorInner` | color | — | ColorPicker |
| `colors` | color[] | 최대 6개 | ColorPicker 배열 |
| `shape` | enum | `none` / `circle` / `daisy` / `diamond` / `metaballs` | Picker |
| `innerDistortion` | float | 0 ~ 1 | Slider |
| `outerDistortion` | float | 0 ~ 1 | Slider |
| `outerGlow` | float | 0 ~ 1 | Slider |
| `innerGlow` | float | 0 ~ 1 | Slider |
| `offset` | float | -1 ~ 1 | Slider |
| `angle` | float | 0 ~ 360 | Slider |
| `size` | float | 0 ~ 1 | Slider |
| + 공통 파라미터 | | | |

---

## iOS 파라미터 패널 구현 노트

### 파라미터 타입별 UI 컴포넌트

| 타입 | SwiftUI 컴포넌트 | 비고 |
|------|-----------------|------|
| `float` (범위 명확) | `Slider(value:in:)` + 값 Label | 범위 표의 값 사용 |
| `float` (범위 `—`) | `Slider(value:in: 0...1)` | 기본 범위 적용 |
| `color` | `ColorPicker` | RGBA → `SIMD4<Float>` 변환 |
| `color[]` | `HStack { ForEach { ColorPicker } }` + 추가/삭제 버튼 | maxColorCount 제한 |
| `bool` | `Toggle` | |
| `enum` | `Picker(.segmented)` (3개 이하) / `Picker(.menu)` (4개 이상) | |

### 파라미터 그룹핑 제안

각 쉐이더의 파라미터 패널은 두 섹션으로 구분:
1. **색상** — color / color[] 파라미터 
2. **조절** — float / bool / enum 파라미터
3. **레이아웃** — 공통 파라미터 (scale, rotation, offsetX/Y 등) — 접기/펼치기로 기본 숨김
