# Session notes — 2026-05-31 — Compaction test: D18 `@import` caveat closed

> Style: meeting minutes. This session ran the one deferred test that the hook→`@import`
> migration could never run headlessly: a **live `/compact`**. It closes the last open caveat
> on D18 — Rule-loading moves from SessionStart hook to CLAUDE.md @import.

## Where we picked up (carried from the past)

Two prior sessions set this up:

- **2026-05-29 — hook→`@import` migration (verified + planned).** Found the `SessionStart`
  rules-hook was mostly defeated by Claude Code's ~10K hook-stdout cap (only ~1 of 6 shards
  loaded). Verified single-hop AND recursive `@import` work, locked Option A (`rules/INDEX.md`
  stays single source of truth AND does the loading). Left **one open caveat**: the hook re-fired
  on `compact` to re-inject rules; `@import` loads once at launch, and `claude -p` can't compact —
  so post-compaction survival was a **strong hunch, explicitly unverified** (that note, lines
  74–76). Fallback if it failed: a `compact`-only nudge hook (plan option B3-b).
- The migration itself then **shipped** (branch `workitem/migrate-hook-to-import`, commit
  `e3dfdb7`): hook deleted, `.claude/settings.json` now `{}`, `CLAUDE.md` → `@rules/INDEX.md` →
  six per-shard `@import` lines. Everything green **except** the compaction question.

This session's whole job: settle that one question with a live test.

## The test protocol (and why it was strict)

Goal: prove the `@import`'d rules are present after `/compact`, with zero contamination.

- **Fresh session required.** A brand-new session boots the *shipped* state (empty `settings.json`,
  no hook, `@import` `CLAUDE.md`) — the exact thing under test. The planning session could not be
  the test bed: it already contained the migration conversation, and the protocol text itself
  quoted all three answer keys, so any probe there would be a guaranteed false pass.
- **vyasa-specific probe tokens**, chosen to avoid global-config bleed-through (hygiene/voice are
  mirrored in `~/.claude/CLAUDE.md`, so they'd show even if a shard didn't reload):
  - git-workflow commit-type whitelist → `feat, fix, docs, refactor, chore, test, eval`
  - workitems plan-path token → `workitems/plans/<slug>.md`
  - readme-convention keyword → `discoverability`
- **No file reads during a probe** — the point is answering from preloaded context.
- **Buffer turns with zero rule-talk before `/compact`**, so the summary has neutral material and
  no probe token leaks into it.

## What happened (observed, not assumed — hygiene #1)

1. **Baseline probe (pre-compact):** fresh session returned the whitelist + plan-path verbatim.
   → launch-load via `@import` confirmed working in a real interactive session (not just `claude -p`).
2. **`/compact` ran**, then the post-compact probe returned **all three** tokens correctly,
   including `discoverability`.
3. **The decisive detail:** the `/compact` step itself listed `Read rules/*.md` entries
   (git-workflow, readme-convention, workitems, island, voice…) nested under it — Claude Code
   **auto-re-reads the `@import`'d shard files while rebuilding the post-compaction context.**

## Verdict

- **Operational question — answered YES.** Imported rules are present after `/compact`. The
  2026-05-29 "strong hunch (unverified)" — that CLAUDE.md + its imports reload into every context
  window including the post-compaction one — is now **confirmed** for the `/compact` path.
- **Mechanism:** reload happens **by re-import** (the harness re-reads the shard files), not merely
  by the rules surviving inside the compacted summary.
- **B3-b fallback hook: not needed, not built.** The failure mode it insured against (rules
  silently absent after compaction) does not occur.

## Honest limitation (recorded, not hidden)

The strict "answer purely from the surviving summary, zero file reads" probe **could not be
isolated**, because `/compact` reads the shard files itself. So "did the summary *alone* carry the
rules?" stays untested. It's **moot**: the auto re-import makes the rules present either way, which
is the outcome that matters. Logged this way in D18 rather than claiming a cleaner result than we
have.

## What changed this session

- `README.md` D18: the **"Compaction (open caveat)"** paragraph → **"Compaction (resolved
  2026-05-31 — live test)"** with the mechanism + the honest limitation.
- `workitems/done.md` (migration entry): the "post-`/compact` reload not live-tested" clause →
  **"Compaction caveat closed (2026-05-31)"**.
- This note + its `INDEX.md` entry.

## State at close

- Branch `workitem/migrate-hook-to-import` (current). Doc edits staged-or-unstaged per the commit
  decision below; **no code/config changed** this session — the migration was already live.
- No new `open.md` items. The compaction test was the existing caveat, not a separate workitem, so
  it closes in place on the migration's `done.md` entry.
- Pending: an optional `docs(readme)` commit carrying the D18 edit (needs the
  `Touches: D18 — Rule-loading moves from SessionStart hook to CLAUDE.md @import` footer + README
  staged, per the commit hook).
