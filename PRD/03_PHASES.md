# Phase 분리 계획 — Paper Shader Effector

## Phase 1: 핵심 파이프라인 + 주요 쉐이더 8종 + 이미지 저장

**목표:** 이것만 완성해도 실제로 쓸 수 있는 앱  
**완료 기준:** 실제 기기에서 사진 불러오기 → 쉐이더 적용 → 카메라롤 저장까지 동작

### 포함 기능

- [ ] Xcode 프로젝트 세팅 (SwiftUI + Metal, iOS 17 타깃)
- [ ] PhotosUI로 카메라롤 사진 선택
- [ ] MTKView 기반 Metal 렌더링 파이프라인 구축
- [ ] 쉐이더 레이어 단일 렌더 패스 구현
- [ ] 8종 쉐이더 MSL 구현:
  - Mesh Gradient
  - Waves
  - Perlin Noise
  - Grain Gradient
  - Halftone Dots
  - Paper Texture
  - Pulsing Border
  - Dot Orbit
- [ ] 각 쉐이더 파라미터 패널 UI (Slider + ColorPicker)
- [ ] 4:5 / 9:16 비율 전환 및 크롭 프리뷰
- [ ] Metal 텍스처 → UIImage → 카메라롤 저장

### 기술 체크포인트

- GLSL(paper-design 원본) → MSL 변환 패턴 확립
- `time` uniform으로 애니메이션 구동 (CADisplayLink)
- 렌더링 해상도: 출력 해상도와 동일 (1080px 기준)

---

## Phase 2: 전체 20종 쉐이더 + 다중 레이어 합성 + PNG 오버레이

**전제 조건:** Phase 1 완성 + 기기에서 안정 동작 확인  
**목표:** 20종 전체 사용 가능, 여러 효과를 쌓아서 합성

### 포함 기능

- [ ] 나머지 쉐이더 12종+ MSL 구현:
  - Fluted Glass, Water, Image Dithering, Halftone CMYK
  - Static Mesh Gradient, Static Radial Gradient, Dithering
  - Dot Grid, Warp, Spiral, Swirl, Neuro Noise, Simplex Noise
  - Voronoi, Metaballs, Color Panels, Smoke Ring, God Rays
  - Heatmap, Liquid Metal, Gem Smoke
- [ ] 다중 쉐이더 레이어 스택 UI (추가/삭제/순서 변경)
- [ ] 레이어 간 순차 렌더링 (Render Pass Chain)
- [ ] 카메라롤에서 투명 PNG 불러오기
- [ ] PNG 오버레이 합성 (위치/크기/투명도 조절)

### 기술 체크포인트

- Multi-pass Metal rendering (MTLCommandBuffer 체이닝)
- Image Filter 쉐이더: 원본 사진 픽셀을 직접 변환 (Effect 쉐이더와 구분)
- PNG 알파채널 보존한 alpha blending

---

## Phase 3: 20초 동영상 저장

**전제 조건:** Phase 2 완성  
**목표:** 쉐이더 애니메이션을 MP4 동영상으로 저장

### 포함 기능

- [ ] AVAssetWriter 기반 동영상 인코딩 파이프라인
- [ ] 20초 × 30fps = 600 프레임 렌더링 + 인코딩
- [ ] 백그라운드 처리 + ProgressView 표시
- [ ] 4:5 (1080×1350) / 9:16 (1080×1920) 동영상 출력
- [ ] 카메라롤 저장

### 기술 체크포인트

- MTLTexture → CVPixelBuffer 변환 (매 프레임)
- `time` uniform을 0에서 20.0까지 순차 증가하며 렌더링
- 오디오 트랙 없는 순수 비디오 (소리 없음)
- 메모리 압박 방지: 프레임 버퍼 재사용

---

## 각 Phase 완료 체크리스트

### Phase 1 Done ✓
- [ ] 실제 iPhone에서 빌드 성공
- [ ] 사진 선택 → 쉐이더 적용 → 실시간 프리뷰 확인
- [ ] 파라미터 슬라이더 조작 시 즉시 반영
- [ ] 이미지 카메라롤 저장 성공

### Phase 2 Done ✓
- [ ] 3개 이상 쉐이더 레이어 스택 → 합성 렌더링 확인
- [ ] PNG 오버레이 투명도 보존 확인
- [ ] 전체 20종 효과 각 1회 동작 확인

### Phase 3 Done ✓
- [ ] 20초 MP4 파일 카메라롤 저장 성공
- [ ] Photos 앱에서 재생 확인
- [ ] 생성 중 앱 크래시 없음
