# Paper Shader Effector — PRD 네비게이션

## 문서 목록

| 파일 | 내용 |
|------|------|
| [01_PRD.md](01_PRD.md) | 제품 요구사항 — 기능 정의, 화면 구성, 출력 스펙 |
| [02_DATA_MODEL.md](02_DATA_MODEL.md) | 데이터 모델 — Swift 구조체, Metal 파이프라인 설계 |
| [03_PHASES.md](03_PHASES.md) | Phase 계획 — 3단계 개발 순서 + 완료 체크리스트 |
| [04_PROJECT_SPEC.md](04_PROJECT_SPEC.md) | 프로젝트 스펙 — AI 행동 규칙, GLSL→MSL 변환표, 시작 프롬프트 |
| [05_SHADER_PARAMS.md](05_SHADER_PARAMS.md) | 쉐이더 파라미터 전체 레퍼런스 — 29종 쉐이더 파라미터 완전 목록 + iOS UI 매핑 |

## 빠른 시작

**Phase 1 개발을 시작하려면:**
`04_PROJECT_SPEC.md` 맨 아래 "Phase 1 시작 프롬프트"를 Claude Code에 붙여넣으세요.

## GitHub

**저장소:** https://github.com/standardmanual/JAM-Eff  
커밋 타이밍: 기능 단위 완성 시 & Phase 완료 시마다 푸시 (`[Phase N] 기능명` 형식)

---

## 핵심 결정 사항

- **플랫폼:** iOS 17+ (네이티브 앱, 앱스토어 미출시)
- **렌더링:** Metal (MSL) — WKWebView 아님
- **쉐이더 소스:** paper-design/shaders GLSL → MSL 포팅
- **출력:** 이미지 (4:5/9:16) + 20초 동영상
- **Phase 1 쉐이더:** 8종 (Mesh Gradient, Waves, Perlin Noise, Grain Gradient, Halftone Dots, Paper Texture, Pulsing Border, Dot Orbit)
