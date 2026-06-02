# 2026-06-01 — PR-format enforcement moves server-side (CI)

> Session minutes. Built, shipped, and live-verified a GitHub Actions check that enforces
> PR title + body + commit-message format on the server, where the local commit hook can't
> reach — `D20 — PR title + body format enforced via GitHub Actions CI`. Plus a 3-agent
> design debate, a drift-fix, and two follow-up polish tweaks. Shipped via PR #12 and PR #13.

---

## What we set out to do

Pick up the parked **PR-side CI enforcement** workitem. Until now, format rules were guarded
only by `hooks/commit-msg` — a *local git hook* (a script git runs on your own machine just
before recording a snapshot). That guard has holes: it can be skipped with `git commit
--no-verify`, it never runs on commits made through GitHub's web editor, and a fresh clone
that never ran the one-time setup in `hooks/README.md` doesn't have it at all. And nothing —
local or remote — ever checked the **PR title** or **PR body** at all.

The goal: a *CI check* (a script GitHub runs automatically on its own servers whenever a pull
request opens or changes) that validates three things server-side, where no local flag can
bypass it:

1. the **PR title** against the same Conventional-Commits subject shape the commit hook uses;
2. the **PR body** carrying all six required sections (`## Summary`, `## Why`, `## Workitem`,
   `## Decisions touched`, `## Verification`, `## Followups`);
3. **each non-merge commit message** in the PR, re-validated by the real `hooks/commit-msg`.

## What happened, in order

1. **Planned it; scope grew.** The original workitem was title + body only. During planning
   the user decided to also re-validate every non-merge commit message in the PR — merge
   commits exempted via `git rev-list --no-merges`, since GitHub writes their subjects itself
   and they can't conform.

2. **Ran a 3-agent debate the user asked for** — three independent general-purpose helper
   agents (a *subagent* = a separate helper assistant spawned for one task) playing critic,
   improver, and auditor, run in parallel. The payoffs:

   - **Critic caught the central bug — on paper, before any code.** The commit hook's
     `Touches: D<N>` footer check reads the git *staging index* (`git diff --cached`,
     `git show :README.md`) — the pile of changes you've marked to go into the *next* snapshot.
     That staging area **does not exist** for an already-recorded commit sitting in a CI
     checkout. So the original plan's "CI just reuses the hook as-is" was simply false.

   - **Improver found the cleaner fix.** Instead of carving the validation logic out into a
     new shared `hooks/lib/check-message.sh` (the originally-recommended approach, "E1"), add a
     ~10-line `COMMIT_REF` *seam* (a small switch) **inside** the existing `hooks/commit-msg`:
     default `:` means "read the staging index" (local behavior byte-for-byte unchanged),
     `<sha>:` means "read from that commit's saved tree" (what CI needs). One file, one source
     of truth, no new library, least code. This superseded E1.

   - **Auditor** confirmed `D20` was the next free decision number, ruled that GitHub Actions
     does **not** violate the island rule (it's GitHub-native, and the island rule already names
     "GitHub is the only durability layer"), and listed the completeness chores: flip the
     `rules/git-workflow.md` enforcement-table cell from honor-system to CI-enforced, update
     `hooks/README.md`, add the `plans/INDEX.md` bullet.

   - **A squash-merge worry was raised and dismissed by fact:** vyasa merges PRs with *merge
     commits*, so each commit's own message really does land on `main` — per-commit validation
     is meaningful, not theater.

   - **The agents disagreed on one fact:** does the PR that *introduces* the workflow run its
     own new check? Critic said yes (same-repo branch), auditor said no (only after it merges
     to the default branch). **Resolved live: the critic was right** — PR #12 ran its own
     workflow and went green.

3. **Built it via a general-purpose agent — deliberately NOT the `craftsman` / go-ultra-instinct
   pipeline agents.** Those belong to the skill system vyasa exists to *measure*; using them to
   scaffold vyasa would be circular (the island rule). Hand-rolled instead.

4. **Review caught a drift crack.** The first cut of the `title` check had copy-pasted the
   subject regexes instead of reusing the hook, and it skipped the inline D-code expansion
   that `rules/voice.md` requires on PR titles. A follow-up agent fixed it: the title check now
   routes through `hooks/commit-msg` itself, deleting the duplicated rules. One true source of
   truth, not two copies that can drift apart.

5. **Shipped as PR #12 with a live red/green test.** Pushed a deliberately-malformed PR title:
   the check went red on the named "Validate PR title" step. Restored a good title: green.
   Merged. The seamed hook's *local* behavior was confirmed byte-for-byte identical across 10
   hand-made cases — the seam changed nothing about how the hook behaves on your own machine.

6. **Two follow-ups noticed and bundled** (a trivial-bundle, one branch, by explicit decision):

   - **(a) Report every failing target, not just the first.** The three validation steps ran
     in sequence with no condition, and GitHub's default is that a failed step aborts the rest —
     so a bad title hid a bad body until the next round trip. Fixed by adding
     `if: ${{ !cancelled() }}` to each validation step. Chosen over `always()` **deliberately**:
     `always()` would run the steps even on a *cancelled* run, fighting the workflow's existing
     `concurrency: cancel-in-progress` (which kills a superseded in-flight run). `!cancelled()`
     runs on failure-of-earlier-steps but still bows out on a real cancellation.
   - **(b) `actions/checkout@v4` → `@v5`** to clear a Node-20 deprecation warning. Cosmetic.

   Shipped as PR #13; merged.

7. **Live-verified the polish via a throwaway-PR agent.** A PR carrying *two* violations now
   reports BOTH the title step (failed) AND the body step (failed — **not** skipped) plus the
   commits step (passed) in a single run, proving `!cancelled()` works. The concurrency-cancel
   still correctly cancelled a superseded in-flight run, and the Node-20 warning was gone. The
   throwaway PR #14 was closed-not-merged, and every test branch/file was cleaned up — the repo
   was independently re-checked pristine afterward, not taken on the subagent's word.

## Decisions / departures from the plan

- **The `COMMIT_REF` seam (E-seam) replaced the extract-a-shared-library plan (E1).** The
  debate's improver showed the seam is both correct and smaller. The seam makes the
  index-vs-commit difference explicit inside one file rather than duplicating logic across two.
- **`D20 — PR title + body format enforced via GitHub Actions CI`** appended to the README
  Decisions log; the `rules/git-workflow.md` enforcement cell flipped from "honor system today"
  to CI-enforced.
- **Body check is presence-only, order-agnostic, content not inspected** — `git-workflow.md`
  shows the six sections in an order but never *requires* that order, so presence is the
  faithful scope.

## Lessons

- **Adversarial multi-agent review caught a real architectural bug ON PAPER, before a line of
  code.** The index-coupling that would have broken CI was invisible in the plan's prose until
  a critic was pointed at it; catching it pre-build is far cheaper than catching it in a red CI
  run three commits later.
- **"Reuse the existing script via a tiny seam" beat both "duplicate the rules" and "extract a
  new shared library."** The cleanest single-source design was also the *least* code — a 10-line
  switch inside one file, versus a new directory with its own mandated README, versus two copies
  destined to drift.
- **Open factual questions get settled by tools, not by assertion.** Does the introducing PR
  self-run its check? Is the repo pristine after the throwaway test? Both were answered by
  *running the thing and looking* — and a subagent's "it's clean" claim was independently
  re-verified rather than trusted.

## State after this session

- `D20 — PR title + body format enforced via GitHub Actions CI` is live: every PR now gets its
  title, body, and per-commit messages validated server-side, un-bypassable by a local flag.
- The seamed `hooks/commit-msg` behaves identically on local machines; CI is the only caller
  that passes `COMMIT_REF=<sha>:`.
- No open threads from this work — PR #12 and PR #13 merged, PR #14 (throwaway) closed and
  cleaned up, ledger updated.
