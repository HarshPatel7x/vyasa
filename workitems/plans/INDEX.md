# plans — index

> One plan per workitem. A plan is written and agreed **before** the workitem's branch is
> cut — the **plan-before-build** gate in [`../../rules/workitems.md`](../../rules/workitems.md).
> Plans load on demand, never auto-loaded. Kept permanently after the item closes (linked from
> [`../done.md`](../done.md)).

---

## Plans

- [sessionstart-load-rules.md](sessionstart-load-rules.md) — plan for the "SessionStart hook to auto-load default rules into context" workitem. Status: planned, not yet built.
- [verify-claudemd-import.md](verify-claudemd-import.md) — plan for verifying CLAUDE.md `@import` expands at launch (reopens Option 1 of the hook plan after the 10K hook-output cap was discovered). Status: verification workitem.
- [voice-rule-reinforcement.md](voice-rule-reinforcement.md) — plan for reinforcing the plain-English rule with a `plain` interrupt, a before-sending self-check, and a recurring-terms glossary. Status: planned, awaiting build sign-off.
- [migrate-hook-to-import.md](migrate-hook-to-import.md) — plan for the hook→`@import` migration. Status: built + shipped (PR #5); compaction caveat closed (PR #6).
- [diff-verification-hook.md](diff-verification-hook.md) — plan for the PostToolUse diff-verification hook that surfaces the real on-disk delta after each Edit/Write. Status: built + shipped (2026-06-01); live trigger verified next fresh session.
- [pr-format-check.md](pr-format-check.md) — plan for PR-side CI that enforces PR title/body + per-commit message format server-side (reuses `hooks/commit-msg` via a `COMMIT_REF` seam). Status: built + shipped (2026-06-01); live workflow run watched on the introducing PR.
