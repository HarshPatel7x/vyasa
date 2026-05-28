# workitems — index

> Router for the workitems domain. Same folder-per-domain + `INDEX.md` pattern as
> [`rules/INDEX.md`](../rules/INDEX.md) and [`notes/INDEX.md`](../notes/INDEX.md).

---

## Files

- [open.md](open.md) — live queue of pending work. The lean, scannable list. **Candidate for default-load** so pending work is visible every session. Each item links to its plan, or is marked `(no plan)`.
- [done.md](done.md) — archive of completed items. **Never loaded** into session context — on-demand only. Items move here from `open.md` on completion; never deleted (audit trail).
- [plans/INDEX.md](plans/INDEX.md) — one plan per workitem. **Loaded on demand** when you pick up an item, never auto-loaded.

---

## Convention

See [`../rules/workitems.md`](../rules/workitems.md) for the full convention:
append-on-agreement, **plan-before-build**, one-branch-per-item, move-to-`done.md`-on-completion.
