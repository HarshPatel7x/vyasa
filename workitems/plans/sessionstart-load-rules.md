# Plan — SessionStart hook to auto-load default rules

> Workitem: "SessionStart hook to auto-load default rules into context" (see [`../open.md`](../open.md)).
> Status: **planned, not yet built.** This plan satisfies the plan-before-build gate; the actual
> build is a separate workitem/branch so we don't violate the gate on day one.

## Problem

The default-load shards listed in `rules/INDEX.md` (hygiene, voice, island, workitems,
readme-convention, git-workflow) only reach context because Claude follows the
`CLAUDE.md` → `rules/INDEX.md` → shard read-chain. That chain is **compliance-based, not
guaranteed**.

Observed failure: in the session that produced this plan, none of the six default shards were
in the starting context — they had to be read manually when they became relevant. So
"read these every session" is aspirational, not enforced.

## Options considered

1. **`@import` in `CLAUDE.md`** — native, declarative, zero script. `@rules/hygiene.md` etc.
   load eagerly at launch (max import depth: 4 hops). Downside: the load-list is **duplicated**
   (CLAUDE.md imports + INDEX.md prose list), which can drift out of sync.
2. **SessionStart hook (CHOSEN)** — a hook script reads the default-load list from
   `rules/INDEX.md` and prints the concatenated shards to stdout, which Claude Code injects as
   context. Keeps `rules/INDEX.md` as the **single source of truth** (no second list). Re-runs
   on `startup`/`resume`/`clear`/`compact`, so it refreshes after compaction. Downside: a script
   to maintain; Claude-Code-specific.

**Decision: SessionStart hook** — keeping `INDEX.md` as the single source of truth aligns with
D13 (INDEX.md is the router), and the load guarantee holds across compaction.

## Implementation

1. **`hooks/load-default-rules.sh`**
   - Read the hook payload from stdin; optionally read `.source`.
   - Parse the **Default-load** section of `rules/INDEX.md` — extract the `[name](file.md)` link targets.
   - `cat` each referenced shard from `rules/` to stdout.
   - Exit 0 (stdout on exit 0 is auto-injected as SessionStart context).
   - Optional: when `.source == "compact"`, prepend a one-line "(refreshed post-compaction)" marker.
2. **`.claude/settings.json` (project scope, NOT global)**
   - Add a `SessionStart` hook entry; matcher covering `startup|resume|clear|compact`;
     command runs `hooks/load-default-rules.sh`.
3. **`CLAUDE.md`** — unchanged. The prose "read `rules/INDEX.md` and follow it" pointer stays as
   a human-readable backup, no longer the load mechanism.

## Verification (verify — do not assert)

- Run `hooks/load-default-rules.sh` manually with a mock stdin payload; confirm all six default
  shards are emitted.
- Start a fresh session; confirm the shard text is present in starting context (the failure
  described above should be gone).
- Optional: add an `InstructionsLoaded` hook to log which instruction files actually loaded.

## Token cost (known, accepted)

The six default shards total ~330 lines (hygiene 45, voice 60, island 38, workitems 44,
readme-convention 34, git-workflow 109), paid up front every session. Accepted: these are
intentional always-on rules. Future optimization (separate workitem): move `git-workflow.md`
to a `paths:`-scoped `.claude/rules/` file so it loads only when touching git, trimming ~a third
of the always-on cost.

## Decided at build time (not in this plan)

- Whether `workitems/open.md` also rides this hook's auto-load (it is a default-load candidate).
- Final shard-list parsing approach in the script.
