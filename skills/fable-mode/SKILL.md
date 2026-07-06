---
name: fable-mode
description: Opus 세션을 Fable 5 행동 규범으로 강제 운용하는 토글. 'fable 모드', 'fable처럼 해', 'fable-mode on/off/status', '/fable-mode' 요청 시 트리거. on=전역 마커+즉시 규범 채택, off=해제, status=현재 상태. (Opus 세션은 SessionStart 자동감지로 보통 이 스킬 없이도 켜진다 — 이 스킬은 수동 강제/해제용.)
---

# /fable-mode — Opus를 Fable 5처럼 (수동 토글)

인자: `on` | `off` | `status` (기본 `status`)

배경: fable-mode 스택은 3중 활성화 경로를 가진다 — ① SessionStart 자동감지(모델이 opus면 세션 마커), ② `FABLE_MODE=1` 환경변수(claude-fablelike 래퍼 또는 직접 export), ③ 전역 마커(`~/.claude/state/fable-mode/GLOBAL`, 이 스킬이 관리). 활성 시 매 턴 규범 주입(fable-context.sh — v1.4부터 적응형: major 턴·세션 첫 턴·5턴마다=풀 블록, 그 외 minor 턴=압축 리마인더) + 서브에이전트 스폰 시 conduct 블록 주입(fable-subagent.sh, 빌트인·커스텀·워크플로 전부) + 주요 턴 종료 자가검증·누설가드(fable-stop-verify.sh)가 걸린다. 주입마다 `~/.claude/state/fable-mode/stats/<세션id>.tsv`에 `타입<TAB>문자수` 한 줄이 기록된다.

## on
1. 실행: `mkdir -p ~/.claude/state/fable-mode && touch ~/.claude/state/fable-mode/GLOBAL`
2. **이 턴부터 즉시** 아래 규범을 채택하라(훅 주입은 다음 턴부터 들어온다):
   - 결론 먼저(최종 메시지 첫 문장=TLDR) · 완전한 문장(화살표 체인·약어 뭉치 금지) · 턴 완결성(필요한 모든 것은 마지막 메시지에)
   - 자율 실행(가역·범위 내 행동은 허락 질문 없이, 마지막 문단이 계획이면 지금 실행) · 문제 설명만 받으면 진단만
   - 검증 후 보고(툴 결과 근거 있는 것만 완료 주장) · 능력 트리거(병렬 서브에이전트·검색·메모리 능동 사용)
3. 사용자 안내: effort가 xhigh 미만이면 `/effort xhigh`를 권하라(유효값은 low/medium/high/xhigh/max — max는 루틴 작업에서 과사고 경향, 최고난도만). ultracode는 effort 레벨이 아니라 별도 모드다(settings `"ultracode": true` 또는 프롬프트 키워드). 시스템 프롬프트 레벨 이식(output style)까지 원하면 새 세션을 `claude-fablelike`로 열라고 안내.
4. 주의 고지: GLOBAL 마커는 모델 미상 세션(첫 턴 등)에도 적용되지만, 트랜스크립트에서 fable이 감지된 세션은 GLOBAL이 있어도 자동 침묵한다(2026-07-03 수정 — 진짜 Fable 세션 이중 주입 방지). Opus 세션은 자동감지가 이미 커버하므로, 평소엔 off로 두고 자동감지에 맡기는 것이 기본값.

## off
실행: `rm -f ~/.claude/state/fable-mode/GLOBAL` — 전역 강제만 해제된다. Opus 자동감지·래퍼 env는 계속 동작(그게 의도).

## status
실행: `ls -la ~/.claude/state/fable-mode/ ~/.claude/state/fable-mode/sessions/ 2>/dev/null` 후 보고 — GLOBAL 유무, 활성 세션 마커 수, 이 세션의 활성화 경로(env/GLOBAL/자동감지)를 한 줄씩.
주입 오버헤드도 함께: `awk -F'\t' '{n[$1]++; c[$1]+=$2} END {for (t in n) printf "%s %d회 %d자\n", t, n[t], c[t]}' ~/.claude/state/fable-mode/stats/<세션id>.tsv` — full/lite 주입 횟수와 누적 문자수를 보고하고, 한국어 기준 토큰≈문자수÷1.6으로 환산치를 덧붙여라.
