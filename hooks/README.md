# hooks

> Hooks that enforce or automate project conventions. Version-controlled so they travel with the repo. Two kinds live here: **git hooks** (run by git, wired via `core.hooksPath`) and **Claude Code hooks** (run by the Claude Code harness, wired via `.claude/settings.json`).

## What lives here

### Git hooks (wired via `core.hooksPath`)

- **`commit-msg`** — validates the commit message format. Hard-fails on:
  - Subject not matching `<type>(<scope>): <summary>` with type in the whitelist
  - Scope not in the whitelist (if a scope is provided)
  - Subject longer than 72 chars or ending with a period
  - Body line longer than 100 chars (URL-only lines exempt)
  - Any `D<N>` mention not followed inline by ` — <title>` (em-dash U+2014)
  - `Touches: D<N> — <title>` footer when docs/decisions.md is not staged, or when the footer's title does not match the staged docs/decisions.md `### D<N>. <title>` heading

  **`COMMIT_REF` seam (so CI can reuse this hook):** the only part of `commit-msg` that needs the staging *index* is the `Touches:` block — `git diff --cached` (which files changed) and `git show :docs/decisions.md` (the decisions-log blob). An already-made commit in a fresh CI checkout has no index, so those reads are routed through a `COMMIT_REF` indirection: unset → `:` (the index, the local default — behavior is byte-for-byte unchanged); set to `<sha>:` → the helpers `readme_changed`/`decisions_blob` resolve the changed files and the docs/decisions.md blob from that commit's tree instead. The PR-format CI (`.github/scripts/pr-format-check.sh commits`) invokes this same hook with `COMMIT_REF="<sha>:"` for each non-merge commit in a PR, so the local hook and the server-side check share one source of truth and cannot drift. See decision **D20 — PR title + body format enforced via GitHub Actions CI** (in `docs/decisions.md`) and the design in `workitems/plans/pr-format-check.md`.

- **`pre-commit`** — blocks direct commits on `main` (per branch-per-workitem). Allows merge commits in progress (e.g., from `git pull`).

### Claude Code hooks (wired via `.claude/settings.json`)

**Edit-verification pair** — `snapshot-before-edit.sh` (PreToolUse) + `verify-diff.sh`
(PostToolUse), matcher `Edit|Write|MultiEdit`. Together they surface the **exact delta a single
edit made**, computed from the file's real before/after bytes — independent of anything the model
claims. When a reported-successful edit leaves the file byte-identical, `verify-diff.sh` also
injects a factual, neutral note into the model's context. See decision
**D19 — Project-scope Claude Code Pre/PostToolUse hooks for edit verification** (in `docs/decisions.md`)
and the full design in `workitems/plans/diff-verification-hook.md`.

How the pair works:

- **`snapshot-before-edit.sh`** fires *before* the edit, copies the target file's current bytes to
  `${TMPDIR}/claude-diff-verify/<session_id>/<path-hash>.<tool_use_id>.snap` (outside the repo, so
  snapshots never enter `git diff` or get committed), plus a `.meta` sidecar. New files get an empty
  baseline marked `existed=no`. Files over 5 MB are skipped (a guard, since the hook also fires on
  large non-repo / git-ignored files).
- **`verify-diff.sh`** fires *after* the edit, diffs the snapshot against the current bytes, emits a
  compact summary (hard-capped well under the 10,000-char hook-output limit), and deletes its own
  snapshot. No matching snapshot → it stays silent.

Both are **fail-open**: any internal error emits nothing and exits 0 — a broken verifier must never
block a real edit. Snapshots are written with raw shell (`cp`/redirection) only, never Claude's
Edit/Write tools, so the snapshot write cannot re-trigger the hooks (no infinite loop). `git` is not
involved at any point, so the diff works for tracked, untracked, and git-ignored files alike.

`NotebookEdit` is deliberately **excluded** from the matcher: it carries `notebook_path` (not
`file_path`) and its `.ipynb` payloads are JSON whose raw diffs are noisy; this repo has no
notebooks. `Edit`, `Write`, and `MultiEdit` all expose `file_path`, so the pair handles them
uniformly.

> **Activation requires a fresh session.** Claude Code snapshots hook config at startup and does not
> reliably hot-reload edits to `.claude/settings.json` mid-session (there is no `/reload` command as
> of this writing). After these hooks are first added — or after any change to them — start a new
> Claude Code session for them to take effect.

> **Collaborator trust model.** Project-scope `command` hooks in a cloned repo are **not** run
> silently. Claude Code prompts for approval before executing project hooks (the defense against a
> malicious hook committed to a repo). A collaborator cloning vyasa will be asked to approve these
> two hooks on first use; they do not auto-run untrusted.

Prior Claude Code hook history: default-rule loading once lived here as a `SessionStart` hook
(`load-default-rules.sh`), but it hit Claude Code's ~10K-char hook-stdout cap and only ~1 of the 6
shards reached context. It was replaced by a `CLAUDE.md` → `@rules/README.md` → shard `@import` chain,
which expands the full shard bodies at launch with no cap. See decision
**D18 — Rule-loading moves from SessionStart hook to CLAUDE.md @import** (in `docs/decisions.md`) and `rules/README.md`.

## One-time setup (per clone)

Git ignores tracked hooks by default — `.git/hooks/` is not version-controlled. Point git at this directory instead:

```bash
git config core.hooksPath hooks
```

Verify with:

```bash
git config --get core.hooksPath   # should print: hooks
```

Default-rule loading needs no per-clone setup — it rides on the `@import` chain in `CLAUDE.md`/`rules/README.md`, which Claude Code expands automatically. Confirm it works by starting a fresh session and checking the default shards are present in context.

## Bypassing

`git commit --no-verify` skips both git hooks. Per the universal honesty rules in `~/.claude/CLAUDE.md`:

- **Assistants must not use `--no-verify` without explicit user permission.** If a hook fails, fix the underlying issue.
- **Humans use it at their own discretion**, typically only when the hook itself is the bug.

## When the rules change

The hooks are version-controlled alongside the rules they enforce. When `rules/git-workflow.md` changes, update the relevant hook in the same commit so spec and enforcement stay aligned.
