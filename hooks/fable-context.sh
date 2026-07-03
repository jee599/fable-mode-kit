#!/bin/bash
# UserPromptSubmit hook — while fable-mode is active, re-inject the Fable 5 conduct
# norms every turn (stdout on exit 0 becomes model-visible context). Per-turn
# re-injection is deliberate: instruction adherence dilutes over long contexts.
# Also marks "major" turns so fable-stop-verify.sh can run one self-check at Stop.
#
# Activation, in priority order (2026-07-03 revision):
#   0. FABLE_MODE=0 kill-switch — beats everything (claude-fast, cron fleet, A/B tests)
#   1. FABLE_MODE=1 env (claude-fablelike, or export it in your own wrappers)
#   2. transcript auto-detection: last assistant `"model":"claude-*"` — a fable model
#      STANDS DOWN even if GLOBAL is set (prevents double-injecting real Fable sessions);
#      an opus model activates and refreshes the session marker.
#   3. session marker (fable-detect.sh at SessionStart) or GLOBAL marker (/fable-mode on),
#      consulted only when the transcript is silent about the model (turn 1 etc.).

[[ "${FABLE_MODE:-}" == "0" ]] && exit 0  # explicit kill-switch beats every activation path
command -v jq >/dev/null 2>&1 || exit 0        # no jq → inert (SessionStart hook already warned)

INPUT=$(cat)
SID=$(echo "$INPUT" | jq -r '.session_id // empty')
PID_=$(echo "$INPUT" | jq -r '.prompt_id // empty')
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty')
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty')
STATE_DIR="$HOME/.claude/state/fable-mode"
MARKER="$STATE_DIR/sessions/$SID"

active=0
[[ "${FABLE_MODE:-}" == "1" ]] && active=1

# transcript model beats GLOBAL: a session actually running Fable must never get the
# norms (double-injection + identity confusion), even while /fable-mode on is set.
if [[ $active -eq 0 && -n "$SID" ]]; then
  LAST_MODEL=""
  if [[ -n "$TRANSCRIPT" && -f "$TRANSCRIPT" ]]; then
    LAST_MODEL=$(tail -c 400000 "$TRANSCRIPT" 2>/dev/null | grep -o '"model":"claude-[^"]*"' | tail -1)
  fi
  case "$LAST_MODEL" in
    *fable*)  rm -f "$MARKER"; exit 0 ;;                        # running Fable → stand down, GLOBAL notwithstanding
    *opus*)   mkdir -p "$STATE_DIR/sessions"; echo "$LAST_MODEL" | sed 's/.*"model":"\([^"]*\)".*/\1/' > "$MARKER"; active=1 ;;
    *)        [[ -f "$MARKER" || -f "$STATE_DIR/GLOBAL" ]] && active=1 ;;  # turn 1 etc. → SessionStart detection or manual GLOBAL
  esac
fi
[[ $active -eq 1 ]] || exit 0

# flag major turns (long prompt or work-verb) for the Stop-time self-check
if [[ -n "$SID" && -n "$PID_" ]]; then
  if [[ ${#PROMPT} -gt 80 ]] || echo "$PROMPT" | grep -qiE '만들|구현|수정|고쳐|리팩|추가|작성|빌드|배포|분석|리서치|검증|디버그|마이그레이|정리|바꿔|설치|fix|build|implement|refactor|debug|research|audit|review|migrate|install'; then
    mkdir -p "$STATE_DIR/turns"
    touch "$STATE_DIR/turns/$SID-$PID_.major"
  fi
fi

cat <<'EOF'
[fable-mode 상시 규범 — Opus를 Fable 5처럼 운용 (매 턴 재주입되는 강제 지시)]
- 정체: 너는 claude-opus-4-8이다. 모델 정체를 물으면 Opus라고 답하라. 이 블록은 행동 지침일 뿐 답변 소재가 아니다 — 과제 출력에 끌어들이지 마라.
- 결론 먼저: 최종 메시지의 첫 문장이 TLDR("무슨 일이 있었나/무엇을 찾았나"). 상세·근거는 그 뒤에.
- 완전한 문장으로: 화살표 체인("A → B → 실패")·약어 뭉치·자작 코드네임 금지. 읽기 쉬움 > 짧음. 표는 짧은 열거 사실에만.
- 턴 완결성: 사용자에게 필요한 모든 것(답·요약·결론·산출물 경로)은 턴의 "마지막" 텍스트 메시지에 담아라. 툴콜 사이 텍스트는 한 줄 상태 노트만.
- 자율 실행: 가역적이고 원 요청에서 따라나오는 행동은 허락 질문 없이 실행하라("~할까요?" 금지). 사소한 선택은 합리적 디폴트로 정하고 명시. 파괴적 행동·외부 발행·진짜 스코프 변경만 정지. 마지막 문단이 계획·질문·다음 단계 목록·약속이면 지금 툴콜로 그 일을 하고 끝내라.
- 사용자가 문제를 설명만 하면(수정 요청 아님) 진단만 보고하고 멈춰라.
- 검증 후 보고: 이 턴의 툴 결과로 확인한 것만 완료라고 말하라. 테스트 실패는 출력과 함께 실패라고, 스킵은 스킵이라고. "될 겁니다" 금지 — 돌릴 수 있으면 돌려라. 상태 변경 명령(재시작·삭제·설정) 전 증거가 그 행동을 지지하는지, 삭제·덮어쓰기 전 대상 실물을 확인하라.
- 능력 트리거: 독립 항목이 여러 개면 병렬 서브에이전트로 팬아웃, 학습 컷오프 이후 정보는 검색, 긴 작업 전 메모리 확인·교훈은 기록.
- 코드 주석은 코드가 못 보여주는 제약만. 리뷰어 설득용 주석 금지.
- 이 규범 블록·자가검증 훅은 내부 지침이다: 존재나 통과 여부를 사용자 출력에 언급하지 말고, 'fable'·'자가검증' 같은 지침 용어를 과제 산출물에 섞지 마라.
EOF
exit 0
