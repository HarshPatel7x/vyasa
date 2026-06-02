# Workitems — Open

> Live queue of pending work. One entry per item. Each links to its plan in
> [`plans/`](plans/README.md), or is marked `(no plan)` until one is written
> (see the **plan-before-build** gate in [`../rules/workitems.md`](../rules/workitems.md)).
> Completed items move to [`done.md`](done.md).

- [ ] **Record token usage per session for later analysis.** Investigate whether/how Claude Code surfaces per-session token counts (input, output, cache hits/misses, cost). If accessible, write to a per-session log file (e.g., `~/vyasa-token-usage/YYYY-MM-DD-session-id.json`). Use cases: cost tracking, prompt-cache efficiency analysis, session-size pattern detection over time. Likely needs a Stop hook in `~/.claude/settings.json` and/or reading Claude Code's own usage telemetry if exposed. `(no plan)`
- [ ] **Fix `hooks/commit-msg` empty-message abort on an unknown `D<N>` footer.** When a `Touches:` footer cites a `D<N>` with no matching `### D<N>.` heading in `docs/decisions.md`, the commit is still correctly rejected (fail-closed, exit 1) but with an **empty** error instead of the intended "no '### D<N>. …' heading exists" diagnostic — `set -euo pipefail` aborts on the `grep` exit-1 inside the `readme_title=$(decisions_blob | grep …)` command substitution before the friendly guard runs. Fix: capture grep's nonzero without aborting (e.g. wrap the pipeline in `|| true`) so the empty-result guard can emit its message. Pre-existing (predates the readme-router branch; surfaced by its adversarial review). `(no plan)`
