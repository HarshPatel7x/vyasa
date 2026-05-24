# 2026-05-24 — Excluding vyasa from harsh-brain SessionStart + UserPromptSubmit hooks

**Session type:** infrastructure / config change + brief state read
**Duration:** short, single working session
**Outcome:** four hook commands in `~/.claude/settings.json` now cwd-guarded to skip silently inside vyasa

---

## Context — why this came up

Session started with four noisy reminders being injected into the conversation, all of which push the assistant toward harsh-brain integration that vyasa explicitly opts out of (rule **P2 — No harsh-brain wiring**):

1. `[BOOTSTRAP REMINDER]` — tells the assistant to read `/memories/session/`, last 3 `/memories/repo/`, `vasudev/plan.md` tail, `vasudev/log.md`, and `patterns.md` before any task.
2. `[CROSS-SKILL REMINDER]` — observer freshness check.
3. `[HIVE-BRAIN]` — recent digests printer.
4. `[PIPELINE GUARD]` — fires on `UserPromptSubmit`, ostensibly only for `/eklavya|/vasudev` prompts, but actually firing on every prompt in this session.

The user typed "flow" → asked the assistant to talk about the project, then asked: *"Can we exclude this project from the SessionStart hook?"*

---

## State-of-project read (delivered at top of session)

Read `README.md`, listed dirs, checked `git log`. Snapshot:
- **Fully designed**, **zero built.** One commit (`60fcbdf chore: initial project skeleton`).
- README has a 12-entry decisions log (D1–D12). CLAUDE.md is self-contained.
- `skills/`, `fixtures/`, `runs/`, `reports/decisions/` all empty. No `cli/` (deferred per D8).
- `notes/INDEX.md` only — no session notes yet.

**Risk flagged (not acted on this session):** the gravitational pull is toward "13th decision logged" rather than "first thing that actually runs." Pick a small skill, hand-write 3–5 fixtures, do the first comparison manually — let that pain define what the runner has to do. Chicken-and-egg cuts both ways.

---

## Options considered for the hook exclusion

**Option A — cwd guard prefix on each hook command.** Each hook command in `~/.claude/settings.json` gets prefixed with `[ "$PWD" = "/Users/harshpatel/Desktop/Harsh/vyasa" ] && exit 0;`. Surgical, vyasa-only, other projects unaffected.

**Option B — project-local `.claude/settings.json` override.** Rejected. Claude Code merges hooks across scopes *additively*; a child scope cannot subtract from the parent. Empty SessionStart in vyasa's settings would not remove the global ones.

**Option C — disable globally.** Rejected. Too broad — would kill the reminders for every harsh-brain project that legitimately wants them.

**Decision:** Option A.

---

## What landed

Four edits to `~/.claude/settings.json`, each prepending the cwd guard to the existing command:

| Hook                        | Line | Type              |
|-----------------------------|------|-------------------|
| `[BOOTSTRAP REMINDER]`      | 244  | SessionStart      |
| `[CROSS-SKILL REMINDER]`    | 253  | SessionStart      |
| `[HIVE-BRAIN]` digests      | 262  | SessionStart      |
| `[PIPELINE GUARD]`          | 273  | UserPromptSubmit  |

**Backup:** `~/.claude/settings.json.bak-20260524-173148` (full file, pre-edit).

**Validation:**
- JSON parses cleanly post-edit (`python3 -c "import json; json.load(...)"`).
- Behavior test in vyasa: silent. Behavior test in `/tmp`: reminder text printed.

---

## Side observation worth recording

The `[PIPELINE GUARD]` hook has matcher `"/eklavya|/vasudev"`, which should restrict it to prompts containing those slash commands. **It fired on every user prompt in this session anyway.** Not investigated — could be (a) matcher applies more loosely than expected, (b) a different hook with same body, (c) some Claude Code behavior around matcher semantics for `UserPromptSubmit`. Flagged here as a known oddity. The cwd guard sidesteps the question entirely for vyasa; the broader behavior remains unverified.

---

## Caveats / known limits

1. **Changes take effect next session.** This conversation already has the reminders injected at session start — they stay in this context window. Verify clean startup by opening a fresh session in vyasa.
2. **The guard is a literal string match on `$PWD`.** If the user works inside a subdirectory of vyasa (e.g., `vyasa/skills/`), the guard will NOT match and the reminders will fire. If that becomes annoying, change to a prefix match: `case "$PWD" in /Users/harshpatel/Desktop/Harsh/vyasa*) exit 0;; esac`.
3. **Project portability impact: zero.** All changes are in the user's global `~/.claude/settings.json`, not in the vyasa repo. Per P2, that's where they belong — vyasa stays an island.

---

## Decisions recap

| # | Decision                                                                                   |
|---|---------------------------------------------------------------------------------------------|
| 1 | Suppress all four harsh-brain reminders inside vyasa via cwd-guard prefix on each command. |
| 2 | Backup `~/.claude/settings.json` before edit (`.bak-<timestamp>`).                          |
| 3 | Validate JSON + behavior test after each batch of edits.                                    |
| 4 | Do NOT investigate why `PIPELINE GUARD`'s matcher fired outside its declared regex scope.   |
| 5 | Do NOT update vyasa's `README.md` decisions log — this change is in global config, not project structure. |

---

## Not done this session (deliberately deferred)

- **First runnable thing in vyasa.** Still skeleton-only. No `cli/`, no fixtures, no first comparison report.
- **PIPELINE GUARD matcher investigation.** Filed as side observation; not chased.
- **Subdirectory-prefix guard.** Current guard is exact-match on vyasa root only.
