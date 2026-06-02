# 2026-06-02 — README-as-router: the build session

> Session type: build (executed the signed-off plan from the companion planning note).
> Outcome: shipped the README-as-router change as PR #19, squash-merged to `main` as commit `6192cd7`.
> `INDEX.md` retired (one `README.md` filename everywhere), the root README sharded into `docs/`, the
> Decisions log relocated to `docs/decisions.md`, and the `Touches: D<N>` enforcement re-pointed to it.
> Logged `D22 — README-as-router: retire INDEX.md, shard root README into docs/`.

---

## What got built

Ten commits on `workitem/readme-router-convention`, following the plan's commit choreography, plus two
it didn't foresee (a deferred planning note that had to ship here, and a review-fix commit) — collapsed
by squash into the single `main` commit `6192cd7`. The change was verified end to end: the re-pointed
commit-message hook (driven directly, live on a real commit, and on GitHub CI for every commit),
decisions-log byte-fidelity, link/structure integrity, a five-dimension adversarial review, and — in a
separate fresh session — the live launch-load probe.

## Lessons (the point of this note)

**1. A signed-off plan is not a finished plan — the build is a third review pass.** The plan had been
hardened through two rounds of three agents, yet building it surfaced three more gaps the reviews
missed: (a) the plan's own suggested subject for the decision-logging commit (`log D22 and …`) would
have failed the very hook it was logging — a bare `D22` not followed by an em-dash trips the inline
D-code rule; (b) two stale "decisions live in the README" pointers in `voice.md` the change-list never
enumerated; (c) a hook comment (`# README.md must be among the files…`) the repoint's line-list
skipped. Catching these needed reading the real files, not trusting the plan's line numbers — exactly
what the project's "never assert from documentation alone" rule is for.

**2. Guard every shell command against `set -e`.** The sandbox shell aborts the whole script on any
non-zero exit. A `grep -c` that finds nothing returns 1 and silently killed multi-step verification
blocks mid-run — and once made a `git add` at the end of a block never execute, so a commit that
looked staged staged nothing. The habit that fixed it: append `|| true` to greps and diffs, and put
`git add` *before* any grep in the same block.

**3. Relocate verbatim by extraction, not retyping.** The Decisions log moved to `docs/decisions.md`
by line-range extraction from the source plus a diff back against it — so the integrity check could
*prove* the only changes were the four intended annotations, nothing lost or reordered (the deliberate
out-of-numeric-order placement of two early decisions survived untouched).

**4. The chicken-and-egg choreography held.** Re-pointing the hook and creating `docs/decisions.md`
came first (commit 1a); logging the new decision came last (commit 5). That ordering is what let the
`Touches:` footer validate against the already-relocated, already-re-pointed file — confirmed by the
hook passing live on that commit and the CI re-validating every commit in commit-tree mode.

**5. The adversarial review earned its keep on a load-bearing change.** Five parallel reviewers plus a
verify pass produced zero surviving false alarms, but did catch two genuinely stale comments the
repoint missed and a readability snag in the new rule text ("one of two shapes" leading into three
bullets). Cheap to fix, and exactly the kind of thing a human skims past on a 300-line diff.

**6. Some checks only a fresh session can run.** The `@import` rename can't be verified mid-session —
Claude Code snapshots its config at startup and never hot-reloads. So launch-load was deferred to a
new session, which then loaded all six rule shards from context *including the rewritten
`readme-convention.md`* — proving the renamed `rules/README.md` chain pulled the updated shard, not a
stale copy. That is the difference between "the wiring looks right" and "the wiring works."

## Loose end queued

The review surfaced a pre-existing hook quirk: a `Touches:` footer citing an unknown `D<N>` is rejected
fail-closed but with an *empty* error message, because `set -e` trips the `grep` in the
title-extraction. Out of scope for this change; logged in `workitems/open.md` for a future pass.
