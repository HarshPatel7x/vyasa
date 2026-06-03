# 2026-06-03 — Planning per-session token-usage logging (+ 3 adversarial reviews)

> Session notes (meeting-minutes style). Topic: a reviewed plan for the "record token usage per
> session" workitem. **No build** — the plan is written and reviewed; the build is blocked on a
> scope decision the user must make.

## What was produced

`workitems/plans/token-usage-logging.md` — a build plan grounded in **empirical investigation** of
Claude Code's own transcript files (not docs), then revised after **three adversarial reviews** run
in parallel with distinct lenses (correctness / scope-safety / completeness).

## Key findings (all verified with `jq` against real transcripts)

- **Token data lives in the per-session transcript JSONL** — each assistant line carries
  `message.usage` (input / output / cache-create / cache-read) plus per-message `model`.
- **The dedup trap.** A single response is written as many lines that each repeat the same usage;
  naive summing overcounts ~**3×** (measured: 673,059 vs the correct 222,898 output tokens on one
  file). Must dedup by `requestId`.
- **Subagent tokens are in a SEPARATE folder** — `…/<session-id>/subagents/agent-*.jsonl`, with
  `sessionId` equal to the parent. The parent transcript has zero subagent lines, so a hook reading
  only the parent is **blind to all helper-assistant spend** (proven: ~10,729 invisible tokens on a
  real vyasa session).
- Other traps: `jq -s` (one-shot slurp) **hard-crashes on a half-written last line** (a live
  transcript being written when the hook fires) → silent total loss; `<synthetic>` canceled-turn
  lines have a null `requestId`; the 5-minute vs 1-hour cache tiers are priced differently and must
  be stored separately.

## Decisions in the plan

- **Hook event:** `Stop` (fires per turn), re-aggregating and overwriting a per-session JSON file —
  robust to crashes, unlike a fire-once `SessionEnd`.
- **Store raw token counts, not computed cost** — prices change; cost is a regenerable view.
- **Scope is the user's blocking call:** project-scope (vyasa sessions only, island-clean, no gate)
  vs global (all sessions, better fits "track cost over time", but edits shared global config →
  hits the ask-twice gate and strains the island principle). Plan recommends project-first; **build
  does not start until the user answers.**

## Lessons / things learned

- **The 3-review panel earned its keep — twice.** Two holes I'd have shipped: a parent-only reader
  that silently ignores subagent cost, and a `jq -s` parse that logs **nothing** on a busy turn when
  the transcript's last line is mid-write. Neither is catchable by an offline test on saved
  (complete) transcripts — exactly the false-confidence trap.
- **Diverse lenses beat three identical reviewers.** Correctness found the null-`requestId` bucket;
  scope/safety found a too-soft ask-twice guard; completeness found the subagent folder and the
  `jq -s` crash. One lens would have missed the others.
- **Don't propagate a reviewer's claim unverified.** I re-checked the two big finds myself before
  folding them in — which *confirmed* the `jq -s` crash and the subagent-folder location, and
  corrected my own plan's "subagent location unknown" to "confirmed, and in v1."
- **I under-searched first.** My initial pass concluded subagent usage was "unfindable" because I
  looked beside the transcript and for inline sidechain lines — both wrong places. The data was one
  directory away. A reminder to exhaust the search before declaring a negative.

## Status / next

Plan reviewed and build-ready **except** the scope decision (project vs global). When the user
picks, the build opens with a live probe of the real `Stop` hook payload, then the aggregation
script. Logged as the one remaining open workitem.
