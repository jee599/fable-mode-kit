#!/usr/bin/env bash
# fable-mode kit installer — make Opus 4.8 behave like Fable 5 in Claude Code.
# Installs: 3 hooks (+ settings.json registration), fable-like output style,
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
install -m 755 "$SRC/hooks/fable-detect.sh" "$SRC/hooks/fable-context.sh" "$SRC/hooks/fable-stop-verify.sh" "$CLAUDE_DIR/hooks/"
install -m 644 "$SRC/output-styles/fable-like.md" "$CLAUDE_DIR/output-styles/"
install -m 644 "$SRC/skills/fable-mode/SKILL.md" "$CLAUDE_DIR/skills/fable-mode/"
install -m 755 "$SRC/bin/claude-fablelike" "$BIN_DIR/"
echo "   files installed (hooks x3, output style, skill, wrapper)"

# 2) register hooks in settings.json (merge, never overwrite; skip if already present)
[[ -f "$SETTINGS" ]] || echo '{}' > "$SETTINGS"
if grep -q "fable-detect.sh" "$SETTINGS"; then
  echo "   hooks already registered in settings.json — skipping"
else
  cp "$SETTINGS" "$SETTINGS.bak-fable-$(date +%Y%m%d%H%M%S)"
  tmp=$(mktemp)
  jq --arg h "$CLAUDE_DIR/hooks" '
    .hooks //= {} |
    .hooks.SessionStart      = ((.hooks.SessionStart      // []) + [{hooks:[{type:"command", command:("bash " + $h + "/fable-detect.sh")}]}]) |
    .hooks.UserPromptSubmit  = ((.hooks.UserPromptSubmit  // []) + [{hooks:[{type:"command", command:("bash " + $h + "/fable-context.sh")}]}]) |
    .hooks.Stop              = ((.hooks.Stop              // []) + [{hooks:[{type:"command", command:("bash " + $h + "/fable-stop-verify.sh")}]}])
  ' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
  echo "   hooks registered (settings.json backed up)"
fi

# 3) smoke test the hooks with fake input
SID="install-test-$$"
OUT=$(echo "{\"session_id\":\"$SID\",\"model\":\"claude-opus-4-8\"}" | bash "$CLAUDE_DIR/hooks/fable-detect.sh")
[[ "$OUT" == *"[fable-mode]"* ]] || { echo "ERROR: fable-detect.sh smoke test failed"; exit 1; }
OUT=$(echo "{\"session_id\":\"$SID\",\"prompt_id\":\"t\",\"prompt\":\"hi\"}" | FABLE_MODE=1 bash "$CLAUDE_DIR/hooks/fable-context.sh")
[[ "$OUT" == *"상시 규범"* ]] || { echo "ERROR: fable-context.sh smoke test failed"; exit 1; }
rm -f "$CLAUDE_DIR/state/fable-mode/sessions/$SID" "$CLAUDE_DIR/state/fable-mode/turns/$SID"* 2>/dev/null || true
echo "   smoke test passed"

cat <<'EOF'

Done. How it works:
  · Any session on an Opus model is auto-detected → Fable 5 conduct norms are
    injected every turn + one self-verification pass at the end of major turns.
  · Fable sessions are auto-detected too and left untouched.
  · Full stack (output style + xhigh effort):   claude-fablelike
  · Opt out for one command / cron / fast path: export FABLE_MODE=0
  · Manual toggle inside a session:             /fable-mode on|off|status
  · Optional: agents/conduct-snippet.md — paste into your custom agent
    definitions (subagents don't receive hook injections).

Uninstall: ./uninstall.sh
EOF
