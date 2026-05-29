# Workitems — Open

> Live queue of pending work. One entry per item. Each links to its plan in
> [`plans/`](plans/INDEX.md), or is marked `(no plan)` until one is written
> (see the **plan-before-build** gate in [`../rules/workitems.md`](../rules/workitems.md)).
> Completed items move to [`done.md`](done.md).

- [ ] **Diff-verification hook to catch hallucinated edits.** After any Edit/Write tool call, run a PostToolUse hook that diffs the file against pre-edit state and surfaces the actual delta. Goal: stop silent "I edited X" claims from going unnoticed. Wire via `~/.claude/settings.json` at project scope (not global, until proven here). `(no plan)`
- [ ] **PR-side CI enforcement.** Add a GitHub Action that validates PR titles match the Conventional Commits subject shape (`<type>(<scope>): <summary>`) and PR bodies contain all required sections (`## Summary`, `## Why`, `## Workitem`, `## Decisions touched`, `## Verification`, `## Followups`). Fails the PR check on violation. Likely lands as `.github/workflows/pr-format-check.yml`. `(no plan)`
- [ ] **Tweak `rules/readme-convention.md` rule.** **Specifics (captured 2026-05-28):** a directory needs a `README.md` only if it's the project head (root) or a directory Claude accesses/works in directly; other directories — sharded sub-domains like `rules/`, `notes/`, `workitems/` — just need an `INDEX.md`. This reconciles the current "every directory carries a README.md" rule with the `INDEX.md`-as-entry-doc pattern those folders already use (the tension noted in `D17 — Workitems become a folder; open/done split; plan-before-build gate`). Implementation is its own branch + plan (plan-before-build gate). `(no plan)`
- [ ] **Record token usage per session for later analysis.** Investigate whether/how Claude Code surfaces per-session token counts (input, output, cache hits/misses, cost). If accessible, write to a per-session log file (e.g., `~/vyasa-token-usage/YYYY-MM-DD-session-id.json`). Use cases: cost tracking, prompt-cache efficiency analysis, session-size pattern detection over time. Likely needs a Stop hook in `~/.claude/settings.json` and/or reading Claude Code's own usage telemetry if exposed. `(no plan)`
