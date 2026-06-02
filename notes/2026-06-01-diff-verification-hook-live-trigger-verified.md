# 2026-06-01 — Edit-verification hook: live trigger verified

> Meeting-minutes style. Closes the one open caveat carried by
> [2026-06-01-diff-verification-hook-build.md](2026-06-01-diff-verification-hook-build.md):
> the build session could verify the hook's *logic* but not its *live firing*, because
> Claude Code snapshots hook config at startup and does not hot-reload `settings.json`.
> This is that next fresh session.

---

## Context

The edit-verification hook pair shipped in commit `9b91257` (`feat(hooks): add
edit-verification Pre/PostToolUse hook pair`, merged via PR #9):

- `hooks/snapshot-before-edit.sh` (PreToolUse) — copies a file's real bytes before an
  Edit/Write/MultiEdit.
- `hooks/verify-diff.sh` (PostToolUse) — diffs the post-edit bytes against that snapshot
  and surfaces the exact per-edit delta. When a reported-successful edit left the file
  byte-identical, it injects a neutral "changed nothing on disk" note into the model's
  context.

The build commit deliberately left a note: *"The live in-session trigger is verified next
fresh session."* That verification is what this session did.

## What was done

Tested on a throwaway file under `/tmp/dv-hooktest/` (outside the repo — no project
changes, no workitem) to avoid polluting tracked files.

1. **New-file path.** `Write` created `/tmp/dv-hooktest/scratch.txt` with three lines.
2. **No-op path.** `Write` re-wrote the *exact same bytes* to the now-existing file, so
   the post-edit bytes are byte-identical to the snapshot.

## What was observed

Both branches of the PostToolUse hook fired correctly. Crucially, the two branches surface
their output in **two different places**, which is why each had to be checked differently:

| Test | Branch exercised | Output channel | Observed result |
|------|------------------|----------------|-----------------|
| 1. New file | `(NEW file)` summary | `systemMessage` → user's terminal only | `[edit-verify] …/scratch.txt  +3 -0 lines  (NEW file)` with the `@@ -0,0 +1,3 @@` hunk — seen by the user (confirmed via screenshot), **not** visible in the model's context |
| 2. No-op | `no change` note | `additionalContext` → injected into model context | `edit-verify: …/scratch.txt is byte-identical to its pre-edit state; this edit changed nothing on disk.` — seen directly in-context |

The no-op case is the load-bearing one: catching a silently-failed edit is the whole reason
the hook exists, and it did exactly that.

## Key learning

**The hook's two output channels are asymmetric, and that matters for self-testing.**
`systemMessage` is shown to the *user* but is **not** echoed back into the model's context;
only `additionalContext` reaches the model. So an assistant verifying this hook from its own
context alone can *only* confirm the no-op branch directly — the NEW/modified branches are
invisible to it and need the user's screen (or a filesystem side-channel) to confirm.

A first instinct — "check the snapshot artifacts on disk" — is a dead end: the PostToolUse
hook's `cleanup()` deletes the `.snap`/`.meta` files after it runs, so an empty
`claude-diff-verify/` directory is consistent with *both* "fired and cleaned up" and "never
fired." It proves nothing. The no-op branch is the only self-contained, in-context signal.

## State after this session

- Hook pair confirmed **live** in a fresh session — the last open caveat from the build note
  is closed.
- No repo changes from the test itself (scratch file in `/tmp`, deleted afterward).
- No new decision; this is verification of already-shipped D19 — Project-scope Claude Code
  Pre/PostToolUse hooks for edit verification, not a change to it.
