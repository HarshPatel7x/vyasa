# Plan — Reinforce the plain-English rule (`rules/voice.md`)

> Workitem (from `workitems/open.md`): "Reinforce the plain-English rule (`rules/voice.md`). The rule
> loads every session but drifted under long technical work (2026-05-31 session). Add three low-cost
> reinforcements: (1) a one-word `plain` interrupt the user can fire anytime; (2) a before-sending
> self-check step; (3) a small reusable glossary. No automated enforcement."

Status: **planned (rev 2, one architect audit folded in), awaiting build sign-off.** Plan-before-build
gate per `rules/workitems.md`.

---

## Problem

`rules/voice.md` (plain-English default) is a default-load rule — it loads into context every session,
and did this session too. It still drifted: during long technical work (hook audits, diffs) the prose
filled with unglossed jargon until the user said their head hurt. So the failure is **adherence under
load, not loading**. The one part that held all session was the end-of-response recap — a fixed ritual
at a fixed spot. The free-flowing prose is where discipline slipped.

## Decision (user, 2026-05-31): do all three

Lean on *triggers and friction-reduction*, not more exhortation, and NOT on automated enforcement
**for v1**. Honest framing of the automation question (sharpened by the rev-1 review):
- A **general** "is this prose plain enough" script is genuinely infeasible — a semantic,
  audience-relative judgment, not regex-checkable.
- A **narrow** script (flag listed glossary terms used without their gloss nearby) is feasible *in
  principle* but (a) high-false-positive, because `rules/voice.md` itself exempts code, file paths,
  and commands — exactly where these terms legitimately appear unglossed — and (b) gated on an
  **unverified** fact: whether a hook in this harness can even see the assistant's outgoing message.
- The narrow script was **considered and dropped** (user decision, 2026-05-31): the false-alarm
  floor (terms legitimately appear unglossed in code/paths/commands) plus the unverified
  hook-visibility made it not worth pursuing. Plain English stays human-run. Hooks are also
  costly/finicky here (see `D18 — Rule-loading moves from SessionStart hook to CLAUDE.md @import`).

## Proposed `rules/voice.md` additions (exact wording — approve before edit)

### Addition A — Plain interrupt (new subsection after "Dummy-language as default")
```markdown
## The `plain` interrupt

The user can type **`plain`** (or "plain please") at any moment. On seeing it, immediately stop,
drop all jargon, and re-explain the most recent thing in plain words — no file paths, no tool names,
no rule codes. If the most recent thing was already plain, say so briefly and move on — no forced
re-explanation. It is the conversational equivalent of the recap, available on demand. Distinct from
"quiet mode" (which *suppresses* the recap); `plain` *triggers* a plain re-explanation.
```

### Addition B — Before-sending self-check (new subsection after the recap section)
```markdown
## Before-sending self-check

Before sending any non-trivial or technical response, do one pass over your own draft and ask:
"would a smart non-specialist stall on any word here?" Gloss each such term on first use, or cut it.
This is a fixed checkpoint — like the end-of-response recap — not an aspiration. The recap is a fixed
checkpoint and held all through the 2026-05-31 session; this gives the body prose the same kind of
anchor.
```

### Addition C — Recurring-terms glossary (new subsection at the end of the file)
```markdown
## Recurring-terms glossary (gloss source)

Ready-made plain glosses for terms that recur in this project, so glossing-on-first-use has no
friction. Use the gloss the first time a term appears in a session, then the bare term after.

| Term            | Plain gloss (first-use) |
|-----------------|--------------------------|
| hook            | a script the system runs automatically at a set moment |
| branch          | a separate copy of the project's files to work on safely |
| commit          | a saved snapshot of changes, with a note on what/why |
| PR (pull request)| a request to fold a branch's changes into the main copy |
| merge           | combining a branch's changes into the main copy |
| snapshot        | a quick copy of a file's contents at one moment |
| context window  | the limited amount the assistant can "hold in mind" at once |
| subagent        | a separate helper assistant spawned for one task |
| shard           | one small rule file (the rules are split into several) |
| @import         | a line that pulls another file's contents in automatically |

**Graduation trigger (kept unambiguous — this project forbids fuzzy triggers):** when this table
exceeds ~20 rows, OR stops being "recurring terms" and turns into a general dictionary, move it OUT
of this always-loaded rule into an on-demand `rules/glossary.md` that this rule points at. Reference
data should not ride in a default-load shard, which pays its context cost every session. Until that
threshold, it lives here.
```

## Implementation steps

1. Confirm branch `workitem/voice-rule-reinforcement` exists (`git branch`) — don't trust this doc.
2. Apply Additions A, B, C to `rules/voice.md` verbatim (above), placed as noted. **Reconcile the
   duplicate `hook` gloss:** `voice.md`'s existing "Dummy-language as default" example (~line 14)
   already glosses `hook`; point that example at the new glossary table so there is ONE canonical
   wording, not two that can drift.
3. No D-entry needed now: this refines an existing rule, not a structural decision (no new domain, no
   change to how rules load). Confirm at build that the `readme-decisions-log.md` trigger does NOT
   fire. **One FUTURE condition that *would* warrant a D-entry (flagged so it isn't forgotten):** if
   the glossary graduates to its own `rules/glossary.md` (that's a `D13 — Shardable-domain pattern:
   folder + INDEX.md routing` move). (The script-enforcement path was dropped, so it is no longer a
   pending condition.)
4. Commit on the branch (`docs(rules): ...`), per `rules/git-workflow.md`. No bare D-codes in the
   message (any `D18`/`D13` mention needs its ` — <title>` em-dash expansion or `commit-msg` fails).
5. Move the workitem `open.md` → `done.md`; open PR.
6. **Script idea: dropped** (user decision, 2026-05-31) — NOT filed as a workitem. The general
   plainness-check is infeasible; the narrow glossary-term script's false-alarm floor plus the
   unverified hook-visibility made it not worth pursuing. Recorded here for the audit trail; plain
   English stays human-run, with the `plain` interrupt + the before-sending self-check as the levers.

## Verification

- **Self-applies from 2026-05-31:** the rule text is the deliverable; once merged it loads every
  session like the other shards.
- **Sanity check at build:** re-read `rules/voice.md` end-to-end to confirm the three additions read
  coherently with the existing "Dummy-language as default", recap, and "Inline expansion of decision
  codes" sections — no contradiction or duplication.
- **No regression:** the existing recap rule and "quiet mode" still stand; `plain` is additive and
  explicitly contrasted with "quiet mode" so they aren't confused.

## Out of scope

- Automated/hook enforcement of prose plainness. The *general* version is infeasible; the *narrow*
  version (glossary-term scan) was considered and dropped (see step 6) — plain English stays
  human-run.
- Lifting `rules/voice.md` to global scope (it is project-only; revisit separately if ever wanted).
