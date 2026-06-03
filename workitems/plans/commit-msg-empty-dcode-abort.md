# Plan — Fix `hooks/commit-msg` empty-message abort on an unknown `D<N>` footer

> Workitem: **Fix `hooks/commit-msg` empty-message abort on an unknown `D<N>` footer.**
> Branch: `workitem/commit-msg-empty-dcode-abort`. Status: planned, awaiting review sign-off.

## Problem

When a commit message carries a `Touches: D<N> — …` footer that cites a `D<N>` with **no**
matching `### D<N>.` heading in `docs/decisions.md`, the commit is correctly **rejected**
(fail-closed, exit 1) — but the rejection prints an **empty** error instead of the intended
diagnostic:

```
✗ commit-msg hook (rules/git-workflow.md): footer references D<N> but no '### D<N>. …' heading exists in staged docs/decisions.md
```

So the author sees a hard failure with no explanation of *why* — a bad failure UX on an
enforcement script whose whole job is to explain what's wrong.

## Root cause (verified empirically, not assumed)

`hooks/commit-msg` runs under `set -euo pipefail` (line 5). The offending line is 124:

```bash
readme_title="$(decisions_blob | grep -E "^### D${d_num}\. " | head -n 1 | sed -E "s/^### D${d_num}\. //")"
```

When no heading matches, `grep` exits 1. `pipefail` makes the whole pipeline inherit that
non-zero status; the command substitution therefore exits 1; and because the assignment is a
plain (non-`local`) simple command, `set -e` aborts the **entire script** right there — *before*
the `if [[ -z "$readme_title" ]]` guard on line 125 that was written to emit the friendly message.
Result: exit 1 (correct, fail-closed) but no stderr output (the bug).

**Reproduced** on the current unfixed hook in an isolated temp repo: a message with
`Touches: D999 — Bogus title` (with `docs/decisions.md` staged) exits 1 and prints nothing.

This is **pre-existing** — it predates the readme-router branch; that branch's adversarial review
surfaced it. The valid-match path is unaffected (a real `### D<N>.` heading yields one line, grep
exits 0), which is why every real `Touches:` validation to date has worked.

## Options considered

1. **`|| true` at the end of the pipeline (chosen).** Swallow the pipeline's non-zero so the
   assignment always succeeds; then let the existing `[[ -z "$readme_title" ]]` content-check decide.
   - Matches the idiom **already used in this same file** at line 113:
     `touches_lines="$(printf '%s' "$clean_msg" | grep -E '^Touches: D[0-9]+ — ' || true)"`.
   - Minimal: one-line change, no control-flow restructure.
   - Robust: also neutralises any incidental non-zero from `head` closing the pipe early
     (SIGPIPE) on a multi-line match, since correctness now hinges on the *content* of
     `readme_title`, never the pipeline's exit code.
2. **Split the assignment / disable `set -e` around it** (`set +e; …; set -e`). More lines, easy to
   get the save/restore wrong, no upside over option 1.
3. **`local`-trick** (assign via a `local` declaration so `set -e` ignores the substitution status).
   Not applicable — this is top-level script scope, not a function; would require wrapping.

**Decision: option 1.** Smallest diff, matches the file's own established pattern, content-based
guard already exists immediately below.

## Implementation steps

1. On branch `workitem/commit-msg-empty-dcode-abort`, edit `hooks/commit-msg` line 124: append
   ` || true` to the end of the pipeline inside the command substitution:

   ```bash
   readme_title="$(decisions_blob | grep -E "^### D${d_num}\. " | head -n 1 | sed -E "s/^### D${d_num}\. //" || true)"
   ```

   No other lines change. (`grep` precedence: `A | B | C | D || true` parses as
   `(A|B|C|D) || true`, so `true` runs only when the pipeline fails and contributes no output.)

2. No spec change and no `D`-entry: the *convention* (footer must match a real heading — "hook,
   hard fail") is unchanged; this only makes the already-intended diagnostic actually print. The
   `rules/git-workflow.md` enforcement table cell ("`Touches: D<N>` footer correctness — hook,
   hard fail") stays true. So this is a `fix(hooks):` bug fix, not a structural change.

## Verification

Driven against the hook in an **isolated temp git repo** (`/tmp`) so the vyasa index/tree is never
touched. `docs/decisions.md` is created with a known `### D22. <title>` heading and staged.

| Case | Message footer | decisions.md staged? | Expected after fix |
|------|----------------|----------------------|--------------------|
| A (the bug) | `Touches: D999 — Bogus title` | yes | exit 1 **with** "footer references D999 but no '### D999. …' heading exists" |
| B (valid match) | `Touches: D22 — A real decision title` | yes | exit 0 (pass) |
| C (title mismatch) | `Touches: D22 — Wrong title` | yes | exit 1 with the "does not match" diagnostic |
| D (footer, file unstaged) | `Touches: D22 — A real decision title` | no | exit 1 with "docs/decisions.md is not in this commit's staged changes" |
| E (no footer) | plain message, no `Touches:` | n/a | exit 0 (block skipped) |
| F (duplicate heading → SIGPIPE) | `Touches: D22 — A real decision title`, with **two** `### D22.` headings in decisions.md | yes | exit 0 (pass) — proves `\|\| true` also neutralises the `head -n 1` SIGPIPE-to-grep (141) that `pipefail` would otherwise treat as failure |
| G (two footers, one bogus) | `Touches: D22 — A real decision title` **and** `Touches: D999 — Bogus` | yes | exit 1 with the D999 "no heading exists" diagnostic (loop reaches the bogus one) |

Before/after evidence: Cases A and F are run on the **unfixed** hook first (A shows empty output;
F shows whether the SIGPIPE path also aborts) and re-run on the fixed hook (A shows the
diagnostic; F passes). B–E guard against regressions in the neighbouring valid / mismatch /
unstaged / no-footer paths; G proves the multi-footer loop still reaches and reports a later bogus
code. **CI-seam coverage:** the `COMMIT_REF="<sha>:"` path shares line 124 verbatim, so the fix
applies to it transitively; one case is additionally run with `COMMIT_REF` pointed at a real commit
(unknown D-code) to confirm the diagnostic prints in CI mode too, not just the local-index path.

## Out of scope (noted, not fixed here)

- Line 36 `clean_msg="$(grep -v '^#' "$msg_file" | sed …)"` is the *same class* of latent issue:
  if a message were 100% comment lines, `grep -v` exits 1 and could abort under `set -e` before
  line 37. Git *usually* aborts an all-comment (empty) commit before invoking `commit-msg`, but
  that is not airtight — a customised `core.commentChar`, a commit template, or
  `--allow-empty-message` can let an all-`#` (by the configured char) message reach the hook. So
  it is a genuine latent sibling, deferred to a possible separate workitem rather than asserted
  away. Flagged here, not fixed, to avoid scope-creeping this one.
- A full audit of every command-substitution-in-assignment site in the file (lines ~36, 37, 67,
  78, 80, 96, 113, 124) confirms the *only* live bug is line 124: lines 67/78/80/96 pipe into
  `perl -ne`/`tail`/`head`/`echo` which exit 0; line 113 already carries `|| true`; line 36 is the
  deferred sibling above. No other site needs changing in this workitem.
- **Discovered during verification (separate latent bug, deferred):** `readme_changed()`'s commit
  path uses `git diff-tree --no-commit-id --name-only -r "${COMMIT_REF%:}"` **without `--root`**,
  which emits nothing for a parentless (first-ever) commit. So if `docs/decisions.md` were ever
  *born* in a repo's root commit, the CI-seam staged-file check would false-fail with "not in this
  commit's staged changes" even when the file is present. Unreachable in vyasa (verified:
  `docs/decisions.md` was not introduced in the root commit), and unrelated to line 124 — but a
  real latent bug worth a separate workitem. Surfaced by checkpoint-2 adversarial review.
