---
WHAT: Session-end notes — when to write them, where, how.
TRIGGER: At the end of a session where {a decision was made, a plan was formed, advice was given, something was built, something was learned, OR the user manually requested notes}.
LOAD: When the trigger above is met.
---

# Session-end notes

## When the trigger fires

End-of-session, if one or more of the following happened this session:

- A decision was made
- A plan was formed
- Advice was given
- Something was built
- Something was learned
- The user manually requested a notes file

Otherwise exit clean — no prompt, no file.

---

## How

**Always ask the user for permission first.** Never silent. If they decline, drop it cleanly.

If they approve, write a session-notes file in lecture / meeting-minutes style.

---

## Filename convention

`notes/YYYY-MM-DD-<topic-slug>.md`

- Date in ISO format (YYYY-MM-DD)
- Slug short, lowercase, hyphen-separated
- One topic per file — if a session covered two distinct topics, write two files

---

## INDEX update

Same session as the notes file, add a one-line entry at the **top** of `notes/INDEX.md` (newest-first):

```
- [YYYY-MM-DD-topic.md](YYYY-MM-DD-topic.md) — one-line topic
  Two-line brief about what was decided/built/learned.
```
