# fable-mode — make Opus behave like Fable 5 in Claude Code

## Quick start — 2 lines, zero config

Inside any Claude Code session:

```
/plugin marketplace add jee599/fable-mode-kit
/plugin install fable-mode@jidonglab
```

Done. From your next session on, **any Opus session is auto-detected** and runs under
Fable 5 conduct norms — nothing to configure, no settings.json edits. Fable sessions
are detected too and left untouched. Opt out anytime with `export FABLE_MODE=0`,
toggle with `/fable-mode on|off|status`. Only requirement: `jq`
(`brew install jq` — if missing, the plugin tells you at session start instead of
failing silently).

---

Claude Fable 5 costs exactly 2× Opus 4.8 ($10/$50 vs $5/$25 per Mtok). The measurable
difference between them splits into two parts: **a Fable-only system-prompt conduct layer**
(portable) and **model weights** (not portable). This kit ports the first part.

Measured result (author's A/B/C probes, same 3 tasks · same effort · judged on a
6-dimension conduct rubric, 36 pts):

| condition | score | conduct fidelity |
|---|---|---|
| bare Opus 4.8 | 23/36 | 64% |
| Opus 4.8 + this kit | **35/36** | **97%** |
| real Fable 5 (baseline) | 36/36 | 100% |

Same-task measured cost with the kit was **71–78% of Fable** (half unit price, minus
extra self-correction turns). What the kit does *not* close: entangled single-pass
reasoning and long unsupervised runs (~5–11 pt third-party benchmark gap, estimate) —
route those to Fable when you have it, or compensate with multi-agent verification.

Full measurement report and a principles explainer (Korean, 13+14 slides, viewable in any browser):
[measurements](https://jee599.github.io/reports/posts/fable-mode-v14-ir.html) ·
[how it works](https://jee599.github.io/reports/posts/fable-mode-principles-ir.html)

## What bare Opus actually does wrong (and the kit fixes)

- Asked *"why does this bug happen?"* → bare Opus **silently edited the file** and
  asserted results without running anything. With the kit: diagnosis only, verified by
  execution. (measured 6/12 → 12/12)
- Given an ambiguous *"clean up these log files"* → bare Opus investigated, then ended
  with *"which way would you like?"* — zero action. With the kit: executes a
  non-destructive default, verifies, defers only the destructive part. (5/12 → 12/12)

## Install

**Route A — plugin (recommended).** Inside any Claude Code session:

```
/plugin marketplace add jee599/fable-mode-kit
/plugin install fable-mode@jidonglab
```

Hooks, the `/fable-mode` skill, and the `fable-like` output style register
automatically; update later with `/plugin update`, remove with `/plugin uninstall`.
The `claude-fablelike` wrapper is not part of the plugin — grab it from `bin/` if
you want the one-shot launcher, or just run `claude --model claude-opus-4-8
--effort xhigh --settings '{"outputStyle":"fable-like"}'`.

**Route B — classic installer** (no plugin system, or you want the wrapper installed):

```bash
git clone https://github.com/jee599/fable-mode-kit && cd fable-mode-kit && ./install.sh
```

Requires: Claude Code CLI, `jq`, bash (macOS/Linux). The installer is idempotent,
merges (never overwrites) your `~/.claude/settings.json`, backs it up first, and
smoke-tests the hooks before finishing.

> Pick **one** route. Installing both registers the hooks twice and the norms get
> injected twice per turn (harmless but wasteful). `uninstall.sh` only removes the
> classic install; `/plugin uninstall` only removes the plugin.

## What gets installed

| piece | file | role |
|---|---|---|
| SessionStart hook | `hooks/fable-detect.sh` | auto-detects Opus sessions → arms fable-mode |
| UserPromptSubmit hook | `hooks/fable-context.sh` | re-injects Fable conduct norms every turn — **adaptive since v1.4**: full ~1.4k-char block on major turns / session start / every 5th turn, a ~0.2k-char reminder on minor turns (−84% injection overhead on simple Q&A turns); logs every injection to `state/fable-mode/stats/` |
| SubagentStart hook | `hooks/fable-subagent.sh` | injects an identity-neutral conduct block into **every subagent** at spawn (built-in, custom, and workflow agents — they never see UserPromptSubmit injections) |
| Stop hook | `hooks/fable-stop-verify.sh` | forces **one** self-verification pass per major turn (verify-before-report, conclusion-first final message, scope check) + **deterministic leak guard since v1.4**: greps the final message for internal-guidance vocabulary and forces one rewrite if the self-check echoed into user output |
| output style | `output-styles/fable-like.md` | system-prompt-level port of the norms |
| skill | `skills/fable-mode/` | `/fable-mode on\|off\|status` manual toggle |
| wrapper | `bin/claude-fablelike` | one-shot: Opus + xhigh effort + output style + hooks |
| optional | `agents/conduct-snippet.md` | fallback for environments without SubagentStart support (CLI < ~2.1.2xx); agents whose definition already contains it are auto-skipped by the hook (no double injection) |

## Behavior & controls

- **Auto**: any session on an Opus model gets the norms; Fable sessions are detected
  and left untouched (no double injection).
- **Subagent coverage**: the SubagentStart hook covers agents spawned by the Agent
  tool and workflows, so conduct norms hold across fan-out work — the previous gap
  where subagents ran bare. The injected block is identity-neutral (a subagent may
  run a different model than the session).
- **Off switch**: `export FABLE_MODE=0` disables everything for that process tree —
  use in cron jobs and cheap one-shot wrappers (the Stop self-check adds one extra
  turn per major prompt, which you may not want on a timeout budget).
- **Force on**: `export FABLE_MODE=1` (what `claude-fablelike` does) or `/fable-mode on`.
- **Overhead telemetry** (v1.4): every injection appends `type<TAB>chars` to
  `~/.claude/state/fable-mode/stats/<session-id>.tsv`; `/fable-mode status` reports the
  session's full/lite counts and the token overhead they cost. Measured block sizes:
  full 1,377 chars (≈860 tokens), lite 214 chars (≈135 tokens).
- The injected block tells the model it is Opus (prevents identity leakage into task
  output) and forbids mentioning the norms/self-check in user-facing text — both were
  real observed failure modes, fixed and re-verified.

## Honest limits

- 97% is a *conduct* score on tasks chosen to expose conduct differences — it is not
  an intelligence benchmark. Sample: 3 tasks × 1 run per condition, plus a no-tool
  Q&A probe added 2026-07-06 (kit answer ≈85–90% equivalent to Fable's at 49% of its
  cost on that task; deliverable equivalence on the tool tasks measured 80–95%).
  Diagnosis + implementation re-measured 2026-07-07 on v1.4: aggregate cost across
  the 4 task types = **72% of Fable**, with all three slugify implementations
  producing identical output on shared test cases.
- The stack reaches the norms via correction turns (8 vs 4 turns on one task); Fable
  gets there on the first attempt. You pay turns, not quality.
- Entangled first-pass reasoning and long autonomous runs keep a real gap. For
  review/audit work, compensate with fan-out + adversarial verification (costs
  1–2.5× a single Fable run, estimate); for high-stakes decisions, N attempts +
  a judge pass + human gate.

## Uninstall

```bash
./uninstall.sh
```

Removes all files, deregisters the hooks (settings.json backed up again), deletes state.

## License

MIT
