<h1 align="center">
  <br>
  ⚡ fable-mode
  <br>
</h1>

<h3 align="center">
  You're paying 2× for Claude Fable 5. Half of what you're buying is a system prompt.<br>
  This kit ports that half to Opus. <code>/plugin install fable-mode@jidonglab</code> → next session, done.
</h3>

<p align="center">
  <img src="https://img.shields.io/badge/version-v1.5-blue?style=flat-square" alt="Version" />
  <img src="https://img.shields.io/badge/conduct_fidelity-64%25→97%25-brightgreen?style=flat-square" alt="Conduct" />
  <img src="https://img.shields.io/badge/cost-0.72×_Fable-orange?style=flat-square" alt="Cost" />
  <a href="LICENSE"><img src="https://img.shields.io/github/license/jee599/fable-mode-kit?style=flat-square" alt="License" /></a>
</p>

<p align="center">
  <a href="#-see-the-difference">Examples</a> •
  <a href="#-the-numbers-no-cherry-picking">Benchmark</a> •
  <a href="#%EF%B8%8F-how-it-works">How it works</a> •
  <a href="#-reports">Reports</a> •
  <a href="docs/README.ko.md">한국어</a> •
  <a href="docs/README.ja.md">日本語</a> •
  <a href="docs/README.zh.md">中文</a>
</p>

---

```
  bare Opus, asked "why is this buggy?"   →   silently EDITS your file, asserts untested results
  bare Opus, asked "clean this up"        →   investigates, then stalls: "which way would you like?"
  Opus + fable-mode                       →   diagnoses only · acts on safe defaults · proves claims

  conduct fidelity  64% → 97%      cost  72% of Fable      deliverable equivalence  80–95%
```

<h3 align="center">⬇️ Two lines inside any Claude Code session. Zero config.</h3>

```
/plugin marketplace add jee599/fable-mode-kit
/plugin install fable-mode@jidonglab
```

<p align="center">
  From your next session on, <b>every Opus session is auto-detected</b> and runs under Fable 5 conduct norms.<br>
  Fable sessions are detected too and left untouched. Only requirement: <code>jq</code>.
</p>

<details>
<summary>Classic installer (no plugin system, or you want the <code>claude-fablelike</code> wrapper)</summary>

```bash
git clone https://github.com/jee599/fable-mode-kit && cd fable-mode-kit && ./install.sh
```

Requires: Claude Code CLI, `jq`, bash (macOS/Linux). Idempotent; merges (never overwrites)
your `~/.claude/settings.json`, backs it up first, and smoke-tests the hooks before finishing.

> [!WARNING]
> Pick **one** route. Installing both registers the hooks twice and the norms get injected
> twice per turn (harmless but wasteful). `uninstall.sh` only removes the classic install;
> `/plugin uninstall` only removes the plugin.

</details>

## 👀 See the Difference

Both failures below are real, measured runs — not hypotheticals.

### 🔍 Asked *"why does this bug happen?"* — 6/12 → 12/12

<table>
<tr>
<td width="50%">

**❌ bare Opus 4.8**
```
Silently edits your file.
Asserts the fix works —
without running anything.

(You asked a question.
 It rewrote your code.)
```

</td>
<td width="50%">

**✅ with fable-mode**
```
Diagnoses only — no edits.
Runs the code to prove
the root cause.

Reports conclusion first,
evidence after.
```

</td>
</tr>
</table>

### 🧹 Asked an ambiguous *"clean up these log files"* — 5/12 → 12/12

<table>
<tr>
<td width="50%">

**❌ bare Opus 4.8**
```
Investigates thoroughly.
Then ends with:
"which way would you like?"

Zero action taken.
```

</td>
<td width="50%">

**✅ with fable-mode**
```
Executes a non-destructive
default, verifies it,
defers only the destructive
part to you.
```

</td>
</tr>
</table>

## 📊 The Numbers (No Cherry-Picking)

**Conduct fidelity** — same tasks, same effort, judged on a 6-dimension rubric (36 pts):

| condition | score | fidelity |
|:---|:---:|:---:|
| bare Opus 4.8 | 23/36 | 64% |
| **Opus 4.8 + fable-mode** | **35/36** | **97%** |
| real Fable 5 (baseline) | 36/36 | 100% |

**Cost + deliverable equivalence** — 4 task types × 3 conditions, tokens from transcript
`usage`, official per-Mtok pricing (Opus $5/$25, Fable $10/$50):

| task | bare Opus | + kit | Fable 5 | kit vs Fable | equivalence |
|:---|---:|---:|---:|:---:|:---:|
| diagnosis | $0.23 | $0.28 | $0.49 | 57% | ~95% |
| implementation | $0.34 | $0.45 | $0.49 | 💀 91% | ~90% |
| ambiguous cleanup | $0.86 | $1.13 | $1.52 | 74% | ~80% |
| simple Q&A | $0.12 | $0.13 | $0.27 | 🏆 49% | ~85% |
| **total** | **$1.54** | **$1.99** | **$2.77** | **72%** | **80–95%** |

> Cells show rounded per-run values; totals and × ratios are computed from unrounded raw
> values, so recomputing from the displayed cells can differ by ±1 in the last digit.

> [!NOTE]
> The ugly numbers stay in the table. On the implementation task the kit's cost win over
> Fable was only 9%. On the ambiguous task the kit spent **31% more than bare Opus** —
> that's the price of the self-correction turns that buy the conduct. Fable writes half
> the output tokens (9.8k vs 20.0k) and still loses on cost because its unit price is 2×.
> All three implementation outputs (bare / kit / Fable) produced **identical results** on
> shared test cases. These figures were measured on v1.4; v1.5 removes the Stop hook's
> extra generation pass on major turns, so its cost is the same or lower.

## 🆚 Why Not Just an Output Style?

An output style is one of the three layers — it's not enough alone:

| | CLAUDE.md rules | output style | **fable-mode hooks** |
|:---|:---:|:---:|:---:|
| Survives long-context dilution | ❌ | 🟡 | ✅ per-turn re-injection |
| Covers subagents (Explore/Plan/custom/workflows) | ❌ | ❌ | ✅ SubagentStart |
| Pre-finish self-check every major turn | ❌ | ❌ | ✅ injected in-context (no extra pass) |
| Norm leakage kept out of output | ❌ | ❌ | ✅ leak vector removed at the source |
| Auto-detects Opus sessions, stands down on Fable | ❌ | ❌ | ✅ |
| Injection overhead telemetry | ❌ | ❌ | ✅ v1.4 |

## ⚙️ How It Works

Three live hooks grab three moments of the session lifecycle; a fourth (Stop) is a
retired no-op stub. No daemon, no proxy — state is empty marker files.

```
  ┌──────────────────────────────────────────────────────────────┐
  │  SessionStart      fable-detect.sh                           │
  │    "is this Opus?" — input .model → ancestor --model flag    │
  │    → settings.json (a guess → neutral announcement)          │
  │           ↓                                                  │
  │  UserPromptSubmit  fable-context.sh          (every turn)    │
  │    per-turn transcript detection (mid-session /model         │
  │    switches, Fable stand-down) + re-injects the conduct      │
  │    norms — adaptive: major = full block · minor = −86%       │
  │    reminder. Full block's last bullet is the pre-finish      │
  │    self-check (in-context, no extra generation pass)         │
  │           ↓                                                  │
  │  SubagentStart     fable-subagent.sh         (every spawn)   │
  │    subagents never see UserPromptSubmit → inject at spawn    │
  │                                                              │
  │  Stop              fable-stop-verify.sh      (retired stub)  │
  │    no-op — kept registered so re-enabling is a one-file      │
  │    git revert; the self-check it used to force now lives     │
  │    in the block above                                        │
  └──────────────────────────────────────────────────────────────┘
```

The principle: Fable's edge splits into **instructions** (text → portable) and
**weights** (reasoning depth → not portable). The hooks port the instructions and
keep them anchored; the weights gap you route around — send entangled reasoning and
long autonomous runs to real Fable, or compensate with fan-out + adversarial
verification.

## 📈 Watch the Overhead

Every injection is logged. `/fable-mode status` reports what the kit actually costs you:

```bash
$ /fable-mode status
GLOBAL marker: off · this session: auto-detected (claude-opus-4-8)
injections: full 4 × 1,636 chars · lite 11 × 234 chars
overhead ≈ 5,700 tokens this session (all-full, no adaptive lite, ≈ 15,300)
```

## 🛡️ Controls & Safety

| | |
|:---|:---|
| 🔴 `FABLE_MODE=0` | kill-switch — **beats every activation path** (use in cron/one-shots) |
| 🟢 `FABLE_MODE=1` | force on (what `claude-fablelike` exports) |
| 🔍 real Fable session | auto-detected from the transcript → hooks **stand down**, no double injection |
| 🔁 `/fable-mode on\|off\|status` | manual toggle + telemetry |
| ✅ self-check | pre-finish self-check rides the full block — in-context, invisible to the user, **no extra generation pass** |
| 🏷️ identity | asserts "you are Opus" **only when the session model is confirmed** (`FABLE_MODE=1`, or the transcript shows an Opus turn). An unconfirmed guess (settings.json at turn 1) gets a neutral identity line — never claims Opus on a session that might be Fable |

> [!IMPORTANT]
> v1.5 retired the Stop hook, so there's no longer an extra generation pass per major
> turn — the per-turn injection is the only overhead. Still `export FABLE_MODE=0` on
> timeout-budgeted headless runs to skip injection entirely.

<details>
<summary>📦 What gets installed (8 pieces)</summary>

| piece | file | role |
|---|---|---|
| SessionStart hook | `hooks/fable-detect.sh` | auto-detects Opus sessions → arms fable-mode (settings.json fallback arms neutrally — it's a guess) |
| UserPromptSubmit hook | `hooks/fable-context.sh` | re-injects conduct norms every turn — adaptive: full ~1.6k-char block (with the pre-finish self-check) on major turns / session start / every 5th turn, ~0.2k-char reminder on minor turns (−86%); logs every injection to `state/fable-mode/stats/` |
| SubagentStart hook | `hooks/fable-subagent.sh` | identity-neutral conduct block into every subagent at spawn |
| Stop hook | `hooks/fable-stop-verify.sh` | retired no-op stub (v1.5) — kept registered so a one-file git revert re-enables it; the self-check it forced now rides the per-turn block |
| output style | `output-styles/fable-like.md` | system-prompt-level port of the norms |
| skill | `skills/fable-mode/` | `/fable-mode on\|off\|status` manual toggle |
| wrapper | `bin/claude-fablelike` | one-shot: Opus + xhigh effort + output style + hooks |
| optional | `docs/conduct-snippet.md` | fallback for CLIs without SubagentStart; marked agents are auto-skipped (no double injection) |

</details>

## 🧪 Built by Diffing, Hardened by Self-Audit

- **The diff.** Headless probes of both models + CLI binary strings showed Fable 5 and
  Opus 4.8 run the *same harness* — same tools, same effort dial, same workflows. The
  difference that matters is a conduct section only Fable's system prompt carries.
  Instructions are text. Text is portable. Hence this kit.
- **The audit.** v1.5 shipped after an 11-agent fleet — running these very norms — audited
  the kit end to end: 29 findings, every major claim handed to an adversarial verifier told
  to refute it. Two "majors" died in verification, one got downgraded. The survivors were
  fixed and released the same day.
- **The best bug.** A real Fable 5 session briefly got injected with *"you are Opus."*
  It self-healed one turn later — and v1.5 makes it structurally impossible: the identity
  line is only asserted when the session model is confirmed, never on a guess.

## 📉 Honest Limits

- **97% is a conduct score**, not an intelligence benchmark. Sample: 4 task types ×
  1 run per condition (diagnosis + implementation re-measured 2026-07-07 on v1.4).
- The kit reaches the norms via correction turns (8 vs 4 turns on one task); Fable gets
  there on the first attempt. **You pay turns, not quality.**
- Entangled first-pass reasoning and long autonomous runs keep a real gap
  (~5–11 pt third-party benchmark estimate). Route those to Fable, or compensate with
  fan-out + adversarial verification (1–2.5× a single Fable run, estimate).

## 📑 Reports

Full measurement deck and a principles explainer (Korean, 13 + 14 slides, open in any browser):

- **[Measurements — v1.4 benchmark](https://jee599.github.io/reports/posts/fable-mode-v14-ir.html)** ([PDF](https://jee599.github.io/reports/posts/fable-mode-v14-ir.pdf))
- **[How it works — principles](https://jee599.github.io/reports/posts/fable-mode-principles-ir.html)** ([PDF](https://jee599.github.io/reports/posts/fable-mode-principles-ir.pdf))

## 🧹 Uninstall

```bash
./uninstall.sh          # classic install — removes files, deregisters hooks, deletes state
/plugin uninstall       # plugin route
```

## 📜 License

MIT

---

<p align="center">
  <b>⚡ 97% of the conduct at half the unit price — and it knows what it can't port.</b>
</p>

<p align="center">
  <a href="https://github.com/jee599/fable-mode-kit">
    <img src="https://img.shields.io/badge/GitHub-⭐_Star_this_repo-yellow?style=for-the-badge&logo=github" alt="Star" />
  </a>
</p>

<p align="center">
  <a href="https://star-history.com/#jee599/fable-mode-kit&Date">
    <img src="https://api.star-history.com/svg?repos=jee599/fable-mode-kit&type=Date" alt="Star History Chart" width="600" />
  </a>
</p>
