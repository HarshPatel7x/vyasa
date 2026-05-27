# vyasa — WORKITEMS

> Pending work for this project. See [`rules/workitems.md`](rules/workitems.md) for the convention (one branch per checked-off item, append on agreement, move to Closed when done).

## Open

- [ ] **Diff-verification hook to catch hallucinated edits.** After any Edit/Write tool call, run a PostToolUse hook that diffs the file against pre-edit state and surfaces the actual delta. Goal: stop silent "I edited X" claims from going unnoticed. Wire via `~/.claude/settings.json` at project scope (not global, until proven here).
- [ ] **PR-side CI enforcement.** Add a GitHub Action that validates PR titles match the Conventional Commits subject shape (`<type>(<scope>): <summary>`) and PR bodies contain all required sections (`## Summary`, `## Why`, `## Workitem`, `## Decisions touched`, `## Verification`, `## Followups`). Fails the PR check on violation. Likely lands as `.github/workflows/pr-format-check.yml`.
- [ ] **Tweak `rules/readme-convention.md` rule.** Specifics TBD — capture in-conversation before editing. Current rule covers: every dir/project carries a README.md, project-scope only, minimum-content guidance (what / what lives here / how to use). Possible tweak directions: looser minimum, different scope (subdirs vs only project roots), exemptions for trivial dirs, etc.
- [ ] **Record token usage per session for later analysis.** Investigate whether/how Claude Code surfaces per-session token counts (input, output, cache hits/misses, cost). If accessible, write to a per-session log file (e.g., `~/vyasa-token-usage/YYYY-MM-DD-session-id.json`). Use cases: cost tracking, prompt-cache efficiency analysis, session-size pattern detection over time. Likely needs a Stop hook in `~/.claude/settings.json` and/or reading Claude Code's own usage telemetry if exposed.

## Closed

- [x] **Log every workitem — shipped-on-the-fly or deferred (2026-05-27).** Extended `rules/workitems.md` with a new section requiring that any agreed work land in `WORKITEMS.md` regardless of whether it's done immediately or queued. Shipped on the fly in-conversation; logged here as the first example of itself.
- [x] **Inline decision-code expansion (2026-05-27).** Extended `rules/voice.md` with an "Inline expansion of decision codes" section: every D-code citation (in prose, commits, PRs, notes) must be expanded inline as `Dxx — short title from README` on every mention, sourced verbatim from the README D-entry title.
- [x] **Define PR, commit-message, and PR-description conventions (2026-05-27).** Shipped `rules/git-workflow.md` with three sub-conventions, `hooks/commit-msg` + `hooks/pre-commit` for hard enforcement, `hooks/README.md` with setup instructions. Retired the bootstrap exception in `rules/workitems.md`. Added `D16 — PR / commit-message / PR-description conventions defined + commit validation enforced via hooks` to `README.md`. Queued followup workitem for PR-side CI enforcement.
