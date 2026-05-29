# Session note — 2026-05-28 — SessionStart hook to auto-load default rules

> Built workitem #1 (the only planned item in `workitems/open.md`), audited it with the
> auditor agent, applied the audit's should-fix, and fixed a stale count in `rules/INDEX.md`.

---

## What was built

`hooks/load-default-rules.sh` — a Claude Code **SessionStart** hook, wired via project-scope
`.claude/settings.json` (matcher `startup|resume|clear|compact`). It parses the **Default-load**
section of `rules/INDEX.md` (kept as the single source of truth), extracts the `[name](file.md)`
link targets, and `cat`s each shard to stdout. On exit 0, Claude Code injects that stdout into the
session's starting context — so the six always-on shards (hygiene, voice, island, workitems,
readme-convention, git-workflow) now load **by guarantee**, not by Claude following the
`CLAUDE.md` → `rules/INDEX.md` → shard read-chain (which was compliance-based and had been
observed to silently miss).

Branch `workitem/sessionstart-load-rules`. Item moved `open.md` → `done.md`. `hooks/README.md`
restructured into a git-hooks section and a Claude-Code-hooks section.

## Why the hook (not `@import`)

Per the plan (`workitems/plans/sessionstart-load-rules.md`): `@import` in `CLAUDE.md` would
duplicate the load-list (CLAUDE.md imports + INDEX.md prose), risking drift. The hook reads the
list from `INDEX.md` directly, so `INDEX.md` stays the single source of truth — aligns with
`D13 — shardable-domain folder-per-domain + INDEX.md router pattern`. The hook also re-runs on
`compact`, so the rules refresh after compaction (`@import` would not).

## Decisions resolved at build time

- **`workitems/open.md` is NOT auto-loaded.** The hook's parser excludes any link target with a
  slash, so the `../workitems/INDEX.md` pointer on the workitems line is dropped — only bare
  in-`rules/` shard filenames load. (The plan left this open.)
- **Parser approach:** `awk` to isolate the Default-load section, `grep -oE` for link targets,
  `sed` to strip `](` / `)` / `#anchor`, `grep -E '^[^/]+\.md$'` allowlist for bare filenames.

## Audit (auditor agent)

Verdict **APPROVED**, zero blockers. Confirmed correct: `set -euo pipefail` handling,
graceful degradation when `jq` is absent / stdin empty / a shard is missing, stdout-vs-stderr
discipline, SessionStart exit-code semantics (exit 0 injects; non-zero warns without blocking),
and plan-conformance. Security surface is nil — shard text is only ever `cat`'d, never evaluated.

## Audit should-fix — applied

The original parser (`grep -oE '\]\([^)]+\.md\)'` + `grep -vE '/'`) would **silently drop** any
shard link carrying a `#anchor` fragment (e.g. `[voice](voice.md#recap)`) — it wouldn't match
`.md)` and never hit the missing-shard warning. Hardened to tolerate-and-strip an optional anchor
and switched the slash exclusion to a bare-filename allowlist. Verified with a temp `INDEX.md`:
`voice.md#recap` loads, a same-line `../other/INDEX.md` pointer is excluded, real INDEX still
yields all six shards. Folded into the commit via `--amend`.

## Learnings

- **SessionStart hook contract:** stdout on exit 0 is injected as context; for SessionStart a
  non-zero exit surfaces stderr to the user but does **not** block the session — so erroring loud
  on a parse failure is safe, it warns without wedging startup.
- **`$CLAUDE_PROJECT_DIR`** is the robust way to reference the project root in a settings.json
  hook command; double-quote it inside the JSON string so paths with spaces survive.
- **Resolve repo root from `${BASH_SOURCE[0]}`**, not cwd — a hook can be invoked from anywhere.
- A `grep -vE '/'` exclusion reads as "skip one known pointer" but actually skips a whole class;
  an allowlist (`^[^/]+\.md$`) states the real intent and is less brittle.

## Tail fix (bundled by explicit decision)

`rules/INDEX.md` said "Read these **three**" while listing **six** default shards — a stale count
in the very file the hook parses. Corrected to "six". Bundled onto this branch by in-conversation
decision (trivial-bundle exception in `rules/workitems.md`).
