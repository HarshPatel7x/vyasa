# vyasa

> *Skill-eval harness for the harsh-brain stack. Takes two versions of a skill,
> runs them against the same fixtures, measures the deltas.*

---

## What it is

vyasa is a tool for comparing two versions of a Claude Code skill (a "baseline" and a "candidate") against the same set of fixture inputs, and measuring the behavioral deltas between them. It is the **measurement layer** that turns skill-version promotion from intuition into evidence.

Today's flow for promoting a skill (e.g., "did the compacted SKILL.md actually preserve behavior?"): hand-test a few cases, eyeball outputs, decide. vyasa formalizes that: same fixtures every time, captured outputs every time, comparable reports every time.

## Why it exists

This project operationalizes one of the user's standing rules:
> *Keep the legacy version during a rewrite. Don't scrap the working baseline until the replacement passes acceptance.*

Without measurement, "passes acceptance" is a feeling. With vyasa, it's a report. Specifically:
- The harsh-brain skill stack (eklavya, vasudev, narada, brahma, kaya, chitragupta, etc.) gets compacted, refactored, restructured periodically.
- Each compaction/refactor is a candidate version of the skill.
- Promoting the candidate without comparing it to the baseline on the same inputs has burned the user before.
- vyasa is the comparison gate.

## Why the name "vyasa"

In Hindu mythology, Vyasa is the sage who took the scattered, oral Vedic hymns — centuries of unorganized material — and **arranged them into the four Vedas**. The Sanskrit word "vyasa" literally translates to "arranger / compiler / divider."

The project's job description IS that translation: take messy raw skill outputs across two versions and arrange them into a structured comparable form. The name is self-documenting.

## Project structure

```
vyasa/
├── CLAUDE.md                    # rulebook — self-contained, includes universal + project-specific rules
├── README.md                    # this file — full project bible + decisions log
├── .gitignore                   # ignores runs/, draft reports, OS junk
│
├── notes/                       # session lecture-notes (newest-first index)
│   ├── INDEX.md
│   └── YYYY-MM-DD-<topic>.md    # one per significant session
│
├── skills/                      # frozen skill variants under test
│   └── <skill-name>/
│       ├── baseline/            # snapshot of the version being defended
│       └── candidate/           # snapshot of the version being tested
│
├── fixtures/                    # version-controlled test inputs
│   └── <skill-name>/
│       ├── trigger-cases.md     # inputs that SHOULD invoke
│       ├── negative-cases.md    # inputs that should NOT invoke
│       └── golden/              # expected/reference outputs (optional)
│
├── runs/                        # gitignored — per-run captured outputs
│   └── YYYY-MM-DD-HHMM-<skill>-<variant>/<case-id>/
│       ├── transcript.md
│       └── metrics.json
│
├── reports/                     # comparison artifacts
│   ├── (gitignored drafts at root)
│   └── decisions/               # COMMITTED — sign-off reports that triggered a promotion
│       └── YYYY-MM-DD-<skill>-baseline-vs-candidate.md
│
└── cli/                         # (future) the runner code itself — empty until first eval
```

## What each component is, and why

### `CLAUDE.md` — the rulebook
Why it's here: every Claude Code session in this directory needs to know the rules of engagement, even after a context wipe. Self-contained so the project is portable; mirrors universal hygiene from `~/.claude/CLAUDE.md` plus adds project-specific rules.

### `notes/`
Why it's here: chat transcripts are unreadable later. Lecture/meeting-minutes notes are. After every significant session (decision/plan/advice/built/learnt), the assistant prompts to write a notes file capturing what was decided + why. `INDEX.md` makes the folder navigable — without an index, the folder is a graveyard.

### `skills/<name>/baseline` and `skills/<name>/candidate`
Why it's here: vyasa compares two versions of the same skill. Storing them as **frozen byte-level snapshots** (not symlinks) means a comparison can be re-run identically tomorrow, even if the live skill at `~/.claude/skills/<name>/` has moved on. Reproducibility is non-negotiable for a promotion gate.

### `fixtures/<name>/`
Why it's here: deltas only make sense against fixed inputs. Trigger cases test "the skill DID fire when it should"; negative cases test "the skill did NOT fire when it shouldn't"; golden outputs (when provided) give a reference target to diff against. Version-controlled because the fixtures themselves evolve and the version that produced a given report must be recoverable.

### `runs/`
Why it's here: every execution of a (skill, variant, fixture-set) tuple produces output. That output is too noisy to commit (timestamped transcripts, full raw responses). It lives in-repo for visibility but gitignored so git history stays clean.

### `reports/` and `reports/decisions/`
Why split into two: most comparison reports are exploratory and don't end in a promotion decision — those are drafts (gitignored). The ones that DO trigger a promotion are durable history and worth committing. The split keeps the noise out of git but doesn't lose the signal.

### `cli/` (future)
Why deferred: vyasa is skeleton-only today. The runner code that actually executes skills against fixtures and produces reports doesn't exist yet. When it does, it lives at top-level alongside the other dirs — kept separate from `skills/` so "the tool that measures" is never mingled with "the thing being measured."

---

## Decisions log

Every structural call made during scoping, with reasoning. Read top-to-bottom for the project's full design rationale.

### D1. No skill-based scaffolding for vyasa — permanent
**Decision:** Never use `/new-project`, `/eklavya`, `/brahma`, `/vasudev`, or any other harsh-brain skill to scaffold vyasa.
**Why:** vyasa measures the skill system. Using a skill to scaffold vyasa is circular — the tool under measurement would be building the measurement tool. This rule applies forever, not just first session.

### D2. No harsh-brain wiring
**Decision:** vyasa does not appear in `~/memories/repo/`, `~/memories/session/`, any `MEMORY.md`, `sync.sh`, or any other harsh-brain integration point.
**Why:** Keeping it an island means it can be moved, cloned, or shared without dragging the rest of the harsh-brain ecosystem along. GitHub is the durability layer.

### D3. Self-contained project `CLAUDE.md` (no `claudeMdExcludes`)
**Decision:** vyasa's `CLAUDE.md` re-declares all universal hygiene rules from `~/.claude/CLAUDE.md` instead of excluding the global one.
**Why:** The global file's content (honesty, recap, context status) is universal-good-practice anyway — would have to be in the project's rules regardless. Excluding the global one mechanically (via `claudeMdExcludes`) adds complexity for no payoff since the content is duplicated either way. Self-contained also makes the project portable: if the global file is missing, vyasa still has its rules.

### D4. Snapshot skills under test, not symlink
**Decision:** When a skill is brought under test, its files are **copied** into `skills/<name>/baseline/` and `skills/<name>/candidate/`, not symlinked from `~/.claude/skills/<name>/`.
**Why:** Promotion-gate comparisons must be reproducible. If "baseline" is a symlink to the live skill, the moment the live skill mutates, yesterday's comparison can no longer be re-run identically. Snapshot = frozen bytes = reproducible.

### D5. Per-skill subdirectories
**Decision:** `skills/`, `fixtures/`, and `runs/` all use per-skill subdirectories rather than a flat layout.
**Why:** Multi-skill support — vyasa is intended to evaluate the whole stack (vasudev, narada, brahma, kaya, …), not one skill. Flat layout would collide.

### D6. Variant directory naming: `baseline/candidate`
**Decision:** The two variants under test live in `baseline/` and `candidate/`, not `v1/v2` or `before/after`.
**Why:** Most semantically honest — vyasa is asymmetric (the candidate must prove itself against the baseline, not symmetric A/B testing). `baseline/candidate` carries that asymmetry in the directory names themselves. Scales naturally if multi-candidate bake-offs appear later (`candidate-a`, `candidate-b`, etc.).

### D7. `runs/` and `reports/` in-repo + gitignored
**Decision:** Both `runs/` and draft `reports/` live in-repo but are gitignored. External dirs (e.g., `~/.vyasa-runs/`) were rejected.
**Why:** Visibility-first — everything related to the project lives under one tree, so finding old runs doesn't require remembering a path outside the repo. Gitignore keeps the noise out of git history.

### D8. `cli/` for future runner code, deferred for now
**Decision:** Runner code lives at top-level `cli/`, not inside `skills/`. Empty until first eval.
**Why:** Keeps the tool-that-measures (cli) separate from the thing-being-measured (skills). Mingling them would confuse the structure permanently. Defer creation because there's nothing to put in it yet.

### D9. Reports: commit only sign-off, draft reports gitignored
**Decision:** `reports/decisions/` is committed; everything else in `reports/` is gitignored as draft.
**Why:** Sign-off reports = durable promotion history worth keeping in git. Exploratory comparisons = noise. The decisions subdirectory makes the signal-vs-noise split mechanical instead of judgment-based.

### D10. Session-end lecture-style notes with permission prompt
**Decision:** At end of any session where a decision/plan/advice/build/learning happened (or on manual request), assistant prompts user for permission to write a session-notes file to `notes/`. Never silent.
**Why:** Chat transcripts are unreadable later. Notes structured like meeting minutes are. The permission prompt prevents two failure modes — (a) writing notes for trivial sessions and bloating the folder, (b) silently skipping when it actually mattered.

### D11. Notes filename + INDEX convention
**Decision:** Notes filename = `YYYY-MM-DD-<topic-slug>.md`. INDEX.md is reverse-chronological (newest at top), one line + two-line brief per entry.
**Why:** Date prefix sorts chronologically when filesystem-listed. Reverse-chron INDEX matches the user's existing preference (vasudev log convention). Brief makes navigation possible without opening each file.

### D12. Edit to global `~/.claude/CLAUDE.md`: "plain-English" → "dummy-level English"
**Decision:** Renamed the recap rule's wording in the global file so end-of-response recaps come out beginner-friendly across all projects, not just vyasa.
**Why:** User wants beginner-friendly explanations as a general preference, not project-specific. One file edit gives it everywhere. Complementary: in-session jargon-defining/analogies are saved separately in user memory (`feedback_dummy_level_explanations.md`).

---

## How to use vyasa (future state)

> **Skeleton-only today.** No runner code exists. This section will be filled in when `cli/` lands.

The intended flow:
1. Bring a skill under test: copy its current state to `skills/<name>/baseline/`, copy the candidate version to `skills/<name>/candidate/`.
2. Write fixtures: trigger cases + negative cases (and golden outputs if you have them) in `fixtures/<name>/`.
3. Run the comparator (TBD): produces output under `runs/<timestamp>-<name>-<variant>/`.
4. Generate a report (TBD): lands in `reports/`.
5. If the report justifies promotion, move it to `reports/decisions/` and commit.

## Provenance

- **Originating handoff:** `~/memories/session/skill-eval-harness-handoff-2026-05-24.md`
- **Originating session:** 2026-05-24 (Sun, REST_DAY override invoked by user)
- **First name candidates considered:** skill-bench, skill-eval, skill-ab → rejected in favor of Sanskrit
- **Hindu-myth candidates considered:** hamsa, tula, manthan, ganesha, patanjali → `vyasa` chosen for literal Sanskrit meaning ("arranger")
