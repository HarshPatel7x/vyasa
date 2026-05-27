# hooks

> Git hooks that enforce the conventions in `rules/git-workflow.md`. Version-controlled so they travel with the repo.

## What lives here

- **`commit-msg`** — validates the commit message format. Hard-fails on:
  - Subject not matching `<type>(<scope>): <summary>` with type in the whitelist
  - Scope not in the whitelist (if a scope is provided)
  - Subject longer than 72 chars or ending with a period
  - Body line longer than 100 chars (URL-only lines exempt)
  - Any `D<N>` mention not followed inline by ` — <title>` (em-dash U+2014)
  - `Touches: D<N> — <title>` footer when README.md is not staged, or when the footer's title does not match the staged README's `### D<N>. <title>` heading

- **`pre-commit`** — blocks direct commits on `main` (per branch-per-workitem). Allows merge commits in progress (e.g., from `git pull`).

## One-time setup (per clone)

Git ignores tracked hooks by default — `.git/hooks/` is not version-controlled. Point git at this directory instead:

```bash
git config core.hooksPath hooks
```

Verify with:

```bash
git config --get core.hooksPath   # should print: hooks
```

## Bypassing

`git commit --no-verify` skips both hooks. Per the universal honesty rules in `~/.claude/CLAUDE.md`:

- **Assistants must not use `--no-verify` without explicit user permission.** If a hook fails, fix the underlying issue.
- **Humans use it at their own discretion**, typically only when the hook itself is the bug.

## When the rules change

The hooks are version-controlled alongside the rules they enforce. When `rules/git-workflow.md` changes, update the relevant hook in the same commit so spec and enforcement stay aligned.
