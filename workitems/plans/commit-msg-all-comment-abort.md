# Plan — Fix `hooks/commit-msg` silent `set -e` abort on a comment-only message (line 36)

> Workitem: **Fix the line-36 all-comment `set -e` abort: a message whose lines are all `#`-comments
> aborts the hook silently instead of failing with a diagnostic.**
> Branch: `workitem/commit-msg-all-comment-abort`. Status: planned, awaiting review sign-off.

## Problem

Line 36 strips git's comment lines before validating:

```bash
clean_msg="$(grep -v '^#' "$msg_file" | sed -e :a -e '/^$/{$d;N;ba' -e '}')"
```

Under `set -euo pipefail`, if **every** line of the message is a `#`-comment (so `grep -v '^#'`
matches nothing), `grep` exits 1, `pipefail` propagates it, and `set -e` aborts the **whole hook**
at line 36 — *before any validation runs*. The commit is rejected (exit 1) but with **zero output**:
the author sees a hard failure with no reason at all.

## Root cause + reachability (verified empirically, not assumed)

Same `set -e` + `pipefail` + non-zero-in-command-substitution class as the two prior fixes, but at a
different site. Three reproductions on the current (pre-fix) hook:

- **REPRO 1 — direct call, all-comment file:** a message file of only `#`-lines → `bash commit-msg
  msg` exits 1 with **0 stderr bytes** (the silent abort).
- **REPRO 3 — real, reachable git flow:** `git commit -m '#42 reference an issue at start'` (a
  one-line `-m` message that *starts with* `#`) → `git commit` exits 1 with **0 stderr bytes**.
  `-m` uses cleanup mode `whitespace`, which does **not** strip `#` lines, so the hook receives
  `#42 …` as the sole line; `grep -v '^#'` removes it → empty → abort. **This is the realistic
  trigger:** anyone who begins a one-line `-m` message with `#` (e.g. an issue reference) hits a
  silent rejection.
- **REPRO 2 — empty-editor commit does NOT trigger it:** `GIT_EDITOR=true git commit` leaves
  `COMMIT_EDITMSG` with a leading **blank** line above the comments; `grep -v '^#'` keeps the blank
  line, so `grep` exits 0 and the hook proceeds to fail loudly with "subject does not match …".
  Documented so the reachability boundary is precise: the bug needs a message with `#`-lines and
  **no** surviving blank/non-comment line.

The control (`git commit -m 'feat(cli): add thing'`) passes — normal messages are unaffected.

## Options considered

1. **`|| true` at the end of the pipeline (chosen).**
   `clean_msg="$(grep -v '^#' "$msg_file" | sed … || true)"`. The pipeline can no longer abort the
   script; `clean_msg` becomes empty; `subject` becomes empty; the **existing** subject-format check
   (lines 52-56) then fails with its real diagnostic: `subject does not match '<type>(<scope>):
   <summary>' … Got:` (empty). Matches the idiom already used at line 113 and the two prior fixes —
   one consistent pattern for "swallow a benign non-zero, let a content check decide".
2. **Explicit empty-message guard** (detect `clean_msg` empty → `fail "commit message is empty (only
   comments)"`). Nicer wording, but more code and a second message string to maintain; the subject
   check already gives an actionable error, and git itself rejects a truly empty message as a
   backstop. Rejected as over-engineering for this fix; the wording gain is marginal.
3. **Drop `pipefail` / restructure.** Wider blast radius on a security-sensitive hook; rejected.

**Decision: option 1.** Smallest diff, identical to the established pattern, and the existing
subject-format check already emits a clear, correct error for the now-empty subject.

## Implementation steps

1. On branch `workitem/commit-msg-all-comment-abort`, edit `hooks/commit-msg` line 36, appending
   ` || true` to the end of the pipeline inside the command substitution:

   ```bash
   clean_msg="$(grep -v '^#' "$msg_file" | sed -e :a -e '/^$/{$d;N;ba' -e '}' || true)"
   ```

   No other lines change.

2. No spec change, no `D`-entry: the convention (a commit subject must match `<type>(<scope>):
   <summary>`) is unchanged; this only converts a silent abort into the already-intended subject
   diagnostic. `fix(hooks):` bug fix.

## Verification

Driven against the hook both directly and through real `git commit`, in isolated `/tmp` repos:

| Case | Input | Expected after fix |
|------|-------|--------------------|
| A (the bug, direct) | all-comment message file, `bash commit-msg msg` | exit 1 **with** "subject does not match … Got:" (before: exit 1, 0 bytes) |
| B (the bug, real git) | `git commit -m '#42 reference an issue at start'` | exit 1 **with** the subject diagnostic (before: exit 1, 0 bytes) |
| C (normal message) | `git commit -m 'feat(cli): add thing'` | exit 0 (pass) — `\|\| true` is a no-op when non-comment lines exist |
| D (message + comments) | subject line `feat(cli): x` followed by `#`-comment lines | exit 0 — comments stripped, real subject validated, unaffected |
| E (empty file) | 0-byte message file | exit 1 with the subject diagnostic, not a silent abort |
| F (full valid commit) | a real `git commit -m 'fix(hooks): real change'` with a body | exit 0 — end-to-end sanity that the fix didn't disturb the normal path |
| G (blank-only / whitespace-only) | a message of only blank or whitespace lines (no `#`, no content) | exit 1 with the subject diagnostic — and note these never hit the silent abort even *unfixed* (grep keeps blank lines → exits 0), so the fix must not regress them |

Cases A and B are run on the **unfixed** hook first (showing the silent 0-byte abort) and re-run on
the fixed hook (showing the diagnostic). C–G guard the normal, mixed, empty, full-commit, and
blank-only paths.

## Out of scope (noted, not fixed here)

- The hook hard-codes `^#` as the comment marker; a customised `core.commentChar` would make
  `grep -v '^#'` strip the wrong lines (or fail to strip git's actual comments). That is a separate
  correctness concern about comment-char handling, not the silent-abort bug; deferred.
- Whether `grep -v '^#'` *should* strip a user's intentional leading-`#` content (e.g. `#42 …`) at
  all is a deeper design question about the hook's comment model; this fix only ensures such input
  fails **loudly** rather than silently. Deferred.
