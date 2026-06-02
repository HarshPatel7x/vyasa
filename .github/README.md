# .github

> GitHub-side automation for vyasa. Today this is one thing: the **PR-format CI check**
> that enforces `rules/git-workflow.md` at the pull-request layer, server-side, where a
> local `--no-verify` cannot bypass it.

## What lives here

```
.github/
├── README.md                       # this file
├── workflows/
│   └── pr-format-check.yml          # the GitHub Actions workflow (thin wrapper)
└── scripts/
    └── pr-format-check.sh           # the validation logic (title | body | commits)
```

- **`workflows/pr-format-check.yml`** — runs on every `pull_request` (`opened`, `edited`,
  `synchronize`, `reopened`). One job, three named steps (title / body / commits) so a red ✗
  names which target failed. Read-only token; plain `pull_request` (never
  `pull_request_target`); locale pinned to `C.UTF-8` so perl's character counting matches the
  local hook; `fetch-depth: 0` so the commit-range validation can resolve `base..head`.
- **`scripts/pr-format-check.sh <mode>`** — the actual checks, hand-rolled in `bash` so the
  title and per-commit rules stay byte-identical to `hooks/commit-msg` (one source of truth,
  no third-party action to drift against). Modes:
  - `title` — validates `$PR_TITLE` against the same subject rules as `hooks/commit-msg`
    (type set, optional scope whitelist, ≤72 UTF-8 chars, no trailing period).
  - `body` — asserts the six required headings are present in `$PR_BODY` (`## Summary`,
    `## Why`, `## Workitem`, `## Decisions touched`, `## Verification`, `## Followups`);
    presence only, order-agnostic, content not inspected.
  - `commits` — runs the **real `hooks/commit-msg`** over each non-merge commit in
    `$BASE_SHA..$HEAD_SHA`, in CI mode (`COMMIT_REF="<sha>:"`) so its `Touches: D<N>` footer
    check resolves `docs/decisions.md` from each commit's own tree. Merge commits are exempt
    (`git rev-list --no-merges`) — GitHub generates their subjects server-side.

## How CI reuses the local hook (the COMMIT_REF seam)

The CI commits-check does **not** reimplement the commit-message rules — it invokes
`hooks/commit-msg` directly. The only thing in that hook that cannot run server-side is the
`Touches:` block's reliance on the staging *index* (which does not exist for an already-made
commit in a fresh checkout). The hook exposes a `COMMIT_REF` seam: unset → `:` (the index,
local default, behavior unchanged); set to `<sha>:` → the hook resolves changed files and the
`docs/decisions.md` blob from that commit's tree instead. See `hooks/README.md` and the design in
`workitems/plans/pr-format-check.md` (decision E-seam).

## Note on the README convention

`rules/readme-convention.md` requires every directory to carry a `README.md`. Under that rule
`.github/` is a **leaf** directory (it holds CI artifacts, not sub-docs), so this one README is
the documentation for the whole CI surface — `workflows/` and `scripts/` are not separately
documented. This was settled by `D22 — README-as-router: retire INDEX.md, shard root README into
docs/`, whose leaf-vs-routing trichotomy makes a single leaf README the correct shape here; it had
been flagged provisionally beforehand (see decision C in `workitems/plans/pr-format-check.md`).

## Local testing

There is no Actions runner locally (`act`/`actionlint` are not installed in this
environment). The script is exercised by driving it with hand-made env inputs and asserting
exit codes — good/bad titles (wrong type, bad scope, >72 chars, trailing period, CRLF),
good/missing/empty bodies, and a `commits` range that includes a merge commit (to confirm the
exemption). Run a mode directly, e.g.:

```bash
PR_TITLE="feat(hooks): add a thing" bash .github/scripts/pr-format-check.sh title
```
