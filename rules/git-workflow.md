---
WHAT: PR, commit-message, and PR-description conventions. Enforced by git hooks in `hooks/`.
LOAD: Default — every session.
---

# Git workflow

## When to open a PR

Every workitem branch ships via a GitHub pull request.

- One workitem → one branch → one PR. Branch name: `workitem/<short-name>`.
- Trivial-bundle exception per `rules/workitems.md` allows multiple items per branch by explicit in-conversation decision; in that case, one PR still, listing all items.
- Self-merge is fine. No required review delay, no approval gate — this is a solo project. The PR is the artifact (the rollback unit, the description carrier, the diff view), not the gate.
- **Direct commits to `main` are not allowed.** Enforced by `hooks/pre-commit`. The bootstrap exception in earlier `rules/workitems.md` versions is retired.

## Commit message format

Standard: Conventional Commits with vyasa-specific scopes. Enforced by `hooks/commit-msg`.

### Subject line

```
<type>(<scope>): <imperative summary, no trailing period, ≤72 chars>
```

**Allowed `<type>`:** `feat`, `fix`, `docs`, `refactor`, `chore`, `test`, `eval`.

**Allowed `<scope>`** (optional — choose the one closest to the change):

- Rules / notes surfaces: `rules`, `notes`, `readme`, `workitems`, `hooks`
- Eval-harness surfaces (once code lands): `cli`, `skills`, `fixtures`, `runs`, `reports`
- Omit for cross-cutting changes that span surfaces.

### Body (optional)

- Wrap at ≤100 chars per line (loose limit; URL-only lines and standard trailer-style footer lines like `Touches:` and `Closes-workitem:` are exempt).
- Explain WHY the change is being made, not WHAT — the diff already shows what.

### Footers (when applicable)

Footers follow standard git trailer syntax: `<Token>: <value>` where `<Token>` is a single CamelCase or hyphenated word (no spaces). The hook exempts any line matching this shape from the body line-length cap.

- **`Closes-workitem: <verbatim bullet text from workitems/open.md (or workitems/done.md)>`** — optional on individual commits; required at PR level via the `## Workitem` section of the PR description.
- **`Touches: D<N> — <title verbatim from README>`** — required when the commit creates or modifies a structural decision in `README.md`'s Decisions log. The hook verifies that `README.md` is in the commit AND that the footer's title exactly matches the heading title for `D<N>` in the staged `README.md`.

### `Co-Authored-By` trailer (honor system)

When AI assisted the commit, include the appropriate trailer (Claude Code's default is `Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>`). The hook does NOT block on missing trailers — it cannot reliably detect AI involvement.

### Inline D-code expansion

Per `rules/voice.md`, every `D<N>` mention in the commit message must be followed inline by ` — <title>`. Enforced by the hook (em-dash `—` U+2014, not hyphen `-`).

## PR description format

### Title

Same shape as a commit subject: `<type>(<scope>): <summary>`. Single-commit PR → title equals that commit's subject. Multi-commit PR → title summarizes the bundle.

### Body template

```markdown
## Summary
<1–3 bullets — what changed>

## Why
<1–3 bullets — why this change is being made; motivation, not mechanics>

## Workitem
<verbatim quote(s) of the workitems/ ledger line(s) this closes — from workitems/open.md or workitems/done.md>

## Decisions touched
<list of `D<N> — title-verbatim-from-README`, or "none">

## Verification
<for rules: "self-applies from <date>"; for code: tests added or manual steps to confirm>

## Followups
<verbatim workitems/open.md bullets for any new items this work created, or "none">
```

## What gets enforced vs honor-system

| Rule                                                              | Enforcement                                              |
|-------------------------------------------------------------------|----------------------------------------------------------|
| Subject `<type>(<scope>): <summary>` format                       | hook (hard fail)                                         |
| Allowed types and scopes                                          | hook (hard fail)                                         |
| Subject ≤ 72 chars, no trailing period                            | hook (hard fail)                                         |
| Body line ≤ 100 chars (URLs exempt)                               | hook (hard fail)                                         |
| Inline D-code expansion in commit messages                        | hook (hard fail)                                         |
| `Touches: D<N>` footer correctness (README staged + title match)  | hook (hard fail)                                         |
| No direct commits to `main`                                       | hook (hard fail)                                         |
| `Co-Authored-By` trailer when AI assisted                         | honor system                                             |
| Imperative subject mood                                           | honor system                                             |
| WHY-not-WHAT in body                                              | honor system                                             |
| PR title + body format (+ per-commit msgs)                        | CI (hard fail) — `.github/workflows/pr-format-check.yml`  |
| `Closes-workitem:` link present at PR-merge time                  | honor system; the PR description's `## Workitem` carries it |

## Bypassing the hooks

Standard `git commit --no-verify` skips both hooks. Per the universal honesty rules:

- **Assistants must not use `--no-verify` without explicit user permission.** If a hook fails, fix the underlying issue.
- **Humans use it at their own discretion**, typically only when the hook itself is the bug.

## When the conventions change

Update `rules/git-workflow.md` AND the relevant enforcement script in the same commit so spec and enforcement stay aligned — that means the relevant `hooks/` script (local commit-time enforcement) and/or `.github/scripts/pr-format-check.sh` (PR-time CI enforcement), since the two share rules via the `COMMIT_REF` seam in `hooks/commit-msg`. Append a D-entry to `README.md` if the change is structural.
