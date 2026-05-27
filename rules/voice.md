---
WHAT: Voice rules — how Claude should speak in this project.
LOAD: Default — every session.
---

# Voice

## Dummy-language as default

Default prose voice for this project is plain English. The user is using vyasa as a learning vehicle for AI — *to learn more about AI is to use it more* — so the conversation itself is part of the learning surface. Over-jargon defeats that.

**Rule:**

- **Prose stays plain.** No jargon without glossing it on first use in the session. *Example:* "hook (a script that Claude Code runs automatically at certain moments)" the first time, "hook" after.
- **Technical artifacts stay literal.** File paths, commands, JSON, code blocks must be exact — those don't get translated. Translation lives in the prose *around* them.
- **Tradeoff accepted:** explanations get longer, not shorter. Clarity-for-learner beats terseness.

When a term is genuinely unavoidable (e.g., "context window", "hook", "subagent"), use it — but gloss it the first time.

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

## Inline expansion of decision codes

Decision codes (`D1`, `D13`, …) defined in `README.md`'s Decisions log are internal shorthand. They are not self-documenting — a reader who hasn't memorized the log will stall on every bare code.

**Rule:** Every time a D-code is cited — in prose, commit messages, PR titles, PR descriptions, session notes, or any project artifact — expand it inline as:

```
D<N> — <short title from the README D-entry>
```

Examples:

- `D13 — shardable-domain pattern: folder + INDEX.md routing`
- `D15 — workitems checklist, branch-per-workitem, README-everywhere conventions`

**Source of truth:** the short description is the title line of the corresponding `### D<N>. <Short title>` heading in `README.md`'s Decisions log. Copy it verbatim — do not paraphrase or invent — so the codes and their expansions stay aligned with the bible.

**Every mention, not just first:** D-codes commonly appear in artifacts that get read out-of-order or partially (commit logs, PR titles, session-note fragments, search hits). A reader landing mid-artifact still needs the expansion. The verbosity tradeoff is accepted as the cost of self-contained citations.

**When the README D-entry is renamed:** future citations use the new title. Old citations already committed (in commit messages, merged PRs, archived notes) are not retroactively updated — they remain a historical record of what the title was at the time of writing.

**What's not covered:** ranges (e.g., "D1–D5") are not standard usage in this project. If you find yourself wanting to cite a range, expand each code individually or rewrite to cite only the relevant ones.
