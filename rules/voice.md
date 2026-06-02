---
WHAT: Voice rules — how Claude should speak in this project.
LOAD: Default — every session.
---

# Voice

## Dummy-language as default

Default prose voice for this project is plain English. The user is using vyasa as a learning vehicle for AI — *to learn more about AI is to use it more* — so the conversation itself is part of the learning surface. Over-jargon defeats that.

**Rule:**

- **Prose stays plain.** No jargon without glossing it on first use in the session. *Example:* "hook (a script the system runs automatically at a set moment)" the first time, "hook" after. Ready-made glosses for recurring terms live in the **Recurring-terms glossary** at the foot of this file — use them so glossing has no friction.
- **Technical artifacts stay literal.** File paths, commands, JSON, code blocks must be exact — those don't get translated. Translation lives in the prose *around* them.
- **Tradeoff accepted:** explanations get longer, not shorter. Clarity-for-learner beats terseness.

When a term is genuinely unavoidable (e.g., "context window", "hook", "subagent"), use it — but gloss it the first time.

---

## The `plain` interrupt

The user can type **`plain`** (or "plain please") at any moment. On seeing it, immediately stop, drop all jargon, and re-explain the most recent thing in plain words — no file paths, no tool names, no rule codes. If the most recent thing was already plain, say so briefly and move on — no forced re-explanation. It is the conversational equivalent of the recap, available on demand. Distinct from "quiet mode" (which *suppresses* the recap); `plain` *triggers* a plain re-explanation.

---

## End-of-response recap

After any complicated multi-step response, end with this 3-line block:

```
In dummy-level words:
- What I did: <one sentence, no jargon>
- Why it matters: <concrete benefit or risk closed>
- What's next: <one concrete action, or "nothing — done">
```

**Skip the recap only for:** trivial one-liners, direct answers to simple questions, or when the user says "quiet mode."

**Never in the recap:** file paths, tool names, jargon. The recap is the strictest layer of plain-English in any response — even if the rest of the response had to use technical terms, the recap doesn't.

---

## Before-sending self-check

Before sending any non-trivial or technical response, do one pass over your own draft and ask: "would a smart non-specialist stall on any word here?" Gloss each such term on first use, or cut it. This is a fixed checkpoint — like the end-of-response recap — not an aspiration. The recap is a fixed checkpoint and held all through the 2026-05-31 session; this gives the body prose the same kind of anchor. (This targets the *body* prose, where the drift happens — the recap only guards the closing block.)

---

## Inline expansion of decision codes

Decision codes (`D1`, `D13`, …) defined in the Decisions log (`docs/decisions.md`) are internal shorthand. They are not self-documenting — a reader who hasn't memorized the log will stall on every bare code.

**Rule:** Every time a D-code is cited — in prose, commit messages, PR titles, PR descriptions, session notes, or any project artifact — expand it inline as:

```
D<N> — <short title from the D-entry>
```

Examples:

- `D13 — shardable-domain pattern: folder + INDEX.md routing`
- `D15 — workitems checklist, branch-per-workitem, README-everywhere conventions`

**Source of truth:** the short description is the title line of the corresponding `### D<N>. <Short title>` heading in the Decisions log (`docs/decisions.md`). Copy it verbatim — do not paraphrase or invent — so the codes and their expansions stay aligned with the bible.

**Every mention, not just first:** D-codes commonly appear in artifacts that get read out-of-order or partially (commit logs, PR titles, session-note fragments, search hits). A reader landing mid-artifact still needs the expansion. The verbosity tradeoff is accepted as the cost of self-contained citations.

**When a D-entry is renamed:** future citations use the new title. Old citations already committed (in commit messages, merged PRs, archived notes) are not retroactively updated — they remain a historical record of what the title was at the time of writing.

**What's not covered:** ranges (e.g., "D1–D5") are not standard usage in this project. If you find yourself wanting to cite a range, expand each code individually or rewrite to cite only the relevant ones.

---

## Recurring-terms glossary (gloss source)

Ready-made plain glosses for terms that recur in this project, so glossing-on-first-use has no friction. Use the gloss the first time a term appears in a session, then the bare term after.

| Term             | Plain gloss (first-use)                                      |
|------------------|-------------------------------------------------------------|
| hook             | a script the system runs automatically at a set moment      |
| branch           | a separate copy of the project's files to work on safely    |
| commit           | a saved snapshot of changes, with a note on what/why        |
| PR (pull request)| a request to fold a branch's changes into the main copy     |
| merge            | combining a branch's changes into the main copy             |
| snapshot         | a quick copy of a file's contents at one moment             |
| context window   | the limited amount the assistant can "hold in mind" at once |
| subagent         | a separate helper assistant spawned for one task            |
| shard            | one small rule file (the rules are split into several)      |
| @import          | a line that pulls another file's contents in automatically  |

**Graduation trigger (kept unambiguous — this project forbids fuzzy triggers):** when this table exceeds ~20 rows, or stops being "recurring terms" and turns into a general dictionary, move it out of this always-loaded rule into an on-demand `rules/glossary.md` that this file points at. Reference data should not ride in a default-load rule, which pays its context cost every session. Until that threshold, it lives here.
