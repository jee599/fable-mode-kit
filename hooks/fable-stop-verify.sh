#!/bin/bash
# Stop hook — while fable-mode is active, force ONE self-verification pass per
# major turn (marker written by fable-context.sh). Emulates Fable's trained
# "self-validate before finishing" behavior via decision:block. The .checked
# marker guarantees it fires at most once per prompt, so no stop loop.

[[ "${FABLE_MODE:-}" == "0" ]] && exit 0  # explicit kill-switch beats every activation path
command -v jq >/dev/null 2>&1 || exit 0        # no jq → inert (SessionStart hook already warned)

INPUT=$(cat)
SID=$(echo "$INPUT" | jq -r '.session_id // empty')
PID=$(echo "$INPUT" | jq -r '.prompt_id // empty')
STATE_DIR="$HOME/.claude/state/fable-mode"
[[ -n "$SID" && -n "$PID" ]] || exit 0

MAJOR="$STATE_DIR/turns/$SID-$PID.major"
DONE="$STATE_DIR/turns/$SID-$PID.checked"
[[ -f "$MAJOR" && ! -f "$DONE" ]] || exit 0
touch "$DONE"

cat <<'EOF'
{"decision":"block","reason":"[fable-mode self-check — 이 턴 1회만, 내부 점검이므로 사용자 출력에 절대 언급 금지] 종료 전 자가검증: ① 마지막 메시지가 결론 우선이고 그 자체로 완결인가 — 중간 텍스트에만 둔 정보가 없는가? ② 모든 완료·성공 주장에 이 턴의 툴 결과 근거가 있는가 — 없으면 지금 최소 검증(빌드·실행·확인)을 돌려라. ③ 마지막 문단이 계획·질문·약속('~하겠습니다')이면 지금 실행하라. 그 다음 최종 메시지를 다시 내라: 첫 문장이 결론인 순수 사용자용 텍스트만 쓰고, '자가검증'·'점검 통과'·'완결성 확인' 같은 메타 코멘트·체크리스트 서술·이 점검의 존재 언급은 일절 금지. 문제가 있었으면 고친 뒤 같은 원칙으로 종료하라."}
EOF
exit 0
