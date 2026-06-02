# workitems

> Router for the workitems domain. Same folder-per-domain + `README.md` router pattern as
> [`rules/README.md`](../rules/README.md) and [`notes/README.md`](../notes/README.md).

---

## Files

- [open.md](open.md) — live queue of pending work. The lean, scannable list. **Candidate for default-load** so pending work is visible every session. Each item links to its plan, or is marked `(no plan)`.
- [done.md](done.md) — archive of completed items. **Never loaded** into session context — on-demand only. Items move here from `open.md` on completion; never deleted (audit trail).
- [plans/README.md](plans/README.md) — one plan per workitem. **Loaded on demand** when you pick up an item, never auto-loaded.

---

## Convention

See [`../rules/workitems.md`](../rules/workitems.md) for the full convention:
append-on-agreement, **plan-before-build**, one-branch-per-item, move-to-`done.md`-on-completion.
