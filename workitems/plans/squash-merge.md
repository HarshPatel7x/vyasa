# Plan — switch repo to squash-merge for structured mainline commits

> Workitem: **Switch repo to squash-merge for structured mainline commits** (from [`../open.md`](../open.md)).
> Status: signed off; building on branch `workitem/squash-merge`.
> This file is the (debate-hardened) build plan. The GitHub-side settings flip is performed by the
> human; the spec changes (`rules/git-workflow.md`, `README.md`) ship on this branch.

---

## Problem

Every time a PR merges today, GitHub writes a **merge commit** whose subject is its own
auto-generated wording — `Merge pull request #N from owner/branch`. That line lands on `main` and
is what `git log main` shows. It is unstructured: it carries no Conventional-Commits type/scope, no
summary of *what* the PR did, and it is not validated by anything.

Meanwhile the project already validates the **PR title** server-side (`D20 — PR title + body format
enforced via GitHub Actions CI`) to the exact Conventional-Commits subject shape used for commits.
So there is an already-validated, structured one-line description of every PR — the PR title — but it
never becomes the commit on `main`. The `Merge pull request…` wording wins instead.

The user wants `main`'s commit history to be structured: every mainline commit a validated,
meaningful line, with the `Merge pull request…` wording gone.

## Options considered + decision

### Chosen — squash-merge, squash subject = PR title, squash body = BLANK

Switch the repo's merge strategy to **squash merge**, set the squash commit's *subject* to the
**PR title** (already validated by the `D20 — PR title + body format enforced via GitHub Actions CI`
check), set the squash *body* to **blank**, and auto-delete merged branches. Rationale:

- **Every commit on `main` becomes a structured, already-validated line** — the PR title — and the
  `Merge pull request #N from owner/branch` wording disappears entirely.
- **Body = blank, chosen deliberately for a clean `git log`.** The alternative (carry the PR
  description into the commit body) was considered and rejected: it bloats `git log` with the
  six-section template on every line. The PR description still lives on the PR page; `main` stays a
  clean list of one-line subjects.
- **One PR = one commit on `main`.** The rollback unit and the commit become the same thing, so
  reverting a PR is a clean atomic single-commit revert.
- **It is a one-time repo-settings change.** Once flipped, *every* future merge — whether done from
  the CLI or via the GitHub web "Merge" button — is squashed automatically, with no per-merge effort.
- **In-PR commits are not lost.** The individual commits made on the branch remain visible on the PR
  page (the "Commits" tab) — squash only changes what lands on `main`, not the PR's own record.

### Rejected — rebase merge

Rebase merge lands *every* branch commit onto `main` individually. A PR with five commits becomes
five commits on `main`. That **loses the PR grouping** and makes a PR **messier to revert as a unit**
(you'd revert a range, not one commit). It conflicts with the "PR is the rollback unit" framing the
squash option preserves. Rejected.

### Rejected — keep merge commits + custom merge subject

Keep today's merge-commit strategy but type a structured subject on each merge. Rejected because it is
**manual per-merge effort** (drift-prone — easy to forget or fat-finger), and the **GitHub web "Merge"
button ignores a custom subject** entirely, so the discipline only holds for CLI merges. The squash
option gets the structured-subject outcome automatically for *both* merge paths with zero recurring
effort.

## The `(#N)` suffix on the mainline subject

GitHub appends ` (#N)` to a squash commit's subject. So the line on `main` is **`<PR title> (#N)`**,
not the bare PR title. This is **embraced**, not fought: the suffix gives free PR traceability — every
mainline commit links back to the PR that produced it.

Two caveats, both accepted:

- **(a) A PR title near 72 chars yields a mainline subject >72 chars.** A 72-char title plus ` (#N)`
  overshoots the 72-char cap on `main`.
- **(b) That overshoot is harmless because the mainline subject is NOT CI-validated anyway.** The
  PR-format workflow runs on `pull_request`, never on pushes to `main`. What CI validates is the PR
  *title* (pre-suffix); the suffixed mainline subject is never checked. So the ≤72 rule applies to the
  PR title, and the suffix on `main` is outside the validated surface.

## Honest consequences (do not gloss)

### 1. It partially undercuts a claim in an existing session note

`notes/2026-06-01-pr-format-ci-enforcement.md` records (from the design debate) that vyasa "merges
PRs with merge commits, so each commit's own message really does land on `main` — per-commit
validation is meaningful, not theater." After this switch, **per-commit messages no longer land on
`main`** — only the squashed PR-title subject does. So that specific justification weakens.

**Decision: do NOT rewrite that historical note.** It was true when written, and per `rules/voice.md`
old records are not retroactively edited — they are a historical record of what was believed at the
time. Instead:

- The **new decision entry** (`D21`, see implementation step c) supersedes it going forward.
- `rules/git-workflow.md` — the *living* spec — is what gets updated to describe squash-merge.

This supersede-don't-rewrite split is stated here so the build step doesn't "tidy up" the old note.

### 2. The per-commit CI check (target 3 of the PR-format workflow) is KEPT — rationale shifts

After squash, the squashed result on `main` is the PR title (target 1 of the workflow), so target 3
— re-validating *each non-merge commit message in the PR* — no longer guards anything that lands on
`main`. **It is kept anyway,** but its rationale moves from "the per-commit messages land on `main`"
to:

- **Defense-in-depth during the open PR / un-bypassable gate.** It gates commit-message hygiene
  *while the PR is open* — catching commits made via `git commit --no-verify` or through the GitHub
  web editor, neither of which the local `hooks/commit-msg` hook can reach.
- **A safety net if the strategy ever reverts** to merge commits.
- It costs nothing extra to keep — it is already wired and passing.

### 3. Trailer loss on `main`

After squash, the `Touches: D<N>` and `Co-Authored-By` trailers on the in-PR commits do **not** appear
on `main` — only the PR title (the squash subject) and a blank body land there. The local
`hooks/commit-msg` still enforces `Touches:` at commit time, so the *discipline* holds; only the
mainline *artifact* loses the trailer. Accepted as a cost of the clean-mainline goal.

### 4. README's D20 entry carries a now-false sentence — annotate, don't delete

`README.md`'s `D20 — PR title + body format enforced via GitHub Actions CI` entry asserts "vyasa uses
real merge commits (not squash), so per-commit messages land on `main` and validating them is
meaningful." After this switch that is false. It is **annotated inline** with a `*(Superseded by D21
— …)*` note (precedent: the existing `D15 — …` → `D17 — …` supersede annotation), **not deleted** —
the original stays as a historical record.

### 5. `rules/git-workflow.md`'s "PR is the artifact (rollback unit…)" line needs updating

That line framed the PR (not the commit) as the rollback unit. Under squash the rollback unit is now
literally the single squashed commit on `main`. The living spec is updated to say so.

## Implementation steps

Owner/repo is `HarshPatel7x/vyasa`. The spec changes (b–e below) ship on branch
`workitem/squash-merge`; the settings flip (a) is performed by the human.

**(a) Flip the GitHub repo merge settings (human-performed).** Disable merge commits, enable squash
as the only merge strategy, disable rebase merge, auto-delete merged branches, set the squash commit
*title* to the PR title and the squash commit *body* to **blank**.

```bash
# Merge-strategy toggles + auto-delete (squash only):
gh repo edit --enable-merge-commit=false --enable-squash-merge=true \
  --enable-rebase-merge=false --delete-branch-on-merge=true

# Squash commit subject/body sources — title = PR title, body = blank:
gh api repos/HarshPatel7x/vyasa -X PATCH \
  -f squash_merge_commit_title=PR_TITLE \
  -f squash_merge_commit_message=BLANK
```

**The `gh api` PATCH is load-bearing.** `gh repo edit` can toggle *which* merge strategies are
allowed and the branch-delete behavior, but it **cannot set the squash TITLE source** — only the
`gh api … PATCH` can. Without the PATCH the repo's live `squash_merge_commit_title` stays at its
current value `COMMIT_OR_PR_TITLE`, which for a **1-commit PR** would wrongly use the *commit* subject
instead of the PR title. The PATCH forcing `PR_TITLE` is what guarantees the PR title (the validated
line) is always the mainline subject.

**(b) Update `rules/git-workflow.md`** — the "When to open a PR" section. Add that the repo merge
strategy is **squash** (squash subject = PR title, squash body = blank, branch auto-deleted), and
explain why: one PR → one structured, already-validated commit on `main`; the rollback unit and the
commit become the same thing. Document the human merge command (`gh pr merge --squash
--delete-branch`, or the GitHub "Squash and merge" button) so the *spec* — not just the GitHub
setting — carries the strategy (island "spec is truth" ethos). Update the existing "PR is the
artifact (the rollback unit…)" line so it's truthful under squash (the rollback unit is the single
squashed commit). Confirm the enforcement table — squash does not change any cell (each rule is still
enforced at the same layer; squash only changes what lands on `main`).

**(c) Append the next decision entry to `README.md`'s Decisions log** —
`D21 — Squash-merge so every mainline commit is structured` (next free number; highest existing is
`D20`). Capture the chosen option (squash, subject = PR title, body = blank, auto-delete), the two
rejected options briefly, the embraced `(#N)` suffix + the >72-char-on-main caveat, the consequence
that per-commit messages no longer land on `main` (superseding the relevant `D20` clause and the
2026-06-01 note), and trailer loss on `main`. The commit that adds this must carry the `Touches: D21
— Squash-merge so every mainline commit is structured` footer per the hook rules and stage
`README.md` in the same commit.

**(d) Annotate (do NOT delete) the now-false D20 sentence.** Add `*(Superseded by D21 — …)*` inline
to the "vyasa uses real merge commits (not squash)…" sentence in the `D20` entry.

**(e) Do NOT edit the old session note.** `notes/2026-06-01-pr-format-ci-enforcement.md` stays as-is
— a historical record, superseded by `D21`, not rewritten (see Honest consequence 1).

**(f) Grep the CI script + `.github/README.md` for old-strategy rationale.** Check
`.github/scripts/pr-format-check.sh` and `.github/README.md` for any "merge commits land on
`main`"-style rationale tied to the old strategy and update it (the per-commit check is **kept**; its
rationale shifts to "defense-in-depth during the PR / un-bypassable gate / safety net if the strategy
reverts"). NOTE (build finding): the only stale rationale of that exact shape lives in `README.md`'s
`D20` entry (handled by step d). The CI script and `.github/README.md` only state that GitHub-generated
*merge-commit subjects* are exempt from the per-commit check — which stays true even under squash (the
build PR itself merges as a merge commit), so no edit was needed there.

**(g) Build-PR merge order.** This build PR is itself merged as a normal **merge commit** (so its
`Touches: D21 — Squash-merge so every mainline commit is structured` trailer lands on `main`); the
settings flip (step a) happens **after** that merge. This PR is the last merge-commit; the next PR is
the first squash.

## Verification

- **Read the settings back** after the human flips them:

  ```bash
  gh api repos/HarshPatel7x/vyasa --jq '{merge:.allow_merge_commit, squash:.allow_squash_merge, rebase:.allow_rebase_merge, delete_branch:.delete_branch_on_merge, title:.squash_merge_commit_title, message:.squash_merge_commit_message}'
  ```

  Expect `merge:false, squash:true, rebase:false, delete_branch:true, title:"PR_TITLE", message:"BLANK"`.

- **Confirm on the first real squash-merge:** the FIRST PR merged after the switch shows, on `main`, a
  commit subject equal to **`<PR title> (#N)`** (NOT the bare PR title — GitHub appends the ` (#N)`
  suffix) with **no `Merge pull request` line** (`git log --oneline main | head -3`).

- **Spec/enforcement alignment:** `rules/git-workflow.md` describes squash-merge and `README.md`
  carries `D21 — Squash-merge so every mainline commit is structured`, both shipped in this build PR.
