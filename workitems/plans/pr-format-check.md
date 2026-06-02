# Plan — PR-side CI format enforcement

> Workitem: **PR-side CI enforcement** (from [`../open.md`](../open.md)).
> Status: planned, ready to build. Branch: `workitem/pr-format-check`.
> This plan was hardened by a 3-agent debate (critic / improver / auditor) on 2026-06-01;
> the decisions below fold in their findings.

---

## Problem

PR title and PR body format are currently **honor-system only**. The local `hooks/commit-msg`
hook enforces *commit* message format, but:

- It only runs locally, and is bypassable (`git commit --no-verify`, commits made through the
  GitHub web UI, or a clone that never ran the `core.hooksPath` setup in `hooks/README.md`).
- Nothing at all checks the **PR title** or **PR body** — `git-workflow.md`'s enforcement
  table literally says `PR title + body format | honor system today; CI enforcement is a
  queued workitem`.

This workitem adds a GitHub Actions check that enforces format at the PR layer, server-side,
where it cannot be bypassed by a local flag.

## Scope (what the CI validates)

Three targets on every PR:

1. **PR title** — Conventional-Commits subject shape `<type>(<scope>): <summary>`, identical
   rules to `commit-msg`'s subject checks: type ∈ {feat, fix, docs, refactor, chore, test,
   eval}; optional scope ∈ {rules, notes, readme, workitems, hooks, cli, skills, fixtures,
   runs, reports}; ≤72 **UTF-8 characters**; no trailing period.
2. **PR body** — all six headings present: `## Summary`, `## Why`, `## Workitem`,
   `## Decisions touched`, `## Verification`, `## Followups`. **Presence only, order-agnostic,
   content not inspected** (decision below).
3. **Each non-merge commit message in the PR** — the full `commit-msg` ruleset (subject shape,
   body line ≤100, inline D-code em-dash expansion, `Touches: D<N>` footer correctness).
   **Merge commits are exempted** (`git rev-list --no-merges`), since GitHub generates their
   subjects server-side and they cannot conform.

Target 3 was added in-conversation on 2026-06-01, beyond the originally-written workitem
(title + body only); the `open.md` item text is updated to match (decision L below).

## Options considered + decisions

### Decision E (architecture) — how to share the commit-msg rules with CI, without drift

The local hook and the CI must apply **identical** message rules, or they silently diverge —
the exact failure mode `D16` bundled spec+enforcement to prevent.

- **E1 (rejected)** — extract the validation core into a new `hooks/lib/check-message.sh`,
  rewire the local hook to call it, have CI call it too. Zero drift, but: refactors a working,
  3×-audited hook; adds a new directory + its mandated README; larger blast radius.
- **E2 (rejected)** — CI keeps its own copy of the rules + a documented "update both together"
  guard. No refactor, but parity is honor-system — reintroduces the drift escape valve.
- **E-seam (CHOSEN)** — the only thing in `commit-msg` that can't run in CI is the `Touches:`
  block's reliance on the **staging index**: `git diff --cached --name-only` (line 90) and
  `git show :README.md` (line 98). Both read the index, which does not exist for an
  already-made commit in a CI checkout. Replace those two reads with a `COMMIT_REF`
  indirection that defaults to today's behavior locally and takes a commit SHA in CI:

  ```bash
  COMMIT_REF="${COMMIT_REF:-:}"   # ":" = staged index (local default, behavior unchanged)
  readme_changed() {
    if [[ "$COMMIT_REF" == ":" ]]; then git diff --cached --name-only
    else git diff-tree --no-commit-id --name-only -r "$COMMIT_REF"; fi
  }
  readme_blob() { git show "${COMMIT_REF}README.md" 2>/dev/null; }   # ":README.md" | "<sha>:README.md"
  ```

  One file, one source of truth, local behavior byte-identical, no new library. CI invokes the
  same `commit-msg` with `COMMIT_REF=<sha>:` and the message piped through a temp file.

  This was the central correctness fix from the debate: the original plan claimed CI could
  reuse the core as-is, but the index-coupling made that false. The seam makes the
  index-vs-commit difference explicit instead of duplicating logic.

### Decision A — validation logic in a script, workflow YAML is a thin wrapper. **One** script
`.github/scripts/pr-format-check.sh <mode>` with `mode ∈ {title, body, commits}`, invoked as
**three separate named steps** in one job, so a red ✗ names which target failed (debate:
better attribution than one blended check; cheaper than three jobs).

### Decision B — hand-rolled, no third-party action. Justified **because** the title and
per-commit checks must stay byte-identical to the shell rules already enforced by `commit-msg`
(not as blanket "trust nothing external"). A third-party title-only action would fragment the
single source of truth.

### Decision C — one `.github/README.md` for the whole CI surface (not one per subdir).
Justified by the `hooks/` precedent (a code/config dir carries one README; it does not shard
further). Noted tension: the *literal* `readme-convention.md` rule says "every directory"; the
not-yet-done "Tweak readme-convention.md" workitem is exactly what would bless this. Documented,
not silently skipped.

### Decision D — add **D20 — PR title + body format enforced via GitHub Actions CI** to the
README Decisions log (appended after D19, chronological-append convention). Update
`git-workflow.md`: flip the enforcement-table cell, and extend the "When the conventions change"
line to also name `.github/scripts/pr-format-check.sh`.

### Decision (body strictness) — **presence, any order, content not inspected.** `git-workflow.md`
shows the six sections in an order but never *requires* that order; deeper content checks
(e.g. non-empty Workitem) are honor-system. Presence-only is the faithful scope.

### Decision L (ledger) — **update the existing workitem's text** in `open.md` to include
per-commit validation, then close it as one coherent item (rather than splitting).

## Implementation steps

1. **Seam the hook.** Patch `hooks/commit-msg`: add the `COMMIT_REF` default + `readme_changed`
   / `readme_blob` helpers; replace line-90 and line-98 reads with the helpers. Local default
   reproduces current behavior exactly.
2. **Local regression test.** Feed good + bad messages to `commit-msg` with no `COMMIT_REF`
   set; confirm identical pass/fail to pre-patch. Then feed a message with `COMMIT_REF=<sha>:`
   against a real commit and confirm the Touches check resolves README from the commit tree.
3. **CI script.** Write `.github/scripts/pr-format-check.sh`:
   - `title`  — run the subject portion of the rules against `$PR_TITLE` (CR-stripped).
   - `body`   — assert the six `## ` headings are present in `$PR_BODY` (guard `${PR_BODY:-}`).
   - `commits`— `git rev-list --no-merges <base>..<head>`; for each SHA, pipe its message to
     `commit-msg` with `COMMIT_REF=<sha>:`.
4. **Workflow.** Write `.github/workflows/pr-format-check.yml`:
   `on: pull_request: types: [opened, edited, synchronize, reopened]`;
   `permissions: { contents: read, pull-requests: read }`; plain `pull_request` (never
   `pull_request_target`); `concurrency: { group: pr-format-${{ github.event.pull_request.number }},
   cancel-in-progress: true }`; one job, `actions/checkout` with `fetch-depth: 0`;
   `env: { LC_ALL: C.UTF-8, LANG: C.UTF-8 }`; three steps (title / body / commits) passing
   title/body/SHAs in via env.
5. **Docs + conventions.** `.github/README.md`; update `hooks/README.md` (document the
   `COMMIT_REF` seam + that CI reuses the hook); flip the `git-workflow.md` table cell + the
   "when conventions change" line; append **D20** to `README.md`; add the `plans/INDEX.md`
   bullet; add `.github/` to the README structure tree (optional polish).
6. **Close the item.** Move the (text-updated) workitem from `open.md` to `done.md` with
   `→ plan: [plans/pr-format-check.md]` and the branch/commit recorded.

## Verification

- **Hook unchanged (local):** step-2 regression — good messages pass, bad ones fail, identical
  to pre-seam behavior. The commit that introduces D20 carries `Touches: D20 — …` and must pass
  the *seamed* hook locally (default index mode).
- **CI script (local, no Actions runner — `act`/`actionlint` not installed here):** drive
  `pr-format-check.sh` with hand-made good/bad inputs for each mode (em-dash D-code case
  included, empty-body case, CRLF-title case, a merge SHA to confirm exemption) and assert exit
  codes — same style as the diff-verification hook's 22 hand-made cases.
- **Live:** the introducing PR is made fully conformant (title/body/commits) so it passes
  regardless of whether GitHub runs the new workflow on its own PR (an unresolved factual point
  between the debate agents — confirmed empirically when it runs). The first clearly-exercising
  run is watched go green, then a deliberately-bad fixup is pushed to watch it go red, then fixed.

## Notes from the debate (for the record)

- **Squash-merge concern (raised, dismissed by fact):** vyasa uses **merge commits** (PRs
  #9/#10/#11 are real merge commits), so per-commit messages land on `main` and per-commit
  validation is meaningful — not theater. If the repo ever switches to squash-merge, target 3
  becomes moot (the squash subject = PR title, already covered by target 1).
- **Operational must-haves the v1/v2 plan omitted:** `fetch-depth: 0`, `types: [edited]`,
  locale pinning, `${BODY:-}` guard against `set -u`, CR strip, read-only token. All folded in.
