# Session note — CLAUDE.md load research + workitems folder restructure

**Date:** 2026-05-28
**Shape:** research → decision → build → audit → ship (PR #2)

---

## 1. What this session covered

Started as "make CLAUDE.md the first focus," sub-question 1: **monolith vs modular**.
Ended with a researched answer, a structural decision (`D17`), a shipped folder
restructure, and an independent audit of that build.

## 2. Research — how Claude Code actually loads CLAUDE.md

Verified against the official docs (`code.claude.com/docs/en/memory`), not asserted:

- `CLAUDE.md` auto-loads in full at session start, but is delivered as a *user message* —
  "no guarantee of strict compliance." Aspirational ≠ enforced.
- `@path` imports **load eagerly at launch** (max depth 4 hops) — but help organization
  only, *not* token cost (imported files still enter context).
- `.claude/rules/` is the real lever: files with `paths:` frontmatter are **path-scoped**
  (load only when Claude touches matching files); without it, they load every session.
- Size guidance: keep a CLAUDE.md under ~200 lines; longer reduces adherence.

**Empirical proof of the gap:** this session started with `CLAUDE.md` in context but *none*
of the six default-load shards — they had to be read manually. So vyasa's "read these every
session" read-chain is compliance-based and did **not** fire automatically.

## 3. The decision — keep modular, fix the load with a hook

The monolith-vs-modular question reframed into 3 options (monolith / native-modular via
`@import`+rules-dir / current prose read-chain). vyasa runs the weakest (prose read-chain).
User's call: **keep modular**, and close the load gap with a SessionStart hook (the existing
queued workitem) rather than `@import`. Reason that tips it to a hook: the hook reads the
default-load list from `rules/INDEX.md`, so `INDEX.md` stays the **single source of truth** —
no second import list to drift. Verified bonus: SessionStart hooks re-run on
`startup/resume/clear/compact`, so the load survives compaction.

## 4. What got built — workitems become a folder (`D17`)

Two moves, bundled, agreed in-conversation:

1. `WORKITEMS.md` (root file) → `workitems/` folder: `open.md` (live queue), `done.md`
   (archive, never auto-loaded), `plans/` (one plan per item, on-demand), `INDEX.md` (router).
   Follows the folder-per-domain pattern from `D13 — Shardable-domain pattern: folder + INDEX.md routing`.
2. **Plan-before-build gate** added to `rules/workitems.md`: no workitem is implemented
   without a plan file in `workitems/plans/`, written and agreed before its branch is cut.
   Items with no plan show `(no plan)`. Shipped the first plan
   (`plans/sessionstart-load-rules.md`) as a working example — dogfooding.

## 5. Process learnings

- **Audit agent earned its keep.** The independent auditor (spawned per user request) caught
  3 stale `WORKITEMS.md` references in `rules/git-workflow.md` — an always-loaded shard the
  restructure had missed. Fixed before commit. Lesson: when renaming/moving a ledger,
  grep the *whole* repo for the old name, including rule shards, not just the obvious files.
- **`git reset --soft` keeps the OLD index.** After soft-resetting two commits to fold a late
  `done.md` edit into commit 1, the first redo committed the stale index version (the
  working-tree edit was never re-staged). Fix: `git add -A` after the soft reset so the index
  matches the working tree before recommitting. Verified with `git show HEAD~1:file`.
- **Self-consistency:** the restructure logged *itself* in `done.md` (2026-05-28 entry), the
  same way the original log-every-workitem rule logged itself — the ledger must be authoritative.

## 6. Queued followups (in `workitems/open.md`)

- Build the SessionStart hook itself (plan ready).
- Tweak `rules/readme-convention.md` — specifics captured: a `README.md` only for the project
  head + directories Claude works in directly; sharded sub-domains (`rules/`, `notes/`,
  `workitems/`) use `INDEX.md` instead. Reconciles the tension noted in `D17`.

## 7. Aside (not vyasa work)

Early in the session: confirmed this model is Opus 4.8 (Jan 2026 cutoff) and pulled Anthropic's
release notes vs Opus 4.7 (honesty focus, agentic-coding 64.3%→69.2%, Dynamic Workflows, effort
controls). Logged here only as context for why the session happened, not as project work.
