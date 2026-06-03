# Plan — Record token usage per session for later analysis

> Workitem: **Record token usage per session for later analysis.** Investigate whether/how Claude
> Code surfaces per-session token counts (input, output, cache hits/misses, cost); if accessible,
> write to a per-session log file for cost tracking, prompt-cache efficiency analysis, and
> session-size pattern detection over time.
> Branch: *(not cut — plan-only; build is gated on the scope decision D-b below).* Status: planned,
> revised after 3 adversarial reviews (correctness / scope-safety / completeness), awaiting a user
> decision on scope.

## What is actually available (VERIFIED this session, with tool calls)

Investigated against real transcripts under
`/Users/harshpatel/.claude/projects/-Users-harshpatel-Desktop-Harsh-vyasa/` and sibling project dirs:

1. **Per-session transcript JSONL is the main-thread data source.** One `<session-id>.jsonl` per
   session; each `type:"assistant"` line carries `message.usage` (`input_tokens`, `output_tokens`,
   `cache_creation_input_tokens`, `cache_read_input_tokens`, `server_tool_use.{web_search_requests,
   web_fetch_requests}`, `service_tier`, and `cache_creation.{ephemeral_5m_input_tokens,
   ephemeral_1h_input_tokens}`), plus `message.model`, `requestId`, `message.id`, `sessionId`,
   `isSidechain`. First line carries `cwd`, `gitBranch`, `version`.

2. **THE aggregation trap — usage is duplicated per request; dedup is mandatory.** A single API
   response is written as several assistant lines (one per content block), **each repeating the
   identical `message.usage`**. Reproducible on the stable current file `4322b604…jsonl`: **343
   assistant lines → 125 distinct (non-null) `requestId`s**; naive `sum(output_tokens)` = **673,059**
   vs correct dedup-by-`requestId` sum = **222,898** — a **3.01× overcount**. Within a `requestId`
   usage is byte-identical, so taking one line per group is safe. *(The earlier draft cited a
   since-rotated file; these are current, reproducible numbers.)*

3. **`<synthetic>` / interrupted lines exist** — assistant lines with `requestId: null` and
   `model:"<synthetic>"` (canceled/interrupted turns), carrying all-zero usage. The aggregation
   **must `select(.requestId != null)` before grouping**, or `group_by` produces a junk
   `<synthetic>` model bucket. (Verified: 2 such lines in `4322b604`, 1 in `9b3868d3`.) So the
   earlier "requestId↔message.id are 1:1" claim is **false in general** and is dropped; it holds only
   among real (non-null) lines.

4. **Subagent tokens live in a SEPARATE, findable place — CONFIRMED (was "unknown").** Subagent
   (Task/Agent) transcripts are written to
   **`<projectdir>/<session-id>/subagents/agent-*.jsonl`**, carry full `message.usage` with
   `isSidechain:true`, and their `sessionId` **equals the parent session id**. The parent
   `<session-id>.jsonl` contains **zero** sidechain lines — so a hook reading only `transcript_path`
   is **blind to all subagent spend.** Proven on a real vyasa session (`a0139427…`): 6 subagent
   files totaling ~**10,729** deduped output tokens invisible to a parent-only reader. For a
   cost-tracking tool this is not ignorable → **subagent attribution is in v1** (the dir is
   reconstructable from `session_id`).

5. **Model is per-message** (multi-model sessions possible: Opus main + Haiku subagent), and the
   **5m vs 1h cache-creation tiers are priced differently** and are both present in every usage
   object → both must be stored separately for cost to be rederivable later.

6. **No precomputed per-session cost/total** exists in any transcript — must be derived or omitted.

7. **Hook events Stop / SessionStart / UserPromptSubmit are real and wired** in the user's *global*
   `~/.claude/settings.json`, which already has **two** `Stop` hook entries (both wiring into
   harsh-brain). Any new Stop hook is additive but must not assume it is the only one. `jq` is at
   `/usr/bin/jq`.

## Open questions (resolve at build time)

- **Exact `Stop` payload not verified this session.** Docs say Stop receives `{session_id,
  transcript_path, cwd, hook_event_name, stop_hook_active}`. **Build step 1 dumps the real payload**
  to confirm `transcript_path` + `session_id` before any aggregation is written.
- **`usage.iterations[]`** is length ≤1 in all current data, so the top-level usage is authoritative
  today; it is a live field that could grow. The aggregation reads top-level usage but the build
  should add a cheap assertion that `iterations|length <= 1`, logging a notice if that ever breaks.

## Design decisions

### D-a. Hook event: `Stop` (per-turn, idempotent full-rewrite) — recommended
`Stop` fires at the **end of every turn**. The hook re-aggregates (parent transcript **+** the
subagents glob) and **rewrites** `<session-id>.json` with the running total each turn; the last turn
leaves the final total. Robust to abrupt exits (crash/kill) — unlike a `SessionEnd`-once design that
loses the whole log if it never fires. A jq pass over a 3 MB transcript measured ~**31 ms**, so
per-turn re-read is fine. The triggering turn's usage is already on disk when Stop fires (verified:
the turn's assistant lines precede the trailing metadata entries), so nothing is missed.

### D-b. Scope: project vs global — **USER DECISION REQUIRED (ask-twice gate for global)**
- **Project scope** (`vyasa/.claude/settings.json`, like the diff-verification hook): logs **vyasa
  sessions only**. Island-consistent, no global-config edit, **no ask-twice gate**. But the stated
  use case ("…pattern detection over time", "cost tracking") implies *all* the user's usage, which
  project scope will **not** capture — stated plainly, not hidden.
- **Global scope** (`~/.claude/settings.json`): logs **every** session. Matches the use case, **but**
  (1) edits global config → **hygiene rule 6 ask-twice gate applies**; (2) couples global config to a
  vyasa-internal script path (fragile if vyasa moves); (3) strains the island principle — and the
  two existing global Stop hooks both point into harsh-brain, so a vyasa-owned global hook would be
  the lone global hook pointing into an "island", which is incoherent. If all-project tracking is the
  real goal it **arguably belongs outside vyasa** as a personal dotfile, not as a vyasa workitem.

**Recommendation:** ship **project scope** first (coherent, gate-free, island-pure); treat global as
a separate, explicitly-gated decision. **The build is BLOCKED until the user answers D-b.**

### D-c. Store RAW tokens (per tier), not derived cost — recommended
Persist raw counts (input / output / **cache-creation-5m** / **cache-creation-1h** / cache-read,
plus `service_tier`), per model, per thread. Cost is a regenerable *view* applying a current price
table; baking prices into the hook makes records silently wrong when prices move. Store `cc_version`
so the price-era is reconstructable.

### D-d. Dedup key `requestId`, filtered non-null, group-and-take-first. Settled by §2–§3 above.

## Proposed log schema (`<session-id>.json`, rewritten each turn)

Per-turn rows are the source of truth (needed for "over time" analysis); the summary is derived.

```json
{
  "schema_version": 1,
  "session_id": "…", "project_cwd": "…", "git_branch": "…", "cc_version": "2.1.159",
  "first_ts": "…", "last_ts": "…",
  "turns": {"main": 125, "subagent": 6},
  "rows": [   // one per deduped request, main + subagent
    {"ts":"…","thread":"main","request_id":"req_…","model":"claude-opus-4-8",
     "input":…, "output":…, "cache_create_5m":…, "cache_create_1h":…, "cache_read":…,
     "service_tier":"standard"}
  ],
  "by_model": { "claude-opus-4-8": {"requests":…,"input":…,"output":…,
                "cache_create_5m":…,"cache_create_1h":…,"cache_read":…} },
  "by_thread": { "main": {…same fields…}, "subagent": {…} },
  "totals": {"input":…,"output":…,"cache_create_5m":…,"cache_create_1h":…,"cache_read":…},
  "server_tool_use": {"web_search_requests":…,"web_fetch_requests":…},
  "subagent_tokens_included": true
}
```

## Implementation steps (once scope is chosen)

1. **Probe the real Stop payload** — temporary hook appends its stdin JSON to a scratch file; confirm
   `transcript_path` + `session_id`; remove the probe. (Verify-before-build.)
2. **Write `hooks/log-token-usage.sh`** (version-controlled in vyasa). It must:
   - Read hook JSON from stdin; extract `transcript_path`, `session_id`, derive the project dir.
   - Aggregate the parent transcript **and** every `<projectdir>/<session_id>/subagents/*.jsonl`
     (label rows `main` vs `subagent`).
   - **Parse line-by-line with `jq -R 'fromjson? | select(. != null)'`, NOT `jq -s` slurp** —
     `jq -s` hard-fails (`Unfinished JSON term at EOF`, zero output) on a transcript whose last line
     is mid-write when Stop fires; `fromjson?` skips the partial line and keeps the complete ones
     (both verified). This is the single most important implementation constraint.
   - Filter `type=="assistant" and .requestId != null`; group by `requestId`, take `.[0]`; then roll
     up by model / thread / totals; emit the schema above.
   - **Atomic write:** temp name `<logdir>/<session-id>.json.$$.tmp` (session id **and** PID, so two
     concurrent sessions under global scope never collide), then `mv` into place.
   - **Fail-open** (always exit 0, never block the turn), bounded, **raw-shell only** (no Edit/Write
     tools — same no-loop discipline as the diff-verification hooks).
3. **Wire it** in the chosen `settings.json` `Stop` array, **additively** (do not remove the two
   existing global Stop hooks). **Gate:** *if scope == global, the build MUST obtain the hygiene-rule-6
   double-confirmation in-session immediately before editing `~/.claude/settings.json`; project scope
   is gate-free.* No code path edits global config without that confirm.
4. **Doc**: `hooks/README.md` entry; note the logs persist in `<logdir>` and are **not auto-pruned**
   (unlike the `$TMPDIR` edit-snapshots) — add a prune/retention note or a size cap. If wiring is a
   structural choice, add a `D`-entry to `docs/decisions.md`.

## Verification

- **Offline correctness** over saved transcripts: the line-streaming aggregation equals the dedup
  value (222,898 on `4322b604`), never the naive 673,059, and produces **no `<synthetic>` bucket**.
- **Partial-last-line (the case offline tests miss):** feed a transcript whose final line is
  truncated mid-write → the hook still writes the complete-line totals (proves `fromjson?` over
  `-s`). This is mandatory because saved transcripts always have complete final lines, so the offline
  test gives false confidence.
- **Subagent inclusion:** on a session with a `subagents/` dir, totals include the subagent output
  tokens (~10,729 on `a0139427`); `subagent_tokens_included:true`.
- **Idempotency:** run twice on the same input → byte-identical output.
- **Compaction:** verified `/compact` **appends** a summary line and does **not** rewrite/truncate
  the JSONL, so earlier `message.usage` survives and per-turn re-aggregation does not undercount
  (file `80527cc3` retains all 58 usage requestIds after its compaction marker). Add a regression
  check.
- **Edge inputs:** zero-assistant-turn session → valid empty-ish output, not a jq error; empty /
  missing transcript path → exit 0, write nothing; resumed session (same filename re-aggregated).
- **`/cost` consistency check (not ground truth):** compare live totals to `/cost`; a match confirms
  we mirror Claude Code's *own* accounting (same source, so a *consistency* check — a shared dedup
  error would not be caught). A mismatch is a bug to chase before ship.

## Out of scope (noted)
- A cost-report generator (applies a price table to the raw logs) — clean follow-up once logs exist.
- Global all-project tracking — a separate, ask-twice-gated decision (D-b).
- Log retention/pruning policy beyond a basic cap — flagged in step 4 for the build to settle.
