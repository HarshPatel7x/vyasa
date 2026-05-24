# vyasa session notes — index

> Newest-first. One line + two-line brief per session.
> Filename convention: `YYYY-MM-DD-<topic-slug>.md`
> Trigger: a session that involved a decision, plan, advice, build, learning, OR a manual request.

---

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
