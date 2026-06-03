# Plan — Add `--root` to `readme_changed()` so root-commit decisions files are seen

> Workitem: **Fix `readme_changed()` missing `--root`: a decisions file born in a repo's root
> commit false-fails the CI-seam staged-file check.**
> Branch: `workitem/diff-tree-root-flag`. Status: planned, awaiting review sign-off.

## Problem

`hooks/commit-msg` validates that, when a `Touches: D<N> — …` footer is present,
`docs/decisions.md` is among the files the commit changes (so a decision citation can't land
without the decision itself). In the CI-seam path (`COMMIT_REF="<sha>:"`, used by the PR-format
workflow against an already-made commit), `readme_changed()` lists those files with:

```bash
git diff-tree --no-commit-id --name-only -r "${COMMIT_REF%:}"
```

`git diff-tree <commit>` diffs the commit against its **parent**. A **root** commit (the first
commit in a repo, no parent) has nothing to diff against, so this command emits **nothing** — even
for files the root commit plainly adds. The staged-file guard then false-fails:

```
✗ … 'Touches: D<N> — …' footer present but docs/decisions.md is not in this commit's staged changes
```

…rejecting a perfectly valid commit whose `docs/decisions.md` *is* present.

## Root cause (verified empirically, not assumed)

Reproduced in an isolated temp repo: a **root** commit that introduces `docs/decisions.md` (with a
valid `### D22.` heading) and a `Touches: D22 — …` footer, validated via `COMMIT_REF="<root-sha>:"`:

- `git diff-tree --no-commit-id --name-only -r <root-sha>` → **empty** output.
- `git diff-tree --no-commit-id --name-only --root -r <root-sha>` → `docs/decisions.md`.
- Current hook → exit 1, "docs/decisions.md is not in this commit's staged changes" (the false-fail).

`git diff-tree` only shows a root commit's contents when given `--root` (which treats the root
commit as a creation diff against the empty tree). Without it, root commits are silently empty.

## Scope / reachability

- **Local path is unaffected.** When `COMMIT_REF=":"` (the default at commit time) the function
  uses `git diff --cached --name-only`, which lists staged files correctly regardless of history
  depth. The bug is *only* in the `else` (CI-seam) branch.
- **Unreachable in vyasa today** (verified: `docs/decisions.md` was not introduced in this repo's
  root commit). It bites only a repo whose *first-ever* commit both introduces `docs/decisions.md`
  and carries a `Touches:` footer, validated server-side. Real but narrow — a correctness/robustness
  fix, not an active outage. Surfaced by the checkpoint-2 adversarial review of the prior workitem.

## Options considered

1. **Add `--root` to the `diff-tree` invocation (chosen).**
   `git diff-tree --no-commit-id --name-only --root -r "${COMMIT_REF%:}"`.
   - `--root` makes a root commit show as a full creation diff (all its files listed); for
     **non-root** commits `--root` is a no-op (they still diff against their parent), so existing
     behavior is byte-for-byte preserved for every commit that has a parent.
   - One-token change, no control-flow restructure.
2. **Special-case root commits** (detect "no parent", fall back to `git ls-tree`/`git show
   --name-only`). More code, more branches, no behavioral gain over `--root`.
3. **Leave as-is, document the limitation.** Rejected — the user asked to finish this followup, and
   `--root` is the idiomatic, zero-risk fix.

**Decision: option 1.** `--root` is exactly the flag git provides for this case; it changes
behavior *only* for parentless commits and leaves the common path untouched.

## Implementation steps

1. On branch `workitem/diff-tree-root-flag`, edit the `else` line of `readme_changed()` in
   `hooks/commit-msg`, inserting `--root` before `-r`:

   ```bash
   git diff-tree --no-commit-id --name-only --root -r "${COMMIT_REF%:}"
   ```

   No other lines change.

2. No spec change and no `D`-entry: the *convention* (a `Touches:` footer requires `docs/decisions.md`
   in the commit) is unchanged; this only makes the CI-seam check correctly recognise a root
   commit's files. `fix(hooks):` bug fix, not structural.

## Verification

Driven against the hook in isolated `/tmp` repos, CI-seam mode (`COMMIT_REF="<sha>:"`):

| Case | Commit shape | Footer | Expected after fix |
|------|--------------|--------|--------------------|
| A (the bug) | **root** commit adds `docs/decisions.md` (has `### D22.`) | `Touches: D22 — A real decision title` | exit 0 (pass) — was exit 1 false-fail before |
| B (root, unknown code) | **root** commit adds `docs/decisions.md` | `Touches: D999 — Bogus` | exit 1 with "no '### D999.' heading exists" (reaches line 124, not the staged-file guard) |
| C (root, footer but file absent) | **root** commit adds only `README.md`, no `docs/decisions.md` | `Touches: D22 — …` | exit 1 with "not in this commit's staged changes" (correct rejection still fires) |
| D (non-root regression) | parent commit, then a commit that changes `docs/decisions.md` | `Touches: D22 — A real decision title` | exit 0 (pass) — proves `--root` is a no-op for commits with a parent |
| E (non-root, file absent) | parent commit, then a commit that changes only `README.md` | `Touches: D22 — …` | exit 1 "not in this commit's staged changes" (unchanged) |
| F (local index path) | staged `docs/decisions.md`, `COMMIT_REF=":"` | `Touches: D22 — A real decision title` | exit 0 — proves the local path is untouched by the change |

Case A is run on the **unfixed** hook first (shows the false-fail) and re-run on the fixed hook
(passes). B–F guard against regressions in the unknown-code, file-absent, non-root, and local-index
paths.

## Audit of the other history-reader

`decisions_blob()` (line 32) reads `git show "${COMMIT_REF}docs/decisions.md"` — a **tree-path**
read, not a parent diff — so it returns the file's content correctly even for a root commit (the
file exists in the root commit's tree). Confirmed independently during plan review. So
`readme_changed()`'s `diff-tree` is the *only* parent-diffing dependency, and the single-line scope
is correct.

## Out of scope (noted, not fixed here)

- The line-36 all-comment `set -e` abort is the *other* followup, handled on its own branch
  (`workitem/commit-msg-all-comment-abort`).
