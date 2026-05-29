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
  - `Touches: D<N> — <title>` footer when README.md is not staged, or when the footer's title does not match the staged README's `### D<N>. <title>` heading

- **`pre-commit`** — blocks direct commits on `main` (per branch-per-workitem). Allows merge commits in progress (e.g., from `git pull`).

### Claude Code hooks (wired via `.claude/settings.json`)

- **`load-default-rules.sh`** — `SessionStart` hook. Parses the **Default-load** section of `rules/INDEX.md` (the single source of truth) and prints the concatenated shards to stdout, which Claude Code injects into the session's starting context. Guarantees the always-on rules load every session instead of depending on Claude following the `CLAUDE.md` → `rules/INDEX.md` → shard read-chain. Re-runs on `startup|resume|clear|compact`, so the rules refresh after compaction (a `(refreshed post-compaction)` marker is added when `source == "compact"`). The script resolves the repo root from its own path, so cwd does not matter. Missing-shard listings are surfaced on stderr but do not abort the load.

## One-time setup (per clone)

Git ignores tracked hooks by default — `.git/hooks/` is not version-controlled. Point git at this directory instead:

```bash
git config core.hooksPath hooks
```

Verify with:

```bash
git config --get core.hooksPath   # should print: hooks
```

The `load-default-rules.sh` hook needs no per-clone setup — it activates from the checked-in `.claude/settings.json`. Confirm it runs by starting a fresh session and checking the default shards are present in context.

## Bypassing

`git commit --no-verify` skips both git hooks. Per the universal honesty rules in `~/.claude/CLAUDE.md`:

- **Assistants must not use `--no-verify` without explicit user permission.** If a hook fails, fix the underlying issue.
- **Humans use it at their own discretion**, typically only when the hook itself is the bug.

## When the rules change

The hooks are version-controlled alongside the rules they enforce. When `rules/git-workflow.md` changes, update the relevant hook in the same commit so spec and enforcement stay aligned.
