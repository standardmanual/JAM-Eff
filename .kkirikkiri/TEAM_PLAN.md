# 팀 작업 계획

- 팀명: kkirikkiri-development-phase1
- 목표: Paper Shader Effector iOS 앱 Phase 1 구현
- 생성 시각: 2026-07-16

## PRD 위치
- PRD/01_PRD.md — 전체 요구사항 (UI 레이아웃 포함)
- PRD/02_DATA_MODEL.md — Swift 구조체, Metal 파이프라인
- PRD/03_PHASES.md — Phase 1 완료 체크리스트
- PRD/04_PROJECT_SPEC.md — AI 행동 규칙, Git 규칙, 시작 프롬프트
- PRD/05_SHADER_PARAMS.md — 29종 쉐이더 파라미터 완전 목록

## 프로젝트 정보
- GitHub: https://github.com/standardmanual/JAM-Eff
- 로컬 경로: /Users/sihyunhwang/Library/Mobile Documents/com~apple~CloudDocs/파일/Work/StandardManual/JamEff
- 타깃: iOS 17+, Swift, SwiftUI + Metal, 외부 패키지 없음
- 방향: Portrait 전용, 라이트 모드 전용
- 최적화: iPhone 15 Pro (393×852pt)

## 팀 구성
| 이름 | 역할 | 모델 | 담당 업무 |
|------|------|------|----------|
| lead | 팀장 | Opus | 아키텍처 결정, 태스크 배분, 코드 리뷰, 통합 판단 |
| dev1 | 개발자 1 | Opus | Metal 렌더링 파이프라인 (MTKView, ShaderPipeline, Renderer, .metal 파일) |
| dev2 | 개발자 2 | Opus | SwiftUI 4-Zone 편집 화면 (EditorView, LayerTray, ParamPanel, 컴포넌트) |

## Phase 1 태스크 목록
- [ ] T1: Xcode 프로젝트 세팅 (Portrait only, Light mode, iOS 17) → dev1
- [ ] T2: Metal 렌더링 파이프라인 기본 구조 (MTKView, Renderer, ShaderPipeline) → dev1
- [ ] T3: Mesh Gradient .metal 구현 (GLSL→MSL, 05_SHADER_PARAMS.md 기준) → dev1
- [ ] T4: Waves .metal 구현 → dev1
- [ ] T5: SwiftUI EditorView 4-Zone 레이아웃 → dev2
- [ ] T6: LayerTrayView (레이어 칩 80×80pt, 가로 스크롤) → dev2
- [ ] T7: ParamPanelView (FloatParamRow 52pt, ColorParamRow, EnumParamRow) → dev2
- [ ] T8: 사진 불러오기 (PhotosPicker) + HomeView → dev2
- [ ] T9: RatioToggle (4:5 / 9:16 Pill) + 비율 프리뷰 → dev1 + dev2
- [ ] T10: 이미지 저장 (ImageExporter, 카메라롤) → dev1
- [ ] T11: Git 커밋 & 푸시 (gh CLI, 기능 단위) → lead

## 주요 결정사항
- Metal 렌더링: MTKView + CADisplayLink (60fps)
- 쉐이더 포팅: paper-design/shaders GLSL → MSL 직역 변환
- 파라미터 전달: MTLBuffer로 struct 단위 전달
- 프리뷰 해상도: 화면 크기 @3x 기준 (393pt × ratio)
- 저장 해상도: 1080px 기준 (1080×1350 for 4:5, 1080×1920 for 9:16)

## 검증 결과
(팀장이 기록)
