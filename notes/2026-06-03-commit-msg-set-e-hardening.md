# 2026-06-03 — Hardening `hooks/commit-msg` against silent `set -e` aborts

> Session notes (meeting-minutes style). Topic: three bug fixes to the commit-message validation
> hook, all the same root cause, shipped as three separate workitems/PRs.

## What was shipped

Three fixes to `hooks/commit-msg`, each a one-token/one-line change, each on its own branch + PR,
each squash-merged to `main`:

1. **PR #22 → `14c5265`** — *empty diagnostic on an unknown `D<N>` footer* (the original open
   workitem). When a `Touches: D<N> — …` footer cited a decision code with no matching `### D<N>.`
   heading in `docs/decisions.md`, the commit was correctly rejected but printed **nothing**. Fix:
   append `|| true` to the `readme_title="$(decisions_blob | grep … | head … | sed …)"` pipeline so
   the existing `[[ -z … ]]` guard can emit its message.
2. **PR #23 → `1867474`** — *`readme_changed()` missing `--root`* (followup, surfaced by #22's
   own review). `git diff-tree … -r` diffs a commit against its parent, so a **root** commit emitted
   no file list and the CI-seam staged-file check false-failed "not in this commit's staged changes"
   even when `docs/decisions.md` was present. Fix: insert `--root` (a no-op for every parented
   commit, verified).
3. **PR #24 → `d1c8966`** — *comment-only message silent abort* (second followup from #22's review).
   Line 36 `clean_msg="$(grep -v '^#' "$msg_file" | sed …)"`: a message whose lines are all
   `#`-comments makes `grep -v` exit 1 → the hook aborted before any validation, rejecting with zero
   output. Fix: append `|| true`; the existing subject-format check then fails loudly.

## The common root cause

All three are the same class: under `set -euo pipefail`, a command that legitimately exits non-zero
(a `grep` with no match; a `diff-tree` that lists nothing) **inside a command substitution in a plain
assignment** aborts the whole script — *before* the friendly guard a few lines down can run. The
fix idiom (`|| true`, already used at line 113) makes correctness depend on the **content** of the
captured variable, never the pipeline's exit code.

## How it ran

- Each fix went through the full pipeline: **plan → adversarial review of the plan → fix →
  adversarial review of the fix → verify → ship**. Six review subagents across the three.
- **Verify-before-fix** every time: the bug was reproduced empirically in isolated `/tmp` repos
  *before* the fix, then re-run after. Nine cases for #22, six for #23, seven for #24.
- Each commit was validated by the **live hook** (`core.hooksPath=hooks`) — the hook validating its
  own fix.

## Lessons / things learned

- **One fix's adversarial review surfaced the other two.** Both #23 and #24 were found by the
  checkpoint-2 reviewer of #22 auditing the surrounding file — the audit paid for itself twice over.
- **The same bug had a second hidden face.** #22's fix also closed a `head -n 1` **SIGPIPE** abort
  (exit 141) on duplicate headings — only demonstrable by forcing 60k matching lines to overflow the
  pipe buffer; with small inputs the SIGPIPE never fires, so a naive test would have missed it.
- **Reachability matters more than the abstract bug.** #24 looked like a theoretical "all-comment
  template" case until testing showed the *real* trigger: `git commit -m '#42 …'` — `-m` uses cleanup
  mode `whitespace`, which does **not** strip `#` lines, so any one-line message starting with `#`
  (an issue reference) hit the silent abort. An empty-editor commit does **not** trigger it (git's
  `COMMIT_EDITMSG` keeps a leading blank line that `grep` retains).
- **A root commit is invisible to `git diff-tree` without `--root`** — a non-obvious git gotcha that
  only bit the CI-seam path, never the local index path.
- All three were pure enforcement bug fixes — convention unchanged, so **no `docs/decisions.md`
  entry** for any of them.
