#!/bin/bash
# Stop hook — RETIRED (2026-07-07), now an inert stub.
#
# This used to force a pre-finish self-check by emitting {"decision":"block", ...}
# on every major turn. Two problems: (1) Claude Code echoes a Stop-block's `reason`
# into the USER's transcript, so the internal checklist surfaced every major turn
# and read like an error; (2) blocking forces an extra generation pass (the turn's
# output is produced twice), the real cost of the mechanism.
#
# The self-check moved to fable-context.sh's per-turn injection — the "마무리 점검"
# bullet in the full block. That path is a UserPromptSubmit reminder: model-visible
# context, never shown to the user, no extra pass. The old leak-guard rewrite pass
# is dropped too — with a silent proactive reminder the echo-into-output risk is
# already covered by the norm block's "don't mention these terms in output" clause.
#
# Kept registered in settings.json (Stop) as a no-op so re-enabling is a one-file
# git revert of this script — no settings edit needed.
exit 0
