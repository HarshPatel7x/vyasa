# Workitems — Open

> Live queue of pending work. One entry per item. Each links to its plan in
> [`plans/`](plans/README.md), or is marked `(no plan)` until one is written
> (see the **plan-before-build** gate in [`../rules/workitems.md`](../rules/workitems.md)).
> Completed items move to [`done.md`](done.md).

- [ ] **Tweak `rules/readme-convention.md` rule.** **Specifics (captured 2026-05-28):** a directory needs a `README.md` only if it's the project head (root) or a directory Claude accesses/works in directly; other directories — sharded sub-domains like `rules/`, `notes/`, `workitems/` — just need an `INDEX.md`. This reconciles the current "every directory carries a README.md" rule with the `INDEX.md`-as-entry-doc pattern those folders already use (the tension noted in `D17 — Workitems become a folder; open/done split; plan-before-build gate`). Implementation is its own branch + plan (plan-before-build gate). `(no plan)`
- [ ] **Record token usage per session for later analysis.** Investigate whether/how Claude Code surfaces per-session token counts (input, output, cache hits/misses, cost). If accessible, write to a per-session log file (e.g., `~/vyasa-token-usage/YYYY-MM-DD-session-id.json`). Use cases: cost tracking, prompt-cache efficiency analysis, session-size pattern detection over time. Likely needs a Stop hook in `~/.claude/settings.json` and/or reading Claude Code's own usage telemetry if exposed. `(no plan)`
