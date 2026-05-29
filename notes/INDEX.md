# vyasa session notes — index

> Newest-first. One line + two-line brief per session.
> Filename convention: `YYYY-MM-DD-<topic-slug>.md`
> Trigger: a session that involved a decision, plan, advice, build, learning, OR a manual request.

---

- [2026-05-28-sessionstart-load-rules-hook.md](2026-05-28-sessionstart-load-rules-hook.md) — Shipped `hooks/load-default-rules.sh`, a SessionStart hook that parses the Default-load list in `rules/INDEX.md` and injects the six shards into starting context — guaranteed load, no longer compliance-based.
  Auditor agent approved with zero blockers; applied its should-fix (parser now tolerates a `#anchor` and uses a bare-filename allowlist so no shard is silently dropped). Bundled a stale-count fix in `rules/INDEX.md` ("three" → "six"). open.md candidate deliberately NOT auto-loaded.

- [2026-05-28-claude-md-load-research-and-workitems-folder.md](2026-05-28-claude-md-load-research-and-workitems-folder.md) — Researched how Claude Code loads CLAUDE.md (auto-load is compliance-based, @import eager but no token saving, .claude/rules/ paths-scoping is the real lever); decided keep-modular + fix load via SessionStart hook; built the workitems/ folder + plan-before-build gate (D17 — Workitems become a folder; open/done split; plan-before-build gate).
  Default shards empirically did NOT auto-load this session — proving the read-chain gap. Audit agent caught 3 stale WORKITEMS.md refs in git-workflow.md; git soft-reset kept the old index (needed `git add -A` to re-stage). Shipped via PR #2.

- [2026-05-27-git-workflow-rules-and-hook-enforcement.md](2026-05-27-git-workflow-rules-and-hook-enforcement.md) — Three rules shipped (log-every-workitem, inline D-code expansion, git-workflow conventions) and D16 — PR / commit-message / PR-description conventions defined + commit validation enforced via hooks landed; hooks wired and self-applying via PR #1.
  Bootstrap exception retired the moment its replacement landed. Hook learnings: macOS BSD grep lacks -P (use perl), trailer-tokens hyphenate not space, perl `pos()` follows the variable matched, em-dash U+2014 not hyphen.

- [2026-05-24-workitems-pushback-and-readme-conventions.md](2026-05-24-workitems-pushback-and-readme-conventions.md) — Added WORKITEMS.md + branch-per-workitem + README-everywhere conventions (D15); hygiene items 5 (push-back) and 6 (ask-twice-global) added project + lifted to global.
  Six file ops in vyasa + one in harsh-brain/CLAUDE.md via the global symlink; five workitems queued. Ask-twice rule fired on its own first use and surfaced that `~/.claude/CLAUDE.md` is a symlink into harsh-brain.

- [2026-05-24-rules-sharding-and-voice.md](2026-05-24-rules-sharding-and-voice.md) — Sharded project rules into `rules/INDEX.md` + 6 shards; trimmed `CLAUDE.md` to 18 lines; added D13 (shardable-domain pattern + README-sharding recipe) and D14 (dummy-language voice).
  User's coffee-machine reframe locked the design: opt-in control is the win, not byte savings. The uniform folder-per-domain + INDEX.md pattern now applies to `rules/`, already-in-place `notes/`, and a future `docs/` if `README.md` is ever sharded.

- [2026-05-24-hook-scoping-vyasa-exclusion.md](2026-05-24-hook-scoping-vyasa-exclusion.md) — Excluded vyasa from harsh-brain SessionStart + UserPromptSubmit reminders via cwd-guarded hook commands.
  Four hooks in `~/.claude/settings.json` (lines 244, 253, 262, 273) now exit silently when `$PWD` is the vyasa root. Backup saved; JSON validated; takes effect next session.

---

*(Project skeleton was set up via the originating handoff at `~/memories/session/skill-eval-harness-handoff-2026-05-24.md`. Decisions from that scoping session live in `README.md`'s decisions log, not here.)*

---

## Format reference

```
- [YYYY-MM-DD-<topic-slug>.md](YYYY-MM-DD-<topic-slug>.md) — <one-line topic>
  Two-line brief: what was decided/built/learned + why it matters.
```
