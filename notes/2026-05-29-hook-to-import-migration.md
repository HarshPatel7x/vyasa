# Session notes — 2026-05-29 — Hook → `@import` rule-loading migration (verified + planned)

> Style: meeting minutes. What we found, decided, and deferred. No production change shipped — this
> session was verification + planning only. The broken hook is still installed.

## Starting question

"Do we have the SessionStart rules-load hook set up, and is it working?"

## What we found (the core discovery)

The hook **runs** but is **mostly defeated** by a size cap:

- `hooks/load-default-rules.sh` concatenates the six default-load shards and prints **~20KB
  (20,237 bytes)** to stdout.
- Claude Code caps hook stdout injected into context at **10,000 chars** (documented). Excess is
  saved to a file on disk; only a preview reaches context.
- Net effect this session: only ~1 of 6 shards (`hygiene.md`, partially) actually loaded. The other
  five sat in a `tool-results/hook-*.txt` file, unloaded.
- So "the hook works" was half-true: it executes and exits 0, but its purpose — getting the rules in
  front of the model — fails for a load this size.

Correction logged mid-session: SessionStart stdout *is* added to context (unlike most hook events),
which is why the preview appeared at all — the failure is the 10K cap, not a stdout-doesn't-load
issue.

## What we verified (tools, not docs — hygiene #1)

Test vehicle: headless `claude -p` with a unique sentinel token, confounder controlled.

1. **Single-hop `@import` works.** `@rules/<file>` in CLAUDE.md expands at launch; a fresh instance
   returned the token. (Workitem: `verify-claudemd-import`, branch + plan, moved to `done.md`.)
2. **Recursive `@import` works.** CLAUDE.md → `@rules/INDEX.md` → `@_import-probe.md` (bare relative
   path resolved from inside `rules/`) returned the token. Confounder ruled out: the hook's parser
   matches only markdown-link syntax `](file.md)`, not bare `@...` lines, so it could not have
   emitted the probe.

Both probes cleaned up — no residue.

## Decisions

- **Option A for wiring (locked).** Because recursion works, `rules/INDEX.md` stays the **single
  source of truth** *and* does the loading (CLAUDE.md imports INDEX; INDEX imports the six shards).
  No list duplication — which was the original reason the hook was picked over `@import`. That reason
  is now gone.
- **Pure `@import` (B3-a) for compaction.** Remove the hook entirely; fallback = a minimal
  `compact`-only hybrid hook only if the compaction test fails.
- **Migration deferred to a fresh session.** Context was mid-to-late; the build is a large
  multi-file change. Plan is self-contained for cold execution.

## Architect-agent audit of the migration plan (3 catches)

Ran the `architect` subagent to audit `plans/migrate-hook-to-import.md` before any build. Verdict:
APPROVE WITH CHANGES. All folded into the plan:

1. **No existing hook D-entry.** The plan assumed it would "supersede" a hook D-entry; the decisions
   log ends at D17 and the hook was never logged there (only in its plan + `done.md`). Fix: write a
   fresh **D18**, don't reference a missing one.
2. **First+last shard check is not a proof.** Recursion can drop a *middle* shard via a bad relative
   path or depth cutoff while first/last still resolve. Fix: verify **all six**.
3. **Post-compaction reload regression (the important one).** The hook re-fires on `compact`;
   `@import` loads once at launch. "Replace hook with @import" is not full parity unless this is
   handled.

## Learnings

- **`claude -p` cannot test compaction** — it is one-shot and never compacts. The only real test is a
  **live interactive `/compact`**: wire @import → confirm all six load → remove hook → user runs
  `/compact` → check survival. No zero-loading window because @import covers launch first.
- **A hook cannot "trigger @import."** `@import` expands only inside memory files, not in hook
  stdout (hook output is injected literally). A hook *can* re-inject rule text on `compact`, but it
  hits the same 10K cap — so a fallback refresh hook could carry only a trimmed core or a pointer,
  not all six shards. (The expansion-in-hook-output claim is from design reasoning — verify on build.)
- **Strong hunch (unverified):** CLAUDE.md + its imports are persistent memory reloaded into every
  context window, including post-compaction — which is *why* the hook needed a `compact` refresh and
  @import may not. To be settled by the live `/compact` test, not asserted.

## State at close

- Branches (both unmerged): `workitem/verify-claudemd-import` (`8be74d2`) and
  `workitem/migrate-hook-to-import` (`029c420`, cut from the verify branch → contains both commits).
  **Start the build from the migration branch.**
- `open.md`: migration workitem queued (now has a plan). `done.md`: verify workitem closed.
- Plans: `verify-claudemd-import.md` (PASS), `migrate-hook-to-import.md` (audited, ready to build).
- **Nothing live changed.** The broken hook + its `.claude/settings.json` entry are untouched.

## Next session — build checklist (from the plan)

1. Wire @import (Option A): `@rules/INDEX.md` in CLAUDE.md; convert INDEX's six Default-load entries
   to `@`-imports (keep human descriptions).
2. Probe all six load at launch.
3. Grep for stray `load-default-rules` refs, then remove hook (script + settings entry + hooks/README
   section). Git hooks `commit-msg`/`pre-commit` stay untouched.
4. Live `/compact` test → ship pure @import, or add the compact-only fallback hook.
5. Write D18 (with `Touches:` footer + README staged), move workitem to `done.md`, open PR(s).
6. Decide whether to merge the verify branch first.
