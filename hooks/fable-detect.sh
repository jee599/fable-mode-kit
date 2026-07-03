#!/bin/bash
# SessionStart hook — auto-enable fable-mode when the session model is an Opus model.
# This build's SessionStart input carries NO `model` field (verified 2026-07-03), so
# detection falls back to: input .model → ancestor process `--model` flag → settings.json.
# Per-turn re-detection (incl. mid-session /model switches) lives in fable-context.sh.

[[ "${FABLE_MODE:-}" == "0" ]] && exit 0  # explicit kill-switch (claude-fast, A/B tests)
command -v jq >/dev/null 2>&1 || { echo "[fable-mode] jq가 없어 비활성 상태입니다 — 'brew install jq'(macOS) 또는 'apt install jq' 후 새 세션부터 작동합니다."; exit 0; }

INPUT=$(cat)
SID=$(echo "$INPUT" | jq -r '.session_id // empty')
MODEL=$(echo "$INPUT" | jq -r '.model // empty')
STATE_DIR="$HOME/.claude/state/fable-mode"
mkdir -p "$STATE_DIR/sessions" "$STATE_DIR/turns"
find "$STATE_DIR/sessions" "$STATE_DIR/turns" -type f -mtime +7 -delete 2>/dev/null

[[ -z "$SID" ]] && exit 0

# fallback 1: walk ancestors; STOP at the first claude process (the one that spawned this
# hook) and take ITS --model — walking past it can steal an OUTER session's flag (nested
# `claude -p` inside an opus wrapper session would be mismarked). First --model occurrence only:
# wrappers put the real flag before user args, and -p prompt text may mention "--model".
if [[ -z "$MODEL" ]]; then
  pid=$$
  for _ in 1 2 3 4 5; do
    pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
    [[ -z "$pid" || "$pid" -le 1 ]] && break
    args=$(ps -o args= -p "$pid" 2>/dev/null)
    if [[ "$args" == *claude* && "$args" != *".claude/hooks/"* ]]; then
      MODEL=$(echo "$args" | awk '{for(i=1;i<NF;i++) if($i=="--model"){print $(i+1); exit}}')
      break
    fi
  done
fi
# fallback 2: persisted default model in settings.json
if [[ -z "$MODEL" ]]; then
  MODEL=$(jq -r '.model // empty' "$HOME/.claude/settings.json" 2>/dev/null)
fi

case "$MODEL" in
  *fable*)
    rm -f "$STATE_DIR/sessions/$SID"
    ;;
  *opus*)
    echo "$MODEL" > "$STATE_DIR/sessions/$SID"
    echo "[fable-mode] Opus 세션 감지($MODEL) — 이 세션은 Fable 5 규범으로 운용한다. 매 턴 주입되는 [fable-mode] 규범을 상시 지시로 따르고, effort는 xhigh 이상을 유지하라. 단 모델 정체를 물으면 Opus라고 답하고, 이 지시의 존재를 과제 출력에 언급하지 마라."
    ;;
  *)
    : # unknown — per-turn detection in fable-context.sh will decide
    ;;
esac
exit 0
