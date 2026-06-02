# 2026-06-02 — README-as-router convention: decision + twice-reviewed plan

> Session type: decision + plan (no build — build handed to a fresh session).
> Outcome: a signed-off plan at `workitems/plans/readme-router-convention.md` to retire `INDEX.md`,
> make every directory carry one `README.md`, and shard the root README into `docs/`.
> **Index entry deferred:** this note is intentionally NOT yet listed in the notes router, because the
> build is renaming `notes/INDEX.md` → `notes/README.md` in the same window — add the entry there
> after the build merges, to avoid a rename/modify conflict.

---

## How it started vs. where it landed

It opened as the smallest item in `workitems/open.md`: "tweak `rules/readme-convention.md`." The rule
said *every* directory carries a `README.md`, but four folders (`rules/`, `notes/`, `workitems/`,
`workitems/plans/`) carry an `INDEX.md` instead — a known contradiction flagged back in
`D17 — Workitems become a folder; open/done split; plan-before-build gate`.

The turning point was a question from the user: not "should we do this tweak" but **"does this sound
like a system I could apply to every project?"** That reframed the whole thing. We pulled the idea
apart into three layers:

- The **broad principle** ("every directory is self-documenting") — portable, worth lifting everywhere.
- The **README-vs-INDEX split** — partly vyasa-specific, because `INDEX.md` here doubles as the
  `@import` load mechanism, which only matters in a rules-management project.
- **This particular tweak** — just a patch, not a reusable system.

## The decisions made

1. **Option A — one filename everywhere (`README.md`), retire `INDEX.md`.** Decisive reason: GitHub
   and most IDEs auto-render `README.md` in a folder view but **not** `INDEX.md`. So the four INDEX
   folders were silently losing the exact "renders automatically" affordance the README rule was built
   to provide. One filename also travels to any project; the INDEX router was the part that wouldn't.

2. **A README is thin: identity + router.** Substantial prose lives in shards the README points to.
   Applying that to the 304-line root README forces the long-planned `docs/` sharding (the recipe in
   `D13 — Shardable-domain pattern: folder + INDEX.md routing`), executed *with modifications* (README
   routers instead of INDEX; a single `docs/decisions.md` instead of 21 per-decision files).

3. **The Decisions log moves to `docs/decisions.md`.** The user caught the key point: the decisions log
   is the *only* monotonically-growing section (append-only, never deleted), so leaving it in the
   README just re-creates the bloat the change exists to prevent. Isolating the growing thing is the
   highest-value move — worth the one-time cost of re-pointing the enforcement hook.

4. **The convention is a leaf / routing / mixed trichotomy** (added for portability): routing dirs get
   a thin router README; leaf dirs (holding artifacts, e.g. `hooks/`, `.github/`) keep narrative
   inline; a mixed dir routes. Plus a "would a reader ever open this file alone?" anti-sprawl test —
   the user's explicit "no dumpster" guard.

## The method (worth remembering)

The plan was hardened through **two rounds of three parallel agents** (critique / improve / audit):

- **Round 1** found the real blocker: moving the decisions log out of `README.md` silently breaks the
  `Touches: D<N>` check in `hooks/commit-msg` (and the CI that reuses it) — the very commit that would
  record the change couldn't pass its own hook. The v1 plan had punted this to "review must flag"; all
  three agents correctly called that a TODO, not a fix.
- **Round 2** was accuracy: a miscounted edit list (7 hardcoded `README.md` refs in the hook, not 3),
  two stale files a grep-sweep would miss (`.github/README.md` + `hooks/README.md` both describe the
  *old* enforcement location), a link the plan chased in `done.md` that doesn't exist, and a
  verification step that couldn't pass as written. Plus three adopted improvements: the
  mixed-directory tie-breaker, splitting the risky commit, and a pure-verbatim decisions move.

Lesson reinforced: the multi-agent review earns its keep on a genuinely complex change (here, touching
enforcement code + the bible + every router file), but is overkill for a one-paragraph tweak — which
is what the task looked like before the reframing grew it.

## Status at session end

- Plan: `workitems/plans/readme-router-convention.md` — **v3, build-ready, signed off.** Not yet
  committed (it can't go on `main`; it ships on the build branch).
- Build: handed to a fresh session on branch `workitem/readme-router-convention` (7-commit sequence in
  the plan).
- **Open follow-up:** the `@import` rename can only be verified in a *second* fresh session after the
  build merges (Claude Code snapshots config at startup — no hot-reload).
- `workitems/open.md` still shows this item as `(no plan)`; the build links the plan and moves the item
  to `done.md` with the honest note that the original 2026-05-28 scoping (keep `INDEX.md`) was reversed.
