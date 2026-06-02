# Plan — switch repo to squash-merge for structured mainline commits

> Workitem: **Switch repo to squash-merge for structured mainline commits** (from [`../open.md`](../open.md)).
> Status: **drafted, awaiting user sign-off.** Branch (for the eventual build): `workitem/squash-merge`.
> This file is a PLAN only — no GitHub setting is changed and no living spec (`rules/git-workflow.md`,
> `README.md`) is touched until the user signs off.

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

### Chosen — squash-merge, squash subject = PR title

Switch the repo's merge strategy to **squash merge**, and set the squash commit's *subject* to the
**PR title** (already validated by the `D20 — PR title + body format enforced via GitHub Actions CI`
check). Rationale:

- **Every commit on `main` becomes a structured, already-validated line** — the PR title — and the
  `Merge pull request #N from owner/branch` wording disappears entirely.
- **One PR = one commit on `main`.** This matches `rules/git-workflow.md`'s existing framing that
  "the PR is the artifact (the rollback unit…)": the rollback unit and the commit become the same
  thing, so reverting a PR is a clean atomic single-commit revert.
- **It is a one-time repo-settings change.** Once flipped, *every* future merge — whether done from
  the CLI or via the GitHub web "Merge" button — is squashed automatically, with no per-merge effort.
  (This is precisely why the "custom merge subject" option below was rejected: it would require
  remembering to set the subject on every merge, and the web button ignores it.)
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

### 2. Does the per-commit CI check (target 3 of the PR-format workflow) still earn its keep?

After squash, the squashed result on `main` is the PR title (target 1 of the workflow), so target 3
— re-validating *each non-merge commit message in the PR* — no longer guards anything that lands on
`main`.

**Recommendation: KEEP target 3.** It still earns its keep as **defense-in-depth during the PR**, not
on `main`:

- It gates commit-message hygiene *while the PR is open* — catching commits made via `git commit
  --no-verify` or through the GitHub web editor, neither of which the local `hooks/commit-msg` hook
  can reach. The in-PR commit history stays clean and conventional even though it gets squashed away.
- It costs nothing extra to keep — it is already wired and passing.

But this is **flagged honestly as a thing the user may want to reconsider**: a reasonable person could
argue that once the per-commit messages no longer reach `main`, validating them is lower-value and
could be dropped to simplify the workflow. The plan's recommendation is keep-as-defense-in-depth, but
the decision is surfaced for the user, not silently made.

## Implementation steps (for the LATER build — not executed now)

These run only after the user signs off. Owner/repo is `HarshPatel7x/vyasa`.

**(a) Flip the GitHub repo merge settings.** Disable merge commits, enable squash as the only merge
strategy, disable rebase merge, and set the squash commit *title* to the PR title and the squash
commit *message body* to the PR body (so the structured PR description carries into the commit body).

```bash
# Merge-strategy toggles (squash only):
gh repo edit --enable-merge-commit=false --enable-squash-merge=true --enable-rebase-merge=false

# Squash commit subject/body sources — title = PR title, body = PR description:
gh api repos/HarshPatel7x/vyasa -X PATCH \
  -f squash_merge_commit_title=PR_TITLE \
  -f squash_merge_commit_message=PR_BODY
```

Note on the body source: `squash_merge_commit_message` accepts `PR_BODY` (the PR description) or
`COMMIT_MESSAGES` (the concatenated branch commit messages). **Choose `PR_BODY`** so the structured,
six-section PR description (already validated by the `D20 — PR title + body format enforced via
GitHub Actions CI` check) becomes the commit body, rather than a raw dump of in-PR commit messages.

**(b) Update `rules/git-workflow.md`** — the "When to open a PR" section. Add that the repo merge
strategy is **squash** (squash subject = PR title, squash body = PR description), and explain why: one
PR → one structured, already-validated commit on `main`; the rollback unit and the commit become the
same thing. (Living spec — gets updated; the old session note does not.)

**(c) Append the next decision entry to `README.md`'s Decisions log** —
`D21 — Squash-merge so every mainline commit is structured` (next free number; highest existing is
`D20`). Capture the chosen option, the two rejected options briefly, and the consequence that
per-commit messages no longer land on `main` (superseding the merge-commit assumption in the
2026-06-01 note). The commit that adds this must carry the `Touches: D21 — Squash-merge so every
mainline commit is structured` footer per the hook rules.

**(d) Do NOT edit the old session note.** `notes/2026-06-01-pr-format-ci-enforcement.md` stays as-is
— a historical record, superseded by `D21`, not rewritten (see Honest consequence 1).

**(e) Decide target-3 of the PR-format workflow.** Per Honest consequence 2 the recommendation is to
**keep** it (defense-in-depth during the PR). If the user instead chooses to drop it, that becomes its
own change to `.github/scripts/pr-format-check.sh` + the workflow + the `rules/git-workflow.md`
enforcement table — out of scope for this plan unless the user asks.

## Verification (for the LATER build)

- **Read the settings back** after flipping them:

  ```bash
  gh api repos/HarshPatel7x/vyasa --jq '{merge:.allow_merge_commit, squash:.allow_squash_merge, rebase:.allow_rebase_merge, title:.squash_merge_commit_title, message:.squash_merge_commit_message}'
  ```

  Expect `merge:false, squash:true, rebase:false, title:"PR_TITLE", message:"PR_BODY"`.

- **Confirm on the first real merge:** the FIRST PR merged after the switch shows, on `main`, a
  **structured one-line commit subject equal to the PR title** with **no `Merge pull request` line**
  (`git log --oneline main | head -3`).

- **Spec/enforcement alignment:** `rules/git-workflow.md` describes squash-merge and `README.md`
  carries `D21 — Squash-merge so every mainline commit is structured`, both shipped in the build PR.
