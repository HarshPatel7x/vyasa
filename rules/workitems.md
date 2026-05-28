---
WHAT: Workitems folder convention — open/done split, plan-before-build, branch-per-workitem.
LOAD: Default — every session.
---

# Workitems

## The checklist lives in the `workitems/` folder

The workitems domain is a folder (folder-per-domain + `INDEX.md`, same pattern as `rules/` and `notes/`):

- [`workitems/open.md`](../workitems/open.md) — live queue of pending work. One entry per item. This is the lean list to read at session start. **Candidate for default-load.**
- [`workitems/done.md`](../workitems/done.md) — archive of completed items. **Never auto-loaded** — on-demand only.
- [`workitems/plans/`](../workitems/plans/INDEX.md) — one plan per workitem, loaded on demand.
- [`workitems/INDEX.md`](../workitems/INDEX.md) — the router.

Checkbox format (`- [ ]` open, `- [x]` done). Read `open.md` at session start to know what's pending; append to it when the user agrees to new work; move items to `done.md` as they're completed.

When the user agrees to a new piece of work (a fix, a feature, a refactor, a rule, a hook), append it to `workitems/open.md` before moving on. Do not rely on memory or scrollback for queued work — if it isn't written down, it doesn't exist.

## Plan-before-build

**No workitem gets implemented without a plan attached.** Before cutting a workitem's branch or writing any code, confirm a plan file exists for it under [`workitems/plans/<slug>.md`](../workitems/plans/INDEX.md). If it doesn't, write the plan and get the user's agreement *first*.

- Open items with no plan yet are marked `(no plan)` in `open.md`, so the gap is visible at a glance.
- An item with a plan links to it: `→ plan: [\`plans/<slug>.md\`](plans/<slug>.md)`.
- The plan captures the problem, options considered + the decision, the implementation steps, and how it will be verified.
- A plan is permanent: when the workitem closes, its plan file **stays** in `plans/` as a record (linked from the `done.md` entry); never deleted.

The gate makes an item's state unambiguous: either *planned, ready to build* or *needs a plan first*.

## Every workitem gets logged — shipped-on-the-fly or deferred

Decided 2026-05-27.

Any piece of agreed work must end up in the workitems ledger, regardless of whether it's done immediately or queued for later:

- **Deferred work** → append to [`workitems/open.md`](../workitems/open.md) (existing rule above).
- **Shipped-on-the-fly work** (agreed and completed in the same exchange) → append directly to [`workitems/done.md`](../workitems/done.md) with the branch/commit that delivered it, so the audit trail is complete.

The motivation is symmetry: the ledger is the project's record-and-reminder system. If shipped-immediately work skips it, the ledger silently loses fidelity over time and "what got done" can only be reconstructed from `git log`. Treat the ledger as authoritative for *every* agreed change, not just queued ones.

## One branch per checked-off workitem

When you complete a workitem:

1. Create a new git branch named after the item (e.g., `workitem/diff-verification-hook`).
2. Make the commit(s) for that item on that branch.
3. Move the item from `workitems/open.md` to `workitems/done.md` (checked off, `- [x]`).
4. Do not bundle unrelated workitems into one branch.

**Sizing exception:** If two or more workitems are trivially small (e.g., typo fixes, one-line config tweaks), they may share a branch — but only by explicit decision in-conversation, not as default. The branch name should then reflect the bundle.

Once on a workitem branch, the commit-message and PR-description conventions in `rules/git-workflow.md` apply. Direct commits to `main` are blocked by the pre-commit hook in `hooks/pre-commit`.

## What does NOT belong in the workitems ledger

- Transient session-internal tasks (use the in-session task tracker for those).
- Ideas you haven't yet agreed with the user to do (those are exploratory, not queued).
- Items already done (move to `done.md`, don't delete — `done.md` is the audit trail).
