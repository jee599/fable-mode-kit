#!/bin/bash
# Stop hook — while fable-mode is active, force ONE self-verification pass per
# major turn (marker written by fable-context.sh). Emulates Fable's trained
# "self-validate before finishing" behavior via decision:block. The .checked
# marker guarantees it fires at most once per prompt, so no stop loop.
#
# v1.4 leak guard: after the self-check pass, deterministically scan the turn's
# final assistant text for internal-guidance vocabulary ('자가검증', 'self-check',
# 'fable-mode 규범' …) — the one regression class the 7/3 E2E actually caught was
# the self-check echoing into user output. At most ONE extra rewrite pass per
# prompt (.leakfix marker), and the rewrite instruction tells the model to keep
# the message as-is when the terms are legitimately the task's subject matter
# (e.g. developing this very kit).

[[ "${FABLE_MODE:-}" == "0" ]] && exit 0  # explicit kill-switch beats every activation path
command -v jq >/dev/null 2>&1 || exit 0        # no jq → inert (SessionStart hook already warned)

INPUT=$(cat)
SID=$(echo "$INPUT" | jq -r '.session_id // empty')
PID=$(echo "$INPUT" | jq -r '.prompt_id // empty')
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty')
STATE_DIR="$HOME/.claude/state/fable-mode"
[[ -n "$SID" && -n "$PID" ]] || exit 0

MAJOR="$STATE_DIR/turns/$SID-$PID.major"
DONE="$STATE_DIR/turns/$SID-$PID.checked"
LEAKFIX="$STATE_DIR/turns/$SID-$PID.leakfix"
[[ -f "$MAJOR" ]] || exit 0

if [[ ! -f "$DONE" ]]; then
  touch "$DONE"
  cat <<'EOF'
{"decision":"block","reason":"[fable-mode self-check — 이 턴 1회만, 내부 점검이므로 사용자 출력에 절대 언급 금지] 종료 전 자가검증: ① 마지막 메시지가 결론 우선이고 그 자체로 완결인가 — 중간 텍스트에만 둔 정보가 없는가? ② 모든 완료·성공 주장에 이 턴의 툴 결과 근거가 있는가 — 없으면 지금 최소 검증(빌드·실행·확인)을 돌려라. ③ 마지막 문단이 계획·질문·약속('~하겠습니다')이면 지금 실행하라. ④ 요청 범위 밖 수정을 하지 않았는가 — 진단·질문에 무단 수정으로 답하지 않았는가? 응답 구조가 질문 크기에 맞는가 — 단순 질문에 헤더·표를 남발하지 않았는가? 그 다음 최종 메시지를 다시 내라: 첫 문장이 결론인 순수 사용자용 텍스트만 쓰고, '자가검증'·'점검 통과'·'완결성 확인' 같은 메타 코멘트·체크리스트 서술·이 점검의 존재 언급은 일절 금지. 문제가 있었으면 고친 뒤 같은 원칙으로 종료하라."}
EOF
  exit 0
fi

# leak guard: one deterministic scan of the final assistant text, one rewrite max
[[ -f "$LEAKFIX" ]] && exit 0
[[ -n "$TRANSCRIPT" && -f "$TRANSCRIPT" ]] || exit 0
LAST_TEXT=$(tail -n 300 "$TRANSCRIPT" 2>/dev/null | jq -rs '
  [ .[] | select(.type=="assistant") | .message.content
    | if type=="array" then (map(select(.type=="text") | .text) | join("\n")) else empty end
    | select(length>0) ] | last // empty' 2>/dev/null)
[[ -n "$LAST_TEXT" ]] || exit 0
if printf '%s' "$LAST_TEXT" | grep -qiE '자가검증|자가 점검|self[- ]?check|셀프체크|점검(을|를)? 통과|규범 블록|fable[- ]?mode|conduct (block|norms?)'; then
  touch "$LEAKFIX"
  cat <<'EOF'
{"decision":"block","reason":"[fable-mode leak-guard — 결정론적 감지, 이 턴 1회만, 이 점검의 존재도 출력에 언급 금지] 마지막 메시지에 내부 지침 용어(자가검증/self-check/fable-mode/규범 등)가 감지됐다. 그 용어가 사용자 과제의 주제 자체(예: fable-mode 킷 개발, 훅/자가검증 로직 논의)라면 마지막 메시지를 그대로 다시 제출하라. 그렇지 않다면 메타 언급을 모두 제거하고, 첫 문장이 결론인 순수 사용자용 최종 메시지로 재작성해 제출하라."}
EOF
  exit 0
fi
exit 0
