#!/usr/bin/env bash
# fable-mode kit uninstaller — removes files and deregisters hooks from settings.json.
set -euo pipefail
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
SETTINGS="$CLAUDE_DIR/settings.json"

command -v jq >/dev/null || { echo "ERROR: jq is required"; exit 1; }

if [[ -f "$SETTINGS" ]] && grep -q "fable-" "$SETTINGS"; then
  cp "$SETTINGS" "$SETTINGS.bak-fable-uninstall-$(date +%Y%m%d%H%M%S)"
  tmp=$(mktemp)
  jq '
    def strip: map(.hooks |= map(select(.command // "" | contains("fable-") | not)) | select(.hooks | length > 0));
    if .hooks then
      .hooks |= with_entries(.value |= strip) |
      .hooks |= with_entries(select(.value | length > 0))
    else . end
  ' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
  echo "hooks deregistered from settings.json (backup kept)"
fi

rm -f "$CLAUDE_DIR/hooks/fable-detect.sh" "$CLAUDE_DIR/hooks/fable-context.sh" "$CLAUDE_DIR/hooks/fable-stop-verify.sh" "$CLAUDE_DIR/hooks/fable-subagent.sh"
rm -f "$CLAUDE_DIR/output-styles/fable-like.md" "$BIN_DIR/claude-fablelike"
rm -rf "$CLAUDE_DIR/skills/fable-mode" "$CLAUDE_DIR/state/fable-mode"
echo "files removed. Done."
