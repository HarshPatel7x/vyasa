# Workitems — Open

> Live queue of pending work. One entry per item. Each links to its plan in
> [`plans/`](plans/README.md), or is marked `(no plan)` until one is written
> (see the **plan-before-build** gate in [`../rules/workitems.md`](../rules/workitems.md)).
> Completed items move to [`done.md`](done.md).

- [ ] **Record token usage per session for later analysis.** Investigate whether/how Claude Code surfaces per-session token counts (input, output, cache hits/misses, cost). If accessible, write to a per-session log file (e.g., `~/vyasa-token-usage/YYYY-MM-DD-session-id.json`). Use cases: cost tracking, prompt-cache efficiency analysis, session-size pattern detection over time. Likely needs a Stop hook and/or reading Claude Code's own usage telemetry if exposed. → plan: [`plans/token-usage-logging.md`](plans/token-usage-logging.md) — **build blocked on a scope decision (project vs global), see D-b**
