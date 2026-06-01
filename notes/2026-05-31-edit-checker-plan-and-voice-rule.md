# Session notes — 2026-05-31 — Edit-checker plan (3 audits) + plain-English rule reinforced

> Style: meeting minutes. Two threads from one continuous session, linked by a live lesson: while
> *planning* the edit-checker, the assistant drifted badly into jargon — which became the reason to
> *harden the plain-English rule* in the same session. (The session's third thread, the live
> `/compact` test, has its own note: `2026-05-31-compaction-test-verdict.md`.)

## Thread 1 — Edit-checker (diff-verification) hook: planned, 3 audits, NOT built

**Goal:** a hook pair that shows the true per-edit change to a file, so a hallucinated "I edited X"
claim is caught — independent of the model's own narration.

**The arc (each audit moved the design):**
- **Rev 1 (git-diff):** first design diffed the file with `git diff`. **Architect audit found a
  BLOCKING flaw:** `git diff <file>` shows the *cumulative uncommitted* delta vs the last commit, not
  *this one edit's* delta — so mid-session it is almost never empty and the headline "claimed an
  edit, disk shows nothing" case slips through. The mechanism contradicted the promise.
- **Rev 2 (snapshot pair, user decision):** reworked to **PreToolUse-snapshot + PostToolUse-compare**
  — copy the file's bytes *before* the edit, diff against *after*. True per-edit delta; also covers
  non-git / git-ignored files for free. Second audit (APPROVE WITH CHANGES) surfaced nine refinements
  (collision-keying for same-file-twice, fail-open under `set -e`, `.meta` as authoritative gate,
  oversize guard, factual not-accusatory no-change wording, etc.).
- **Rev 3/4 (final):** folded all nine in; a third audit confirmed the D19 commit-footer would pass
  `commit-msg` and added five more tightenings (all folded). Verdict: buildable.

**State:** plan saved on branch `workitem/diff-verification-hook` (commit `2aa1714`), pushed,
**left unmerged** so the build continues there in a fresh session. No hook code, no settings change.
Build is deferred — it's a multi-file job. Plan: `plans/diff-verification-hook.md`.

**Key build-time unknowns the plan front-loads (hygiene #1 — verify, don't assume):** exact hook
stdin field names, whether a per-call id exists (for collision-keying), the real output-injection
keys + size cap for Pre/PostToolUse, `$CLAUDE_PROJECT_DIR`, `MultiEdit`/`NotebookEdit` existence,
and the collaborator auto-run-approval behavior.

## Thread 2 — Plain-English rule reinforced (built + merged, PR #7)

**Trigger:** mid-session the user said the responses were giving them a headache — the prose had
drifted into heavy jargon (PostToolUse, re-entrancy, snapshot pair…) **with the plain-English rule
loaded the whole time.** So the failure was *adherence under load, not loading*.

**Diagnosis that shaped the fix:** the one part that held all session was the end-of-response recap —
a fixed ritual at a fixed spot. Free-flowing body prose is where discipline slipped. So the fix
leans on *triggers and fixed checkpoints*, not more exhortation.

**Shipped to `rules/voice.md` (one architect audit folded in):**
1. **`plain` interrupt** — user types `plain` for an instant jargon-free re-explanation (contrasted
   with "quiet mode", which *suppresses* the recap; `plain` *triggers* a re-explanation).
2. **Before-sending self-check** — scan the body prose for unglossed jargon before sending, anchored
   like the recap.
3. **Recurring-terms glossary** (10 rows) with a **named graduation trigger** (~20 rows → move to an
   on-demand `rules/glossary.md`), so a default-load rule has no unbounded per-session context cost.

**Script enforcement — considered and DROPPED (user decision):** a *general* "is this plain enough"
checker is infeasible (semantic judgment); a *narrow* glossary-term scanner is feasible in principle
but cries wolf on terms inside code/paths/commands (which the rule exempts) AND is gated on an
unverified fact — whether a hook can even see the assistant's outgoing message. Not worth it; not
filed. Plain English stays human-run.

**No D-entry:** refines an existing rule, not a structural change. (Future D-entry only if the
glossary graduates to its own file.) Branch `workitem/voice-rule-reinforcement` → PR #7 → **merged**.
Plan: `plans/voice-rule-reinforcement.md`.

## Cross-cutting learnings

- **A loaded rule is not an obeyed rule.** The plain-English rule loaded every session (proven by the
  compaction test the same day) and still drifted. Loading ≠ adherence; the lever is active handles
  (interrupt, checkpoint), not louder text.
- **Fixed-position rituals hold; free-prose intentions drift.** The recap survived; the body didn't.
  Reinforcements that mimic the recap's fixed-checkpoint shape are the ones likely to stick.
- **Audits earn their cost.** Three independent passes on the edit-checker plan caught a blocking
  mechanism/promise contradiction, fourteen-plus refinements, and a commit-hook footer landmine —
  none cheap to discover at build time.
- **"Infeasible" was an over-claim.** The script question wasn't "impossible" but "general-impossible,
  narrow-risky-and-unproven." Naming the honest distinction beat defending the original blanket call.

## State at close

- `main` clean and synced. Today merged **PR #6** (compaction caveat closed) and **PR #7**
  (plain-English rule). Branch cleanup done earlier (single `main` + the parked build branch).
- One branch parked by design: `workitem/diff-verification-hook` (edit-checker plan, unmerged,
  awaiting a fresh-session build).
- `done.md` updated for both the compaction caveat and the voice-rule item; `open.md` still holds
  the diff-verification hook (now with a plan), PR-side CI enforcement, README-convention tweak, and
  token-usage logging.

## Next session

- Build the edit-checker from `plans/diff-verification-hook.md`, starting on the parked branch.
  Step 1 of that plan: capture one real hook payload to resolve all the build-verify unknowns before
  writing logic.
