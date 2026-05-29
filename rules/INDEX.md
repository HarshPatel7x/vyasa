# rules — index

> Project rules sharded by concern. This file is the router.
> Same pattern as `notes/INDEX.md`.

---

## Default-load (read at session start, every session)

Read these six before responding to anything. Each shard opens with a `WHAT:` / `LOAD:` header.

- [hygiene.md](hygiene.md) — Honesty, verification, no fabricated confidence, context-window awareness, push-back on wrong premises, ask-twice gate before editing global config.
- [voice.md](voice.md) — Dummy-language voice as project default; end-of-response 3-line recap.
- [island.md](island.md) — vyasa is an island: no harsh-brain wiring; no skill-based scaffolding; README is the bible.
- [workitems.md](workitems.md) — `workitems/` folder convention: open/done split, plan-before-build gate, one branch per workitem. (The ledger itself lives in [`../workitems/INDEX.md`](../workitems/INDEX.md).)
- [readme-convention.md](readme-convention.md) — Every directory or project carries a `README.md`.
- [git-workflow.md](git-workflow.md) — PR, commit-message, and PR-description conventions. Enforced by `hooks/`.

---

## Triggered-load (read only when the trigger fires)

Each shard opens with a `TRIGGER:` line so the firing condition is unambiguous.

| Trigger                                              | Shard                                                |
|------------------------------------------------------|------------------------------------------------------|
| Session ending with decision/plan/advice/build/learn | [session-end-notes.md](session-end-notes.md)         |
| Bringing a skill under test                          | [skill-snapshot.md](skill-snapshot.md)               |
| A structural decision is made or changed             | [readme-decisions-log.md](readme-decisions-log.md)   |

---

## How to add a shard

1. Decide whether it's default-load (applies every session) or triggered (applies only when a clear condition fires).
2. Write `rules/<short-slug>.md` with a `WHAT:` / `LOAD:` (or `TRIGGER:`) header at the top.
3. Add a one-line entry above in the appropriate section. Triggered shards need an unambiguous firing condition — fuzzy triggers cause silent misses.
4. If the shard represents a structural project decision (new domain, change to how rules work), append an entry to the README decisions log in the same session.
