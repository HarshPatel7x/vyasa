# Plan — Migrate rule-loading from SessionStart hook to CLAUDE.md `@import`

> Workitem: "Migrate rule-loading from SessionStart hook to CLAUDE.md `@import`" (see [`../open.md`](../open.md)).
> Status: **planned, not yet built.** Satisfies the plan-before-build gate.
> Depends on: [`verify-claudemd-import.md`](verify-claudemd-import.md) (PASS — `@import` expands at launch, v2.1.156).

## Problem

`hooks/load-default-rules.sh` (a `SessionStart` hook wired in `.claude/settings.json`) concatenates
the six default-load shards and prints ~20KB to stdout. Claude Code caps hook-stdout injection at
**10,000 chars**; the excess is saved to a file and only a ~2KB preview reaches context. Net effect:
only ~1 of 6 shards actually loads. The loader is effectively broken for a load this size.

`@import` was verified to expand imported files in full at launch with no hard cap. This workitem
**replaces the hook with `@import`**, with one hard requirement.

## Hard requirement (non-negotiable)

After the swap, **the exact same six shards the hook loads today must load via `@import`**, in the
same order:

1. `rules/hygiene.md`
2. `rules/voice.md`
3. `rules/island.md`
4. `rules/workitems.md`
5. `rules/readme-convention.md`
6. `rules/git-workflow.md`

(These are the `## Default-load` entries in `rules/INDEX.md` — the hook's current source of truth.)
Parity is verified, not assumed (see Verification).

## Compaction behavior — DECISION REQUIRED (audit B3)

The current hook's matcher is `startup|resume|clear|compact`, and it re-emits the rules on a
`compact` event (with a "(refreshed post-compaction)" marker). So today the rules are **re-injected
after the conversation is summarized**. Plain `@import` expands **once at launch** and does not
re-fire on compaction. "Replace the hook with `@import`" is therefore **not full parity** unless we
address this.

Two competing facts, one of them unverified:
- **Likely-better view (UNVERIFIED):** `CLAUDE.md` + its `@import`s are *persistent project memory*,
  re-loaded into every context window — including the fresh window built after a compaction. Hook
  *stdout*, by contrast, is conversation-injected and gets summarized away, which is **why the hook
  needed a `compact` refresh in the first place.** If memory truly reloads each window, `@import` is
  strictly better and there is no regression. **This must be probed, not assumed (hygiene #1).**
- **Conservative view:** if memory does NOT reload post-compaction, dropping the hook is a silent
  rule-loss regression.

**Options:**
- **B3-a — pure `@import`, verify compaction.** Remove the hook entirely; before trusting it, run a
  test that forces/observes a compaction and confirms imported rules are still present in the new
  window. Cleanest end state; needs a compaction test.
  **Compaction-test method (important):** `claude -p` is one-shot and never compacts, so it CANNOT
  test this. The viable test is a **live interactive `/compact`**: (1) wire `@import` for real,
  (2) confirm all six load at launch, (3) remove the hook, (4) run `/compact` in a real session,
  (5) check whether the imported rules are still in context. No zero-loading window exists because
  `@import` covers launch before the hook is removed. If rules survive `/compact` → ship A. If not →
  add the B3-b compact-only hook.
- **B3-b — hybrid (belt-and-suspenders).** Use `@import` for launch loading AND keep a *minimal*
  SessionStart hook scoped to `compact` only, emitting a short "(rules in CLAUDE.md — re-read if
  needed)" pointer or a trimmed refresh. Guarantees parity even if memory doesn't reload; keeps a
  little of the hook complexity we wanted to delete.

**Decision: B3-a chosen (user, 2026-05-29).** Go pure `@import` + a compaction verification step;
fall back to B3-b only if compaction shows memory does not reload.

**Fallback mechanics (user asked "can we trigger a hook for @import?"):**
- A hook **cannot** make `@import` syntax expand — `@import` only expands inside memory files
  (CLAUDE.md + imports), not in hook stdout (hook stdout is injected as literal text). *To verify,
  not assert.*
- A hook **can** re-inject the rule *text* on `compact` (the current hook already does), BUT it hits
  the same **10K-char cap** — so a `compact`-refresh hook could only carry a trimmed core (e.g.
  `hygiene.md`) or a short "re-read CLAUDE.md" pointer, not all six shards.
- Therefore the real fallback = **B3-b hybrid**: `@import` does the full uncapped launch load; a
  minimal `compact`-only hook re-nudges with a small payload. Only needed if A's compaction test
  fails.

## Options for the wiring

| # | Approach | Source-of-truth | Verified? |
|---|----------|-----------------|-----------|
| A | **INDEX.md as loader** — `CLAUDE.md` has one line `@rules/INDEX.md`; INDEX.md's Default-load entries become `@`-import lines. Recursion (CLAUDE→INDEX→shard) pulls the shards. | Single (INDEX.md), matches the hook's design intent + D13 (INDEX is the router). | **No** — recursive import + relative-path resolution from inside INDEX.md both unverified. |
| B | **Explicit list in CLAUDE.md** — six `@rules/<shard>.md` lines directly in CLAUDE.md; INDEX.md stays prose. | Duplicated (CLAUDE.md list + INDEX.md prose) — drift risk; mitigate with a sync note. | **Yes** — single-hop `@import`, already proven. |

**Decision: A — VERIFIED & CHOSEN (2026-05-29, v2.1.156).** The Step 1 recursion probe passed:
CLAUDE.md → `@rules/INDEX.md` → `@_import-probe.md` (bare relative path resolved from inside
`rules/`) returned the sentinel token. Confounder ruled out — the hook's parser matches only
markdown-link syntax `](file.md)`, not bare `@...` lines, so it could not have emitted the probe.
So Option A works: `rules/INDEX.md` stays the single source of truth *and* does the loading. No
duplication. (Depth used: 2 hops, well under the docs' stated 4-hop limit — that limit itself is
assumed-from-docs, not independently verified, but irrelevant at depth 2.)

## Implementation steps

1. **Probe recursion (decides A vs B).** Put a sentinel token in `rules/_import-probe.md`; in
   `rules/INDEX.md` add a temporary `@_import-probe.md` line; in `CLAUDE.md` add `@rules/INDEX.md`.
   Run `claude -p` asking for the token. Token returned ⇒ recursion + relative paths work ⇒ choose A.
   Clean up the sentinel + temp lines regardless of outcome.
2. **Wire the chosen approach.**
   - **A:** In `CLAUDE.md`, replace the prose "read `rules/INDEX.md` and follow it" *load mechanism*
     with `@rules/INDEX.md` (keep a one-line human pointer too). In `rules/INDEX.md`, convert the six
     Default-load entries to `@<shard>.md` import lines (keep the human descriptions alongside as
     comments/prose so INDEX.md stays a readable router).
   - **B:** In `CLAUDE.md`, add the six explicit `@rules/<shard>.md` lines; add a sync note in both
     `CLAUDE.md` and `rules/INDEX.md` that the two lists must stay aligned.
3. **Remove the hook (LAST, only after Step 4 verifies parity).**
   - Delete the `SessionStart` entry from `.claude/settings.json` (if it's the only hook, leave a
     valid empty `{}` or remove the `hooks` key cleanly — verify the file still parses).
   - Delete `hooks/load-default-rules.sh`.
   - Update `hooks/README.md`: remove/redirect the section describing the Claude-Code SessionStart
     hook; the git hooks (`commit-msg`, `pre-commit`) stay untouched.
4. **Verify parity — ALL SIX (verify — do not assert).** Run a fresh `claude -p` probe asking for a
   unique token from **each of the six** shards, not just first+last. Rationale (per audit B2):
   Option A (recursion) can silently drop a *middle* shard via a mis-resolved relative path or a
   depth cutoff while the first and last still resolve — so first+last is not a proof. Ask the probe
   for an existing unique phrase from each shard (e.g. hygiene's "Aspirational ≠ Live", git-workflow's
   allowed `<type>` list, etc.). Pass = all six returned.
5. **Ledger.** Move the workitem from `open.md` to `done.md` (checked, with branch + plan link).
6. **Decisions log.** This changes *how rules load* — a structural decision. Append a **new `D18`**
   entry to `README.md` recording the hook→import switch and the 10K-cap rationale (per
   `rules/git-workflow.md`, the commit needs a `Touches: D18 — <title>` footer with `README.md`
   staged). **Corrected per audit (B1):** the decisions log ends at D17 and there is **no existing
   D-entry for the hook** — it was shipped but logged only in `plans/sessionstart-load-rules.md` +
   `done.md`. So D18 does **not** supersede a prior D-entry; it should note that the hook decision was
   never logged and this entry establishes the current mechanism. Annotate
   `plans/sessionstart-load-rules.md` as superseded, but **do not edit** the immutable `done.md` /
   `notes/` audit-trail entries (they record what happened).
7. **Pre-delete safety + git mechanics.** Before deleting `load-default-rules.sh`, run a working
   repo-wide grep for `load-default-rules` (the auditor's sandbox blocked this) to confirm no other
   consumer. Work on branch `workitem/migrate-hook-to-import`; ship via a PR using the full body
   template in `rules/git-workflow.md` (no direct commits to `main`).

## Risks / things the auditor should check

- **Recursion + relative-path assumption (A).** Unverified until Step 1; plan must not hard-commit to A.
- **Remove-before-verify gap.** Hook must be removed *after* parity is confirmed, never before, or
  there's a window with no rule-loading. Order in steps 3–4 enforces this.
- **Frontmatter.** Shards open with YAML frontmatter (`WHAT:`/`LOAD:`). The hook `cat`s them raw;
  `@import` also pulls raw file content — so frontmatter rides along either way. Confirm that's
  acceptable (it was, under the hook).
- **settings.json validity** after removing the only hook entry — must still be valid JSON.
- **INDEX.md dual role (A).** Making INDEX.md both human router *and* machine loader — confirm the
  `@`-import lines don't break its readability or its own parsing by anything else.
- **Other consumers of the hook.** Confirm nothing else references `load-default-rules.sh` before
  deleting it.
- **Stale docs.** `plans/sessionstart-load-rules.md` and the hook's `done.md` entry describe the hook
  as the chosen mechanism — should be annotated as superseded, not silently contradicted.

## Out of scope

- The `git-workflow.md` path-scoping optimization (separate workitem from the hook plan).
- Any change to the git hooks (`commit-msg`, `pre-commit`).

## Verification summary

Pass = a fresh session/probe has BOTH `hygiene.md` content AND `git-workflow.md` content in context,
the hook script + settings entry are gone, and `.claude/settings.json` still parses.
