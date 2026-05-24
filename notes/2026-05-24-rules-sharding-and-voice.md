# 2026-05-24 — Sharding project rules + dummy-language voice default

**Session type:** structural redesign + new behavioral rule
**Duration:** medium, single working session
**Outcome:** Rules sharded into `rules/INDEX.md` + 6 shards. `CLAUDE.md` trimmed from ~80 lines to 18. README decisions log gains **D13** (shardable-domain pattern + recipe for sharding `README.md` later) and **D14** (dummy-language voice).

---

## Context — why this came up

State at session start: project skeleton-only, one commit, README has 12 decisions (D1–D12), `CLAUDE.md` was self-contained (~80 lines) mirroring universal hygiene from `~/.claude/CLAUDE.md` plus 7 project-specific rules (P1–P7).

User opened with: *"For this project, I want focus on modularity — should be added in Claude? For example: for committing to GitHub, create a rules file which Claude can reference when committing instead of writing that directly into .md file. What do you think?"*

The intuition: don't bloat `CLAUDE.md` — let it point at separate rule files instead.

---

## Design exchange (the parts that actually mattered)

### Round 1 — I flagged a reliability trap

A "rules file Claude references" sounds modular but has a hidden failure mode: `CLAUDE.md` is **auto-loaded** by Claude Code; arbitrary files at `rules/X.md` are **not**. They only enter context if (a) `CLAUDE.md` explicitly says "before action X, read `rules/X.md`" AND (b) the assistant remembers to check at action-time. The second part is the fragile bit — under context pressure, the check can be silently skipped.

I proposed three shapes:

- **Cheap & medium-reliable:** tiny `CLAUDE.md` with hard directives to read shards on triggers
- **Modular + auto-loaded:** use `@path/to/file.md` import syntax in `CLAUDE.md` (would need verification it actually works)
- **Enforced by harness:** `PreToolUse` hook injects rules at action moment (violates P2's island principle since hooks live in global config)

### Round 2 — user clarified the goal

User: *"the purpose here is to not bloat .md file. just state for this check this file and then when needed it loads it in the context window. before that it knows nothing about it."*

Lazy-load IS the goal, not a tradeoff to mitigate. That reframed everything. The pattern becomes: `CLAUDE.md` as router, shards under `rules/`, each shard pulled in only when its trigger fires. Same shape that `notes/INDEX.md` → `notes/<file>.md` already uses, applied to rules.

### Round 3 — user wanted EVERYTHING sharded (including always-on rules)

User also added a new behavioral ask: *always answer in dummy language for this project — because vyasa is a learning vehicle, and "to learn more about AI is to use it more."*

My pushback (recorded for honesty): sharding **always-load** rules doesn't actually save context bytes — those shards still load every session, just from a different file. The wins are different:
- **Structural:** one file per concern, easier to diff and edit one without touching others
- **Signal clarity:** `CLAUDE.md` becomes a clean directive list at the top of context instead of a thick wall

User needed to know that before signing off. I also flagged that "always dummy language" has a sharp edge — technical content (file paths, commands, JSON) can't be dummified without breaking. Worked into the final rule: **prose stays plain, technical artifacts stay literal, terms get glossed on first use.**

### Round 4 — user broke my proposed shape

I had proposed putting the routing table **inside** `CLAUDE.md` itself. User: *"what if I want to do the same with readme.md file where would I keep it?"*

Hit. The shape didn't generalize. README would have no obvious place for its own routing table if it ever wanted to shard the same way. Fixed: **every shardable domain gets its own folder + its own `INDEX.md` as router.** `CLAUDE.md` and `README.md` become thin entry points. Pattern is uniform.

### Round 5 — user's coffee-machine reframe

On my "sharding always-load rules doesn't save context" point: *"with sharding we may save context but also choose what to add or not. Like a coffee machine where we can choose to add milk or not, even if we take milk for every cup."*

The "may save context" framing isn't quite right (always-load shards still load every session), but the **coffee-machine analogy** is exactly the right mental model: the value is **opt-in control**, not byte savings. Even if 95% of sessions take the milk, having it as a separate pour means the 5% can skip it without restructuring the kitchen.

---

## What landed

### Files created (8 new)

| File                              | Type        | Content                                                                  |
|-----------------------------------|-------------|--------------------------------------------------------------------------|
| `rules/INDEX.md`                  | router      | Default-load list + triggered table + how to add a shard                |
| `rules/hygiene.md`                | default     | Honesty/verification (rules 1–4) + context window status                |
| `rules/voice.md`                  | default     | Dummy-language voice + end-of-response recap                            |
| `rules/island.md`                 | default     | No harsh-brain wiring + no skill scaffolding + README is bible          |
| `rules/session-end-notes.md`      | triggered   | Former P3 + P4 + P5 consolidated                                        |
| `rules/skill-snapshot.md`         | triggered   | Derived from D4 + D5 — copy-don't-symlink + per-skill subdirs           |
| `rules/readme-decisions-log.md`   | triggered   | Former P7 — when structural decision is made, update README same session |

### Files modified (2)

- **`CLAUDE.md`** — trimmed from ~80 lines to 18: minimal entry-point directive plus the one rule that has to live there (the folder-per-domain + `INDEX.md` routing convention itself, because every shard depends on it being known)
- **`README.md`** — updated structure tree (added `rules/`), revised `CLAUDE.md` component description, added new `rules/` component description, appended **D13** (shardable-domain pattern + 7-step recipe for sharding `README.md` later) and **D14** (dummy-language voice as project default)

---

## Decisions recap

| # | Decision                                                                                                                          |
|---|-----------------------------------------------------------------------------------------------------------------------------------|
| 1 | Project uses uniform **folder + `INDEX.md`** routing pattern for every shardable domain. Top-level files stay thin.               |
| 2 | `rules/` is the first sharded domain. 3 default-load shards + 3 triggered shards.                                                |
| 3 | Dummy-language voice is the project default. Prose plain, technical artifacts literal, terms glossed on first use.               |
| 4 | The convention rule itself lives in `CLAUDE.md` (not in a shard) because every shard depends on it being known to be loaded.     |
| 5 | Recipe for sharding `README.md` is in D13 step list — **not executed** this session, ready for next session.                     |
| 6 | The hook-scoping work from earlier today (separate session) gets bundled into the same commit as the rules sharding.             |

---

## Caveats / known limits

1. **The new voice/structure takes effect next session.** This conversation was already loaded under the OLD `CLAUDE.md` (the thick one). The shift to thin-entry + shard-routing applies from the next fresh session onward. Verify by opening a fresh session and checking startup behavior.
2. **The load chain now has 2 levels of indirection.** Claude Code auto-loads `CLAUDE.md` → it reads `rules/INDEX.md` → it reads the default-load shards. Slightly more startup file reads than an inline rulebook, but deterministic and bounded (3 reads).
3. **Triggered shards depend on the trigger being unambiguous.** Every triggered shard opens with a `TRIGGER:` line so the firing condition is explicit. If a trigger turns out to fire ambiguously in practice, that's a design bug — either promote the rule to default-load or rewrite the trigger condition.
4. **`docs/` does not yet exist.** D13's recipe describes how to shard `README.md` into a `docs/` domain with the same pattern, but no actual move was performed this session.
5. **`rules/commit.md` is intentionally absent.** Today's project-specific `CLAUDE.md` had no explicit commit rules, so a shard for it would have been empty placeholder. Will be created the first time a commit-specific rule actually needs to exist (e.g., a rule about commit-message format or what NOT to commit).

---

## Not done this session (deliberately deferred)

- **README sharding.** D13 has the 7-step recipe. Execute in a future session when ready.
- **Verifying `@file.md` import syntax** in `CLAUDE.md`. Was a fallback option in Round 1, became irrelevant once the user clarified that lazy-load by directive was the goal.
- **The actual measurement work.** Still skeleton-only. Risk flagged in the previous notes file (`2026-05-24-hook-scoping-vyasa-exclusion.md`) remains live: the gravitational pull is toward design polishing rather than the first runnable thing. Worth naming again at the start of the next session.
