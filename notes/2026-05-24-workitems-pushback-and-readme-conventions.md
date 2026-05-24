# 2026-05-24 — Workitems checklist, branch-per-workitem, README-everywhere, push-back, ask-twice-global

**Session type:** rule design + implementation (six conventions installed across project and global)
**Outcome:** three new project shards, two hygiene items added (project + global), one D-entry, one WORKITEMS.md file, three workitems queued, one discovery surfaced.

---

## Context — why this came up

User brought a list of five ideas to evaluate, then added a sixth mid-session. The session was conversational design with explicit ask for honest push-back ("if I am wrong or taking a wrong path push hard").

The six items, in order of discussion:

1. Workitems list in CLAUDE.md.
2. Branch convention for completed work.
3. Auto-version every MD file on new branch.
4. Expand decision codes (D1, D13, …) inline as `Dxx — short description`.
5. Diff-verification hook to catch hallucinated edits.
6. Push-back rule on wrong understanding / wrong path.

Several were refined or rejected through back-and-forth.

---

## Decisions made

| # | Original idea | Final decision |
|---|---|---|
| 1 | Workitems IN CLAUDE.md | **WORKITEMS.md at project root**, CLAUDE.md only references the rule. Rule lives in new shard `rules/workitems.md`. |
| 2 | New branch per commit | **One branch per checked-off workitem**, with trivial-bundle and bootstrap exceptions. Same shard as #1. |
| 3 | Auto-version every MD on new branch | **Rejected.** Pushed back hard — git already does this better; manual versioning drifts, conflicts on merge, doubles every diff, and the user could not name an analysis question git couldn't answer. User accepted the push-back. |
| 4 | Inline decision-code expansion | **Queued as workitem.** Not implemented this session. |
| 5 | Diff-verification hook | **Queued as workitem.** Not implemented this session. |
| 6 | Push-back rule | **Implemented.** Added to `rules/hygiene.md` item 5 AND lifted to global `~/.claude/CLAUDE.md` item 5 in same pass. |

Additional decisions emerged mid-session:

- **Never edit global CLAUDE.md without asking twice.** New hygiene rule (item 6, project + global). Triggered by a near-miss earlier in the session when the assistant almost wrote to global without explicit consent.
- **Every directory or project carries a README.md.** New rule (project-scope only for now), captured in new shard `rules/readme-convention.md`. Rationale: README files have affordances (auto-rendering, conventional entry point) that plain folders lack; skipping them scatters per-directory context elsewhere.
- **D15 entry** in `README.md` Decisions log, bundling all three structural moves (workitems shard, branch convention, README convention) as one decision.

---

## What landed

**Vyasa (6 file ops):**
- `rules/hygiene.md` — items 5 (push-back) + 6 (ask-twice-global, includes symlink caveat per the discovery below)
- `rules/workitems.md` — **new** default-load shard
- `rules/readme-convention.md` — **new** default-load shard
- `rules/INDEX.md` — registered both new shards in default-load
- `WORKITEMS.md` — **new** at project root, seeded with 3 items (inline decision-code expansion, diff-verification hook, PR/commit/PR-description rules)
- `README.md` — **D15** entry appended to Decisions log; updated once during the session to reflect the symlink resolution

**Harsh-brain (1 file op, via the symlink at `~/.claude/CLAUDE.md`):**
- `CLAUDE.md` — items 5 (push-back) + 6 (ask-twice-global, with symlink note) added; previous item 5 (recap rule) renumbered to 7.

---

## Discovery — the global file is a symlink

When the assistant first attempted the global edit, the Edit tool refused: *"Refusing to write through symlink: /Users/harshpatel/.claude/CLAUDE.md."* `readlink -f` revealed:

```
/Users/harshpatel/.claude/CLAUDE.md -> /Users/harshpatel/Desktop/Harsh/harsh-brain/CLAUDE.md
```

So "global" is not a standalone file — it lives inside the `harsh-brain` project on this machine. The assistant paused (per the ask-twice rule we were literally in the middle of installing), surfaced the finding, asked the user to reconfirm. User chose **"Proceed — write to harsh-brain via symlink."** The edit then went to the real path.

The new global rule itself carries a footnote noting the symlink so future sessions are not surprised by the same discovery.

**Side note:** harsh-brain has an auto-sync that commits and pushes every ~10 min ("Auto-sync 2026-05-24 HH:MM" commits). The explicit commit landed before any auto-sync ran, so the change carries a meaningful message instead of being absorbed silently.

---

## How the new rule validated itself

The ask-twice-before-editing-global rule fired on **its own first use**. That was unplanned and a clean piece of evidence that the rule is doing work: the symlink discovery would have been a silent surprise without the gate. Recorded in D15 so the sequence is preserved.

---

## Workitems queued (in `WORKITEMS.md`)

| # | Item | Why queued, not done |
|---|---|---|
| 1 | Inline decision-code expansion (`Dxx — short desc`) | Rule, not action — defer to its own shard pass. |
| 2 | Diff-verification hook (PostToolUse on Edit/Write) | Needs hook design + `~/.claude/settings.json` edit at project scope. Non-trivial. |
| 3 | Define PR / commit-message / PR-description conventions | Gap surfaced when discussing branch-per-workitem. Until landed, branch convention runs "best effort + direct-to-main acceptable." |
| 4 | Tweak `readme-convention.md` rule | User flagged specifics TBD. |
| 5 | Record token usage per session for analysis | User question: should we log per-session token counts? Investigation + Stop hook likely. |

---

## Decisions recap

| # | Decision |
|---|----------|
| 1 | Add `WORKITEMS.md` at project root + `rules/workitems.md` shard capturing checklist + branch-per-workitem convention. |
| 2 | Reject manual MD versioning; git is sufficient. |
| 3 | Add push-back-on-wrong-premises rule to project hygiene (item 5) AND lift to global. |
| 4 | Add ask-twice-before-editing-global rule to project hygiene (item 6) AND lift to global. |
| 5 | Add `rules/readme-convention.md` shard (every dir/project carries README.md, project-scope only). |
| 6 | Bundle all three structural moves into single **D15** entry in README. |
| 7 | Commit directly to `main` for now; branch-per-workitem applies once PR/commit/PR-description rules land. |

---

## Caveats / not done this session

1. **Three workitems remain open.** Inline decision-code expansion, diff-verification hook, PR/commit/PR-description conventions — all queued, none built. Plus the two added at session end (readme-convention tweak, token recording).
2. **README backfill not done.** New `readme-convention.md` rule says every directory carries a README.md, but existing vyasa subdirectories (`rules/`, `notes/`, `skills/`, `fixtures/`, `runs/`, `reports/`, `cli/`) were not audited or backfilled. Tracked informally — could be added to WORKITEMS.md if strict compliance is wanted.
3. **`harsh-brain` sync.log changes** appeared in its git status during this session. **Not from the assistant** — that file is owned by harsh-brain's own auto-sync. Not staged or committed by this session.
4. **Recap-rule renumbering in global was a content-meaningful edit.** Item 5 → item 7 in `~/.claude/CLAUDE.md`. Any other doc or memory that references "item 5" of global CLAUDE.md is now stale — none known, but flagged in case.

---

## Tags

`#rules` `#hygiene` `#workitems` `#branch-convention` `#readme-convention` `#push-back` `#ask-twice` `#symlink-discovery` `#D15`
