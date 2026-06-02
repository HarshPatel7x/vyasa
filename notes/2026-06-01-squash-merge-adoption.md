# 2026-06-01 — Adopt squash-merge for a structured mainline history

> Session minutes. Switched the repo to **squash-merge** so every commit on `main` is one
> structured, already-validated line (the PR title) instead of GitHub's unstructured
> `Merge pull request #N from owner/branch` wording — `D21 — Squash-merge so every mainline
> commit is structured`. Includes a 3-agent debate, a survived mid-task tool lockout, and a
> deliberate "last merge commit, then flip" cutover. Shipped via PR #16.

---

## What set this off

The user noticed the `Merge pull request #N from owner/branch` lines GitHub writes on every
merge — unstructured, no Conventional-Commits shape, validated by nothing — and said they'd
prefer a structured message. We already validate the **PR title** server-side
(`D20 — PR title + body format enforced via GitHub Actions CI`) to the exact commit-subject
shape, so a validated one-liner for every PR already exists; it just never became the commit
on `main`. Squash-merge makes it the commit.

## What we decided

**Squash-merge**, squash subject = PR title, squash body = **blank**, merged branches
auto-delete. Options weighed and rejected:
- **Rebase merge** — lands every branch commit on `main` individually; loses the PR grouping
  and makes a PR messier to revert as a unit. The "PR is the rollback unit" framing favours squash.
- **Keep merge commits + a custom subject** — manual per-merge effort, drift-prone, and the
  GitHub web "Merge" button ignores a custom subject. Squash gets the outcome automatically
  for both CLI and web merges, zero recurring effort.

Body source was a real fork: `BLANK` (cleanest `git log`; full description lives on the PR
page) vs `COMMIT_MESSAGES` (keeps per-commit detail on `main`) vs `PR_BODY` (the six-section
template in every commit body — verbose). Chose **BLANK** — consistent with the island rule
that "GitHub is the only durability layer," so the PR page is the description's native home.

## What happened, in order

1. **Drafted the plan via a background agent**, then the user asked for the same 3-agent
   debate (critic / improver / auditor) that hardened the PR-format CI plan. It earned its keep
   again — findings that changed the build:
   - **Command bug (critic verified live with `gh repo edit --help`):** `gh repo edit` has **no
     flag to set the squash *title* source** — only a `gh api … -f squash_merge_commit_title=PR_TITLE`
     PATCH does. The repo's live setting was `COMMIT_OR_PR_TITLE`, which for a single-commit PR
     uses the commit subject, not the PR title — so without the API call the headline outcome
     would have silently failed. The API PATCH is load-bearing.
   - **The `(#N)` suffix:** GitHub appends ` (#N)` to the squash subject, so the line on `main`
     is `<PR title> (#N)`, not the bare title. Embraced (free PR traceability), with the caveat
     that a ~72-char title overshoots 72 on `main` — accepted, because the mainline subject is
     never CI-validated anyway (CI runs on `pull_request`, not on pushes to `main`).
   - **A now-false sentence in the bible:** the `D20 — PR title + body format enforced via
     GitHub Actions CI` entry literally said "vyasa uses real merge commits (not squash)…" —
     squash falsifies it. Annotated (not deleted) with a `*(Superseded by D21 …)*` note, same
     precedent as the existing D15→D17 supersede annotation.
   - **Trailer handling:** after squash, GitHub auto-preserves `Co-authored-by` (it derives
     co-author trailers from the squashed commits), so AI co-authorship *does* reach `main`; only
     non-authorship trailers like `Touches: D<N>` are dropped. The local `hooks/commit-msg` still
     enforces `Touches:` at commit time, so the discipline holds — only the mainline `Touches:`
     artifact is lost. (Confirmed empirically: PR #17's squash commit on `main` carried its
     `Co-authored-by` line — which is what corrected this claim.)
   - **Missing ledger move** and the `git-workflow.md` "PR is the rollback unit" line — both
     folded into the touch-list.
2. **Survived a mid-task tool lockout.** Partway through, the shell's working-directory handle
   broke — every `git` command failed with `fatal: Unable to read current working directory:
   Operation not permitted` (a sandbox / `getcwd()` issue; file reads still worked). Rather than
   guess, we wrote a durable `RESUME-squash-merge.md` handoff into the repo (the Write tool uses
   absolute paths, so it worked where git couldn't), and the user restarted the terminal. A
   fresh shell fixed it; the uncommitted plan files had survived on disk, exactly as predicted.
3. **Built via an agent** (plan revision + `git-workflow.md` + the `D21` entry + the `D20`
   annotation + the ledger move), with the `Touches: D21 — Squash-merge so every mainline
   commit is structured` footer on the README commit.
4. **Shipped via PR #16 with a deliberate cutover.** Merged PR #16 as a normal **merge commit**
   — the *last* one — so its `Touches: D21` trailer landed on `main` (confirmed in history).
   *Then* flipped the GitHub settings to squash-only. Verified by reading the settings back:
   `merge:false, squash:true, rebase:false, delete_branch:true, sq_title:PR_TITLE, sq_msg:BLANK`.

## Decisions / departures

- **`D21 — Squash-merge so every mainline commit is structured`** added; the merge-commit clause
  of `D20 — PR title + body format enforced via GitHub Actions CI` annotated as superseded.
- **The per-commit CI check is KEPT** — its value shifts from "guards mainline history" to
  "defense-in-depth while the PR is open" (catches `--no-verify` / web-editor commits the local
  hook can't, and is the safety net if the merge strategy ever reverts). Honestly flagged as a
  thing the user may later reconsider.
- **The historical PR-format-CI session note was left unedited** — true when written, superseded
  by `D21`, not retroactively rewritten (per `rules/voice.md`).

## Lessons

- **The debate caught two real defects again, on paper:** a `gh` command that silently wouldn't
  set the squash title, and a flatly-false sentence left standing inside the README bible.
  Independent adversarial review keeps paying for itself.
- **Cutover order is a design choice, not an afterthought.** Merging the switch-on PR the *old*
  way one last time — then flipping — preserved the `D21` decision trailer on `main`. Flip-first
  would have squashed it away.
- **A tool lockout is survivable with a durable handoff.** Working-tree files outlive a terminal
  restart; writing a `RESUME` file (and not trusting the "are the files even still there?" panic)
  turned a hard stop into a clean continuation.

## State after this session

- `main` history is now structured going forward: PR #16's `Merge pull request #16…` is the
  **last** unstructured merge subject; from the next PR on, each lands as one squashed
  `<PR title> (#N)` line with a blank body, and the branch auto-deletes.
- `D21 — Squash-merge so every mainline commit is structured` is live in the README; the spec
  (`rules/git-workflow.md`) carries the strategy and the merge command, not just the GitHub
  setting.
- **First-squash confirmation:** the PR that ships *this very note* is the first real
  squash-merge — its mainline commit is the live proof the switch works end-to-end.
