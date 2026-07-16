# 팀 진행 현황

업데이트: 2026-07-16

---

## Phase 1 작업 상태

| 태스크 | 상태 | 완료 시각 | 비고 |
|--------|------|-----------|------|
| T0: 아키텍처 설계 (ARCH_NOTES.md) | ✅ 완료 | 2026-07-16 | ARCH_NOTES.md 작성 완료 |
| T1: Xcode 프로젝트 세팅 | ⚠️ 부분 완료 | 2026-07-16 | Swift 파일 전체 작성 완료. .xcodeproj는 Xcode에서 수동 생성 필요 |
| T2: Metal 렌더링 파이프라인 기본 구조 | ✅ 완료 | 2026-07-16 | Renderer.swift, ShaderPipeline.swift, TextureUtils.swift |
| T3: Mesh Gradient .metal 구현 | ✅ 완료 | 2026-07-16 | MeshGradient.metal (MSL) — 색상 배열, distortion, swirl, grain |
| T4: Waves .metal 구현 | ✅ 완료 | 2026-07-16 | Waves.metal (MSL) — shape morph, frequency, amplitude, spacing |
| T5: SwiftUI EditorView 4-Zone 레이아웃 | ✅ 완료 | 2026-07-16 | EditorView.swift |
| T6: LayerTrayView | ✅ 완료 | 2026-07-16 | LayerTrayView.swift, LayerChip.swift (80×80pt) |
| T7: ParamPanelView (파라미터 행 4종) | ✅ 완료 | 2026-07-16 | FloatParamRow(52pt), ColorParamRow, BoolParamRow, EnumParamRow |
| T8: HomeView (PhotosPicker) | ✅ 완료 | 2026-07-16 | HomeView.swift |
| T9: RatioToggle (4:5 / 9:16) | ✅ 완료 | 2026-07-16 | RatioToggle.swift |
| T10: ImageExporter (카메라롤 저장) | ✅ 완료 | 2026-07-16 | ImageExporter.swift |
| T11: Git 커밋 & 푸시 | ✅ 완료 | 2026-07-16 | origin/main push 완료 (38 files, 4008 lines) |

---

## 다음 단계 (Xcode 프로젝트 생성)

⚠️ **수동 작업 필요**: Claude Code는 .xcodeproj 파일을 직접 생성할 수 없습니다.
아래 절차로 Xcode에서 프로젝트를 생성하고 소스 파일을 연결해야 합니다.

### Xcode 프로젝트 생성 절차
1. Xcode → File → New → Project
2. iOS → App 선택
3. Product Name: `PaperShaderEffector`
4. Bundle Identifier: `com.standardmanual.PaperShaderEffector`
5. Interface: SwiftUI, Language: Swift
6. **저장 위치**: `/Users/sihyunhwang/Library/Mobile Documents/com~apple~CloudDocs/파일/Work/StandardManual/JamEff/`
7. Deployment Target → iOS 17.0

### 소스 파일 추가 절차
Xcode 프로젝트 생성 후:
1. Project Navigator에서 `PaperShaderEffector` 그룹 우클릭 → "Add Files to..."
2. `PaperShaderEffector/` 폴더 전체 추가
3. Info.plist 내용 병합 (Portrait, NSPhotoLibraryUsageDescription 등)
4. Build & Run

---

## 완료된 파일 목록 (38 files, 4008 lines)

Models, Metal/Shaders, Views/ParamRows, Views/Components, Export, App 전체 작성 완료.
GitHub push: https://github.com/standardmanual/JAM-Eff (main 브랜치)
