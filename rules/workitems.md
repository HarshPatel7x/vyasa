---
WHAT: Workitems checklist and branch-per-workitem convention.
LOAD: Default — every session.
---

# Workitems

## The checklist lives at `WORKITEMS.md` (project root)

`WORKITEMS.md` is this project's source of truth for "what's queued." One line per item, checkbox format (`- [ ]` open, `- [x]` done). Read it at session start to know what's pending; append to it when the user agrees to new work; check items off as they're completed.

When the user agrees to a new piece of work (a fix, a feature, a refactor, a rule, a hook), append it to the **Open** section of `WORKITEMS.md` before moving on. Do not rely on memory or scrollback for queued work — if it isn't written down, it doesn't exist.

## One branch per checked-off workitem

When you complete a workitem:

1. Create a new git branch named after the item (e.g., `workitem/diff-verification-hook`).
2. Make the commit(s) for that item on that branch.
3. Check the item off in `WORKITEMS.md` and move it to the **Closed** section.
4. Do not bundle unrelated workitems into one branch.

**Sizing exception:** If two or more workitems are trivially small (e.g., typo fixes, one-line config tweaks), they may share a branch — but only by explicit decision in-conversation, not as default. The branch name should then reflect the bundle.

**Bootstrap exception (until PR/commit/branch rules exist):** The PR, commit-message, and PR-description conventions are not yet defined (tracked as a workitem). Until they land, branch-per-workitem applies on a best-effort basis and direct commits to `main` are acceptable when no convention covers the situation.

## What does NOT belong in `WORKITEMS.md`

- Transient session-internal tasks (use the in-session task tracker for those).
- Ideas you haven't yet agreed with the user to do (those are exploratory, not queued).
- Items already done (move to Closed, don't delete — Closed is the audit trail).
