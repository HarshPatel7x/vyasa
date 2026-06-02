# vyasa session notes — index

> Newest-first. One line + two-line brief per session.
> Filename convention: `YYYY-MM-DD-<topic-slug>.md`
> Trigger: a session that involved a decision, plan, advice, build, learning, OR a manual request.

---

- [2026-06-01-squash-merge-adoption.md](2026-06-01-squash-merge-adoption.md) — Switched the repo to squash-merge so every `main` commit is one structured, already-validated line (the PR title `(#N)`, blank body, auto-deleted branch) instead of GitHub's `Merge pull request #N…` wording — `D21 — Squash-merge so every mainline commit is structured`; annotated the now-false merge-commit clause of `D20 — PR title + body format enforced via GitHub Actions CI`. Shipped via PR #16, merged as the deliberate last merge commit (so its `Touches: D21` trailer landed) before flipping the GitHub setting.
  Lesson: the 3-agent debate again caught real defects on paper — `gh repo edit` can't set the squash title source (only the API PATCH can, else the headline outcome silently fails) and a flatly-false sentence left standing inside the README bible. Cutover order is a design choice: merging the switch-on PR the old way one last time, then flipping, preserved the decision trailer on `main`. And a mid-task tool lockout (`getcwd` EPERM) was survived by writing a durable RESUME handoff — working-tree files outlive a terminal restart.

- [2026-06-01-pr-format-ci-enforcement.md](2026-06-01-pr-format-ci-enforcement.md) — Built, shipped, and live-verified server-side PR-format enforcement (`D20 — PR title + body format enforced via GitHub Actions CI`): a GitHub Actions check validating PR title + body sections + each non-merge commit message, server-side where the bypassable local `commit-msg` hook can't reach. Shipped via PR #12 (CI) and PR #13 (polish: `!cancelled()` to report all targets + `checkout@v5`); throwaway PR #14 closed-and-cleaned.
  Lesson: a 3-agent debate (critic/improver/auditor) caught a real architecture bug on paper before any code — the `commit-msg` `Touches:` check reads the git staging index, which doesn't exist for an already-made commit in CI; the fix reused the hook via a 10-line `COMMIT_REF` seam, beating both "duplicate the rules" and "extract a shared library." Open factual questions (does the introducing PR self-run? is the repo pristine after the test?) were settled by tools, not assertion.

- [2026-06-01-diff-verification-hook-live-trigger-verified.md](2026-06-01-diff-verification-hook-live-trigger-verified.md) — Verified the edit-verification hook pair fires live in a fresh session, closing the one caveat the build note deferred. Tested on a throwaway `/tmp` file: the NEW-file branch printed `[edit-verify] … +3 -0 (NEW file)` to the user's terminal (confirmed by screenshot), and the no-op branch (re-writing identical bytes) injected the "byte-identical… changed nothing on disk" note into the model's context.
  Lesson: the hook's two output channels are asymmetric — `systemMessage` reaches only the user's screen, `additionalContext` reaches only the model — so an assistant self-testing this hook can directly confirm *only* the no-op branch. Checking the on-disk snapshot artifacts proves nothing, since the Post hook's `cleanup()` deletes them whether or not anything fired.

- [2026-06-01-diff-verification-hook-build.md](2026-06-01-diff-verification-hook-build.md) — Built and shipped the edit-verification hook pair (snapshot-before-edit + verify-diff) planned on 2026-05-31; added D19 — Project-scope Claude Code Pre/PostToolUse hooks for edit verification; merged via PR #9. Discovered by testing that Claude Code does not hot-reload `settings.json` hooks, so logic was verified by 22 hand-made-JSON cases + three audit rounds, with the live trigger deferred to the next fresh session.
  Lesson: a documented hook is not a live hook (the key finding came from trying it, not trusting docs); and "audit until zero faults" earns its keep on round 1 — the first auditor caught a 7×-over-limit output bug and a path-traversal hole the in-house tests missed, while later rounds mostly confirmed.

- [2026-05-31-edit-checker-plan-and-voice-rule.md](2026-05-31-edit-checker-plan-and-voice-rule.md) — Planned the edit-checker (diff-verification) hook through three architect audits — the first caught a blocking flaw (git-diff shows cumulative, not per-edit, delta), reworked to a before/after snapshot pair; saved unmerged for a fresh-session build. Then reinforced the plain-English rule after the assistant drifted into heavy jargon live (rule was loaded the whole time): added a `plain` interrupt, a before-sending self-check, and a capped glossary; merged via PR #7.
  Lesson: a loaded rule is not an obeyed rule — fixed-position rituals (the recap) held while free-prose intentions drifted, so the fix adds active handles, not louder text. Script enforcement considered and dropped (general case infeasible, narrow case high-false-positive + unverified hook visibility).

- [2026-05-31-compaction-test-verdict.md](2026-05-31-compaction-test-verdict.md) — Ran the one test the migration couldn't run headlessly: a live `/compact` in a fresh session. All three buried rule tokens survived, closing the last open caveat on D18 — Rule-loading moves from SessionStart hook to CLAUDE.md @import.
  Mechanism observed: `/compact` auto-re-reads the `@import`'d shards while rebuilding context, so rules reload by re-import (the 2026-05-29 "strong hunch" confirmed). B3-b fallback hook not needed/not built. Honest limit: a zero-read probe couldn't be isolated (compact reads the files itself) — moot, since the rules are present either way.

- [2026-05-29-hook-to-import-migration.md](2026-05-29-hook-to-import-migration.md) — Found the SessionStart rules-hook is mostly defeated by Claude Code's 10K hook-stdout cap (only ~1 of 6 shards loaded); verified single-hop AND recursive `@import` work, so Option A is locked — `rules/INDEX.md` stays single source of truth and does the loading. Build deferred to a fresh session.
  Architect-agent audit caught 3 issues (no existing hook D-entry → write D18; verify all six shards not first+last; post-compaction reload regression). Decided pure `@import` (B3-a) with a hybrid compact-only hook as fallback; compaction is only testable via a live `/compact`, not `claude -p`. Two unmerged branches; nothing live changed.

- [2026-05-28-sessionstart-load-rules-hook.md](2026-05-28-sessionstart-load-rules-hook.md) — Shipped `hooks/load-default-rules.sh`, a SessionStart hook that parses the Default-load list in `rules/INDEX.md` and injects the six shards into starting context — guaranteed load, no longer compliance-based.
  Auditor agent approved with zero blockers; applied its should-fix (parser now tolerates a `#anchor` and uses a bare-filename allowlist so no shard is silently dropped). Bundled a stale-count fix in `rules/INDEX.md` ("three" → "six"). open.md candidate deliberately NOT auto-loaded.

- [2026-05-28-claude-md-load-research-and-workitems-folder.md](2026-05-28-claude-md-load-research-and-workitems-folder.md) — Researched how Claude Code loads CLAUDE.md (auto-load is compliance-based, @import eager but no token saving, .claude/rules/ paths-scoping is the real lever); decided keep-modular + fix load via SessionStart hook; built the workitems/ folder + plan-before-build gate (D17 — Workitems become a folder; open/done split; plan-before-build gate).
  Default shards empirically did NOT auto-load this session — proving the read-chain gap. Audit agent caught 3 stale WORKITEMS.md refs in git-workflow.md; git soft-reset kept the old index (needed `git add -A` to re-stage). Shipped via PR #2.

- [2026-05-27-git-workflow-rules-and-hook-enforcement.md](2026-05-27-git-workflow-rules-and-hook-enforcement.md) — Three rules shipped (log-every-workitem, inline D-code expansion, git-workflow conventions) and D16 — PR / commit-message / PR-description conventions defined + commit validation enforced via hooks landed; hooks wired and self-applying via PR #1.
  Bootstrap exception retired the moment its replacement landed. Hook learnings: macOS BSD grep lacks -P (use perl), trailer-tokens hyphenate not space, perl `pos()` follows the variable matched, em-dash U+2014 not hyphen.

- [2026-05-24-workitems-pushback-and-readme-conventions.md](2026-05-24-workitems-pushback-and-readme-conventions.md) — Added WORKITEMS.md + branch-per-workitem + README-everywhere conventions (D15); hygiene items 5 (push-back) and 6 (ask-twice-global) added project + lifted to global.
  Six file ops in vyasa + one in harsh-brain/CLAUDE.md via the global symlink; five workitems queued. Ask-twice rule fired on its own first use and surfaced that `~/.claude/CLAUDE.md` is a symlink into harsh-brain.

- [2026-05-24-rules-sharding-and-voice.md](2026-05-24-rules-sharding-and-voice.md) — Sharded project rules into `rules/INDEX.md` + 6 shards; trimmed `CLAUDE.md` to 18 lines; added D13 (shardable-domain pattern + README-sharding recipe) and D14 (dummy-language voice).
  User's coffee-machine reframe locked the design: opt-in control is the win, not byte savings. The uniform folder-per-domain + INDEX.md pattern now applies to `rules/`, already-in-place `notes/`, and a future `docs/` if `README.md` is ever sharded.

- [2026-05-24-hook-scoping-vyasa-exclusion.md](2026-05-24-hook-scoping-vyasa-exclusion.md) — Excluded vyasa from harsh-brain SessionStart + UserPromptSubmit reminders via cwd-guarded hook commands.
  Four hooks in `~/.claude/settings.json` (lines 244, 253, 262, 273) now exit silently when `$PWD` is the vyasa root. Backup saved; JSON validated; takes effect next session.

---

*(Project skeleton was set up via the originating handoff at `~/memories/session/skill-eval-harness-handoff-2026-05-24.md`. Decisions from that scoping session live in `README.md`'s decisions log, not here.)*

---

## Format reference

```
- [YYYY-MM-DD-<topic-slug>.md](YYYY-MM-DD-<topic-slug>.md) — <one-line topic>
  Two-line brief: what was decided/built/learned + why it matters.
```
