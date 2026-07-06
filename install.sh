#!/usr/bin/env bash
# fable-mode kit installer — make Opus 4.8 behave like Fable 5 in Claude Code.
# Installs: 4 hooks (+ settings.json registration), fable-like output style,
# /fable-mode skill, claude-fablelike wrapper. Idempotent; backs up settings.json.
# Requirements: Claude Code CLI, jq, bash. macOS/Linux.
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
SETTINGS="$CLAUDE_DIR/settings.json"

command -v jq >/dev/null || { echo "ERROR: jq is required (brew install jq / apt install jq)"; exit 1; }

echo "== fable-mode kit → $CLAUDE_DIR"

# 1) files
mkdir -p "$CLAUDE_DIR/hooks" "$CLAUDE_DIR/output-styles" "$CLAUDE_DIR/skills/fable-mode" "$BIN_DIR"
install -m 755 "$SRC/hooks/fable-detect.sh" "$SRC/hooks/fable-context.sh" "$SRC/hooks/fable-stop-verify.sh" "$SRC/hooks/fable-subagent.sh" "$CLAUDE_DIR/hooks/"
install -m 644 "$SRC/output-styles/fable-like.md" "$CLAUDE_DIR/output-styles/"
install -m 644 "$SRC/skills/fable-mode/SKILL.md" "$CLAUDE_DIR/skills/fable-mode/"
install -m 755 "$SRC/bin/claude-fablelike" "$BIN_DIR/"
echo "   files installed (hooks x4, output style, skill, wrapper)"

# 2) register hooks in settings.json (merge, never overwrite; skip if already present)
[[ -f "$SETTINGS" ]] || echo '{}' > "$SETTINGS"
cp "$SETTINGS" "$SETTINGS.bak-fable-$(date +%Y%m%d%H%M%S)"
tmp=$(mktemp)
jq --arg h "$CLAUDE_DIR/hooks" '
  .hooks //= {} |
  (if (.hooks.SessionStart     // [] | tostring | contains("fable-detect.sh"))     then . else .hooks.SessionStart     = ((.hooks.SessionStart     // []) + [{hooks:[{type:"command", command:("bash " + $h + "/fable-detect.sh")}]}])     end) |
  (if (.hooks.UserPromptSubmit // [] | tostring | contains("fable-context.sh"))    then . else .hooks.UserPromptSubmit = ((.hooks.UserPromptSubmit // []) + [{hooks:[{type:"command", command:("bash " + $h + "/fable-context.sh")}]}])    end) |
  (if (.hooks.SubagentStart    // [] | tostring | contains("fable-subagent.sh"))   then . else .hooks.SubagentStart    = ((.hooks.SubagentStart    // []) + [{hooks:[{type:"command", command:("bash " + $h + "/fable-subagent.sh")}]}])   end) |
  (if (.hooks.Stop             // [] | tostring | contains("fable-stop-verify.sh")) then . else .hooks.Stop            = ((.hooks.Stop             // []) + [{hooks:[{type:"command", command:("bash " + $h + "/fable-stop-verify.sh")}]}]) end)
' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
echo "   hooks registered per-event, existing entries kept (settings.json backed up)"

# 3) smoke test the hooks with fake input
SID="install-test-$$"
OUT=$(echo "{\"session_id\":\"$SID\",\"model\":\"claude-opus-4-8\"}" | bash "$CLAUDE_DIR/hooks/fable-detect.sh")
[[ "$OUT" == *"[fable-mode]"* ]] || { echo "ERROR: fable-detect.sh smoke test failed"; exit 1; }
OUT=$(echo "{\"session_id\":\"$SID\",\"prompt_id\":\"t\",\"prompt\":\"hi\"}" | FABLE_MODE=1 bash "$CLAUDE_DIR/hooks/fable-context.sh")
[[ "$OUT" == *"상시 규범"* ]] || { echo "ERROR: fable-context.sh smoke test failed"; exit 1; }
OUT=$(echo "{\"session_id\":\"$SID\",\"agent_type\":\"smoke-test\"}" | FABLE_MODE=1 bash "$CLAUDE_DIR/hooks/fable-subagent.sh")
[[ "$OUT" == *"SubagentStart"* && "$OUT" == *"conduct norms"* ]] || { echo "ERROR: fable-subagent.sh smoke test failed"; exit 1; }
rm -f "$CLAUDE_DIR/state/fable-mode/sessions/$SID" "$CLAUDE_DIR/state/fable-mode/turns/$SID"* 2>/dev/null || true
echo "   smoke test passed"

cat <<'EOF'

Done. How it works:
  · Any session on an Opus model is auto-detected → Fable 5 conduct norms are
    injected every turn + one self-verification pass at the end of major turns.
  · Every subagent (built-in, custom, workflow) gets a conduct block at spawn
    via the SubagentStart hook — full-coverage, no agent-file edits needed.
  · Fable sessions are auto-detected too and left untouched.
  · Full stack (output style + xhigh effort):   claude-fablelike
  · Opt out for one command / cron / fast path: export FABLE_MODE=0
  · Manual toggle inside a session:             /fable-mode on|off|status
  · Optional: agents/conduct-snippet.md — for environments without
    SubagentStart hook support (old CLI, minimal -p setups).

Uninstall: ./uninstall.sh
EOF
