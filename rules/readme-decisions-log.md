---
WHAT: Updating the README decisions log.
TRIGGER: A structural decision is made or changed during a session.
LOAD: When the trigger above is met.
---

# README decisions log

`README.md` is the project bible. Every structural decision lives in its **Decisions log** section.

## When the trigger fires

A *structural* decision = anything about how vyasa is shaped:

- Adding/removing/renaming top-level directories
- Changing how shards are organized (`rules/`, `notes/`, future `docs/`)
- Changing what is or isn't tracked in git
- Changing what the project IS (purpose, scope, name)
- Changing how rules or notes are managed
- Adding a new shardable domain

Behavioral rules (voice, recap, hygiene specifics) live in `rules/` shards, **not** in the decisions log — unless a structural change forced them. Example: "dummy-language voice as project default" is a structural project-level decision (D14), but the *details* of how it works live in `rules/voice.md`.

## Format

Append to the bottom of the Decisions log section in `README.md`. Use the next sequential D-number.

```
### D<N>. <Short title>
**Decision:** <what was decided>
**Why:** <reasoning — one or two sentences>
```

If the decision has a follow-up recipe (e.g., "ready to apply to X later"), include it as a short numbered list under the entry so a future session can pick it up cold.

## Same-session rule

The README update happens in **the same session** as the decision. Never defer to "next time" — that's how the bible falls behind.
