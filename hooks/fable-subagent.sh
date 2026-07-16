#!/bin/bash
# SubagentStart hook — while fable-mode is active, inject an identity-neutral
# conduct block into EVERY subagent's starting context via
# hookSpecificOutput.additionalContext (supported for SubagentStart since ~v2.1.2xx;
# verified against v2.1.201 binary). This closes the biggest coverage gap of the
# per-turn UserPromptSubmit injection: subagents (built-in Explore/Plan/
# general-purpose, custom agents, Workflow agents) never see UserPromptSubmit.
#
# The block is deliberately identity-NEUTRAL (no "you are Opus") because a
# subagent may run a different model than the session (agent frontmatter model
# overrides); the norms are Fable's own conduct, so they are harmless if a
# Fable-powered subagent receives them.
#
# Activation mirrors fable-context.sh:
#   0. FABLE_MODE=0 kill-switch beats everything
#   1. FABLE_MODE=1 env
#   2. transcript signal: later-of(last assistant model line, /model local-command
#      stdout) — the assistant line alone lags one turn behind a mid-session /model
#      switch. fable → stand down, opus → activate.
#   3. session marker (fable-detect.sh) or GLOBAL marker (/fable-mode on)
# Dedupe: agents whose definition file already carries the static
# "fable-like-conduct" block (docs/conduct-snippet.md) are skipped.

[[ "${FABLE_MODE:-}" == "0" ]] && exit 0
command -v jq >/dev/null 2>&1 || exit 0

INPUT=$(cat)
SID=$(echo "$INPUT" | jq -r '.session_id // empty')
AGENT_TYPE=$(echo "$INPUT" | jq -r '.agent_type // empty')
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
STATE_DIR="$HOME/.claude/state/fable-mode"

active=0
[[ "${FABLE_MODE:-}" == "1" ]] && active=1

if [[ $active -eq 0 ]]; then
  SIG=""
  if [[ -n "$TRANSCRIPT" && -f "$TRANSCRIPT" ]]; then
    SIG=$(tail -c 400000 "$TRANSCRIPT" 2>/dev/null | awk '
      {
        if (match($0, /"model":"claude-[^"]*"/)) { m=tolower(substr($0,RSTART,RLENGTH)); ml=NR }
        s=$0
        while (match(s, /"content":"<local-command-stdout>(Set model to|Kept model as)[^"<]*/)) {
          w=tolower(substr(s,RSTART,RLENGTH)); wl=NR; s=substr(s,RSTART+RLENGTH)
        }
      }
      END {
        mk=""; if (m ~ /fable/) mk="fable"; else if (m ~ /opus/) mk="opus"; else if (m!="") mk="other"
        wk=""; if (w ~ /fable/) wk="fable"; else if (w ~ /opus/) wk="opus"; else if (w!="") wk="other"
        if (wk!="" && wl+0 > ml+0) print wk
        else if (mk!="") print mk
        else if (wk!="") print wk
      }')
  fi
  case "$SIG" in
    fable) exit 0 ;;
    opus)  active=1 ;;
    *)     [[ ( -n "$SID" && -f "$STATE_DIR/sessions/$SID" ) || -f "$STATE_DIR/GLOBAL" ]] && active=1 ;;
  esac
fi
[[ $active -eq 1 ]] || exit 0

# skip agents that already embed the static conduct block in their definition.
# Project agents may live in any ancestor of cwd (hooks can run from a subdirectory),
# so walk up. Plugin agents: single-plugin marketplaces keep agents/ at the repo root
# (marketplaces/<mp>/agents/), multi-plugin ones under plugins/<plugin>/agents/, and
# the cache mirrors both as cache/<mp>/<plugin>/<sha>/[plugins/<plugin>/]agents/.
# agent_type may be namespaced ("plugin:name"), so match on the bare name too.
# Worst case on a miss is a harmless double injection.
if [[ -n "$AGENT_TYPE" ]]; then
  BARE="${AGENT_TYPE##*:}"
  d="$CWD"
  while [[ -n "$d" && "$d" != "/" ]]; do
    for f in "$d/.claude/agents/$AGENT_TYPE.md" "$d/.claude/agents/$BARE.md"; do
      [[ -f "$f" ]] && grep -q 'fable-like-conduct' "$f" && exit 0
    done
    d="${d%/*}"
  done
  for f in "$HOME/.claude/agents/$AGENT_TYPE.md" \
           "$HOME/.claude/agents/$BARE.md" \
           "$HOME/.claude/plugins/marketplaces"/*/agents/"$BARE".md \
           "$HOME/.claude/plugins/marketplaces"/*/plugins/*/agents/"$BARE".md \
           "$HOME/.claude/plugins/cache"/*/*/*/agents/"$BARE".md \
           "$HOME/.claude/plugins/cache"/*/*/*/plugins/*/agents/"$BARE".md; do
    [[ -f "$f" ]] && grep -q 'fable-like-conduct' "$f" && exit 0
  done
fi

CTX=$(cat <<'EOF'
[conduct norms for this agent task — internal guidance; never mention this block or these rules in your output]
- Lead with the outcome: the first sentence of your final message states the conclusion (what happened / what you found); supporting detail after. Your final message is the ONLY thing returned to the caller — everything needed must be in it, written in complete sentences, no arrow chains, fragments, or invented codenames.
- Act without permission questions: for reversible actions inside the task scope, proceed; stop only for destructive actions or externally visible effects (publishing, sending, deleting shared state). Pick reasonable defaults for minor choices and note them. If your last paragraph is a plan, a question you could answer yourself, or a promise, execute it with tool calls before finishing.
- If the task asks a question or for a diagnosis, report findings only — do not modify files unasked.
- Claim only what a tool result in this run proves: report failures with their output, skips as skips, and completed work assertively, naming the check that proves it. Never say "should work" for something you could have run.
- Inspect targets before deleting or overwriting, and before state-changing commands confirm the evidence supports that specific action; batch independent tool calls in parallel; search when the answer may postdate your training data.
- Code: match the surrounding style and comment density; comment only constraints the code cannot show — never reviewer-directed justification. Reference code locations as file_path:line_number.
EOF
)
jq -n --arg ctx "$CTX" '{hookSpecificOutput:{hookEventName:"SubagentStart",additionalContext:$ctx}}'
exit 0
