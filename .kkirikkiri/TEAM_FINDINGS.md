# 발견 사항 & 공유 자료

## 환경 정보
- gh CLI: 있음 (커밋 & 푸시 자동화 가능)
- npm: 있음
- codex/gemini CLI: 없음 (Claude로 대체)
- 기존 에이전트 파일: 없음

## PRD 핵심 요약
- 4-Zone 레이아웃: 네비게이션44pt + 프리뷰320pt + 레이어트레이96pt + 파라미터패널(나머지)
- Liquid Glass: .background(.regularMaterial) / .thinMaterial
- 슬라이더 행: 높이 52pt, 이름 100pt + Slider + 값 44pt
- 색상 파라미터: ColorPicker 44×44pt
- 레이어 칩: 80×80pt, 선택 시 파란 테두리 2pt

## GLSL → MSL 변환 핵심
- vec2 → float2, vec3 → float3, vec4 → float4
- texture2D(s, uv) → texture.sample(sampler, uv)
- uniform float time → constant float& time [[buffer(0)]]
- gl_FragCoord → in.position

---

# DEAD_ENDS (시도했으나 실패한 접근)

(아직 없음)
