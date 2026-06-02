# Plan — CI workflow polish (pr-format-check.yml)

> Workitem: **CI workflow polish** — a trivial two-tweak bundle on the existing PR-format-check
> GitHub Actions workflow. Shipped on the fly (agreed + completed in one exchange), logged in
> [`../done.md`](../done.md). Branch: `workitem/ci-workflow-polish`.
> Status: built + shipped (2026-06-01); live workflow run watched on the introducing PR.

---

## Problem

Two small defects in `.github/workflows/pr-format-check.yml`, the server-side PR-format check:

1. **Only the first failing target is reported.** The three validation steps ("Validate PR title",
   "Validate PR body", "Validate commit messages") run sequentially with no step-level condition. In
   GitHub Actions the default is that a failed step aborts the remaining steps in the job. So if the
   PR *title* is malformed, the body and commit-message checks are SKIPPED — the author fixes the
   title, re-pushes, and only then learns the body was also wrong. Each round trip surfaces just one
   problem. We want every target checked and reported in a single run.

2. **`actions/checkout@v4` raises a Node-20 deprecation warning.** Cosmetic, but it clutters every
   run's annotations. `@v5` clears it.

## The two changes

Both are in `.github/workflows/pr-format-check.yml`. No other file changes the workflow needs (this
is a tweak to the *existing* enforcement, not a new or modified structural decision — so no
`README.md` change, no `Touches:` footer, no new D-entry).

### 1. Run all three validation steps independently

Add `if: ${{ !cancelled() }}` to each of the three validation steps. With that condition a step runs
regardless of whether an *earlier* step failed, so all three targets get validated and reported in
one run. Checkout deliberately does NOT get the condition — the validation steps depend on the
checkout having succeeded, so if checkout fails they should still be skipped.

#### Why `!cancelled()` and not `always()`

`always()` would force the step to run **even when the whole run is cancelled**. This workflow already
sets `concurrency: cancel-in-progress: true`, which supersedes an in-flight run when a newer event
arrives for the same PR. `always()` would fight that — the cancelled run's steps would keep executing,
wasting a runner and defeating the cancel. `!cancelled()` is the targeted choice: it runs the step on
success *or* on failure-of-prior-steps, but still bows out when the run is genuinely cancelled. That
is exactly the "report every target, but respect cancellation" behavior we want.

### 2. Bump checkout to v5

`actions/checkout@v4` → `actions/checkout@v5`. Keep `fetch-depth: 0` (needed so `BASE..HEAD` commit
ranges resolve). No other `with:`/`env:` changes.

## Out of scope (explicitly unchanged)

`fetch-depth: 0`, the job `env` (`LC_ALL` / `LANG` locale pin), `permissions`, `concurrency`, and the
three steps' own `env` blocks — all left exactly as-is.

## How verified

- **YAML still parses:** `ruby -ryaml -e 'YAML.load_file(".github/workflows/pr-format-check.yml")'`
  → `YAML OK` (python `yaml` is absent on this machine; ruby used instead).
- **Structural greps:** `if: ${{ !cancelled() }}` present on exactly the three validation steps and
  NOT on Checkout; `actions/checkout@v5` replaced `@v4` with no `@v4` remaining.
- **No live Actions run from here:** `actionlint` / `act` are not installed locally, so the genuine
  end-to-end behavior (all three targets reported on a failing PR) is watched on the introducing PR's
  live workflow run by the orchestrator.
