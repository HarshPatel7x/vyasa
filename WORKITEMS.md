# vyasa — WORKITEMS

> Pending work for this project. See [`rules/workitems.md`](rules/workitems.md) for the convention (one branch per checked-off item, append on agreement, move to Closed when done).

## Open

- [ ] **Inline decision-code expansion.** When citing a decision code (e.g., D1, D13), expand inline as `Dxx — short description` so the reader doesn't need to look it up. Implementation: add as a rule (likely a new `rules/decision-codes.md` shard, or extend `rules/voice.md`).
- [ ] **Diff-verification hook to catch hallucinated edits.** After any Edit/Write tool call, run a PostToolUse hook that diffs the file against pre-edit state and surfaces the actual delta. Goal: stop silent "I edited X" claims from going unnoticed. Wire via `~/.claude/settings.json` at project scope (not global, until proven here).
- [ ] **Define PR, commit-message, and PR-description conventions.** Currently no rules exist for: when to open a PR, commit-message format, PR-description format. Until these exist, the branch-per-workitem convention runs in "best effort + direct-to-main acceptable" bootstrap mode. Likely lands as a new shard `rules/git-workflow.md` (or split across shards) plus a D-entry in the README.
- [ ] **Tweak `rules/readme-convention.md` rule.** Specifics TBD — capture in-conversation before editing. Current rule covers: every dir/project carries a README.md, project-scope only, minimum-content guidance (what / what lives here / how to use). Possible tweak directions: looser minimum, different scope (subdirs vs only project roots), exemptions for trivial dirs, etc.
- [ ] **Record token usage per session for later analysis.** Investigate whether/how Claude Code surfaces per-session token counts (input, output, cache hits/misses, cost). If accessible, write to a per-session log file (e.g., `~/vyasa-token-usage/YYYY-MM-DD-session-id.json`). Use cases: cost tracking, prompt-cache efficiency analysis, session-size pattern detection over time. Likely needs a Stop hook in `~/.claude/settings.json` and/or reading Claude Code's own usage telemetry if exposed.

## Closed

- [x] **Log every workitem — shipped-on-the-fly or deferred (2026-05-27).** Extended `rules/workitems.md` with a new section requiring that any agreed work land in `WORKITEMS.md` regardless of whether it's done immediately or queued. Shipped on the fly in-conversation; logged here as the first example of itself.
