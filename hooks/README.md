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

None currently. Default-rule loading used to live here as a `SessionStart` hook
(`load-default-rules.sh`), but that hook hit Claude Code's ~10K-char hook-stdout cap and
only ~1 of the 6 shards reached context. It was replaced by a `CLAUDE.md` → `@rules/INDEX.md`
→ shard `@import` chain, which expands the full shard bodies at launch with no cap. See
README decision **D18 — Rule-loading moves from SessionStart hook to CLAUDE.md @import** and
`rules/INDEX.md`. (`.claude/settings.json` is now an empty `{}`.)

## One-time setup (per clone)

Git ignores tracked hooks by default — `.git/hooks/` is not version-controlled. Point git at this directory instead:

```bash
git config core.hooksPath hooks
```

Verify with:

```bash
git config --get core.hooksPath   # should print: hooks
```

Default-rule loading needs no per-clone setup — it rides on the `@import` chain in `CLAUDE.md`/`rules/INDEX.md`, which Claude Code expands automatically. Confirm it works by starting a fresh session and checking the default shards are present in context.

## Bypassing

`git commit --no-verify` skips both git hooks. Per the universal honesty rules in `~/.claude/CLAUDE.md`:

- **Assistants must not use `--no-verify` without explicit user permission.** If a hook fails, fix the underlying issue.
- **Humans use it at their own discretion**, typically only when the hook itself is the bug.

## When the rules change

The hooks are version-controlled alongside the rules they enforce. When `rules/git-workflow.md` changes, update the relevant hook in the same commit so spec and enforcement stay aligned.
