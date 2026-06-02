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
├── CLAUDE.md                    # thin entry point — points at rules/INDEX.md
├── README.md                    # this file — full project bible + decisions log
├── .gitignore                   # ignores runs/, draft reports, OS junk
│
├── rules/                       # sharded project rules (router + shards)
│   ├── INDEX.md                 # router: which shards load when
│   ├── hygiene.md               # default-load: honesty, verification, context status
│   ├── voice.md                 # default-load: dummy-language voice + recap
│   ├── island.md                # default-load: no harsh-brain wiring; no skill scaffolding; README is bible
│   ├── workitems.md             # default-load: workitems/ folder convention + plan-before-build
│   ├── session-end-notes.md     # triggered: session end with decision/plan/build/learn
│   ├── skill-snapshot.md        # triggered: bringing a skill under test
│   └── readme-decisions-log.md  # triggered: a structural decision is made or changed
│
├── workitems/                   # the ledger of queued + completed work (folder-per-domain)
│   ├── INDEX.md                 # router
│   ├── open.md                  # live queue of pending work (default-load candidate)
│   ├── done.md                  # archive of completed items (never auto-loaded)
│   └── plans/                   # one plan per workitem; plan-before-build gate
│       ├── INDEX.md
│       └── <slug>.md            # load on demand when you pick up an item
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

### `CLAUDE.md` — the thin entry point
Why it's here: every Claude Code session in this directory needs a starting instruction. The actual project rules live as shards under `rules/`; `CLAUDE.md` just says "read `rules/INDEX.md` and follow it." Keeps the auto-loaded file tiny and signals at the top of context that the rules are modular. The one rule that DOES live in `CLAUDE.md` itself is the folder-per-domain + `INDEX.md` routing convention — because that convention describes how every other rule is organized, it has to be known before any of them.

### `rules/`
Why it's here: project rules are sharded by concern rather than lumped into one rulebook. `rules/INDEX.md` is the router; each shard handles one concern (`voice.md`, `hygiene.md`, `island.md`, …). Three wins: (1) **opt-in control** — even rules currently always loaded can be skipped on specific sessions without restructuring the project (coffee-machine analogy: milk is a separate pour even if you take it every cup); (2) **uniform pattern** — same shape as `notes/` and any future sharded domain like `docs/`; (3) **cleaner top-of-context signal** — `CLAUDE.md` becomes a 6-line directive instead of a thick wall of rules.

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

### D13. Shardable-domain pattern: folder + `INDEX.md` routing
**Decision:** Every shardable domain lives in its own folder with an `INDEX.md` router inside. Top-level files (`CLAUDE.md`, `README.md`) stay thin and point at the relevant `INDEX.md`. Applied today to `rules/`; **ready to apply to `README.md`** in a future session (the recipe is below).
**Why:** Two wins. (1) **Opt-in control** — even rules currently always loaded can be skipped on a given session without restructuring (coffee-machine analogy: milk is a separate pour even if you take it every cup). (2) **Uniform pattern** — once you know how `rules/` is shaped, you know how any future domain will be shaped. As a side benefit, `CLAUDE.md` shrank from a thick rulebook to a 6-line directive, which is much better signal at the top of every session's context.

**How `rules/` is organized today:**
- Default-load shards (loaded every session): `hygiene.md`, `voice.md`, `island.md`
- Triggered shards (loaded only when relevant): `session-end-notes.md`, `skill-snapshot.md`, `readme-decisions-log.md`
- `rules/INDEX.md` is the router that lists which loads when

**Recipe for next session — sharding `README.md`:**

1. Create a `docs/` folder at the project root.
2. Move each section of `README.md` into its own shard:
   - `docs/what-it-is.md` (the "What it is" section)
   - `docs/why.md` (the "Why it exists" section)
   - `docs/name.md` (the "Why the name 'vyasa'" section)
   - `docs/structure.md` (the "Project structure" tree + "What each component is" subsections)
   - `docs/provenance.md` (the "Provenance" section)
3. Move the decisions log into individual files under `docs/decisions/`, one per decision: `docs/decisions/D01-no-skill-scaffolding.md` through `docs/decisions/D14-dummy-language-voice.md` (and beyond as new decisions are added). Add `docs/decisions/INDEX.md` as a sub-router listing them in order.
4. Create `docs/INDEX.md` as the top-level router for `docs/`, pointing at the section shards and at `docs/decisions/INDEX.md`.
5. Trim `README.md` to a thin entry point: a short identity paragraph plus "see [`docs/INDEX.md`](docs/INDEX.md) for the full project bible."
6. Update `CLAUDE.md` if needed so any reference to "see README.md" becomes "see `docs/INDEX.md`" (currently no such reference exists — included as a checklist item just in case).
7. Append a new decision entry (next D-number, would be D15 or later depending on what's happened in between) recording the move.

### D14. Dummy-language voice as project default
**Decision:** Default prose voice in this project is plain English. Technical artifacts (file paths, commands, JSON, code blocks) stay literal. Any term introduced in prose gets glossed on first use in the session — e.g., "hook (a script that Claude Code runs automatically at certain moments)" the first time, "hook" after.
**Why:** vyasa is being used as a learning vehicle for AI. The user's stated principle: *to learn more about AI is to use it more.* The conversation itself is part of the learning surface, so over-jargon defeats the project's pedagogical purpose. Tradeoff accepted: explanations get longer, not shorter — clarity-for-learner beats terseness.

The operational details (when to gloss, what counts as a technical artifact, how the end-of-response recap interacts with this rule) live in `rules/voice.md`. This entry records the project-level decision.

### D16. PR / commit-message / PR-description conventions defined + commit validation enforced via hooks
**Decision:** Three sub-conventions land as the new shard `rules/git-workflow.md`:
1. Every workitem branch ships via a GitHub PR. Self-merge fine. **No direct commits to `main`.** The "best effort + direct-to-`main` acceptable" bootstrap mode in `D15 — Workitems checklist, branch-per-workitem, README-everywhere conventions` is retired.
2. Commit messages follow Conventional Commits with a fixed type / scope whitelist, ≤72-char subject, optional body wrapped at ≤100 chars, optional `Closes-workitem:` footer, required `Touches: D<N> — <title>` footer when a structural decision is touched, honor-system `Co-Authored-By:` trailer when AI assisted.
3. PR descriptions follow a fixed template with `## Summary`, `## Why`, `## Workitem`, `## Decisions touched`, `## Verification`, and `## Followups` sections.

Enforcement: `hooks/commit-msg` and `hooks/pre-commit` (bash, version-controlled under `hooks/`) hard-fail violations at commit time. One-time setup per clone: `git config core.hooksPath hooks`. PR-side enforcement (title + body-section checks via GitHub Actions) is a queued workitem.

**Why:** Without a spec for these surfaces, conventions live only in scrollback and decay. Without enforcement, even written rules slip silently. Bundling spec + enforcement in one pass means the first PR following these rules IS the PR that creates them — closing the loop instead of leaving a permanent escape valve.

### D15. Workitems checklist, branch-per-workitem, README-everywhere conventions
**Decision:** Three structural moves bundled in one pass:
1. `WORKITEMS.md` lives at the project root as the source-of-truth checklist for queued work. New default-load shard `rules/workitems.md` captures the convention. *(Superseded by `D17 — Workitems become a folder; open/done split; plan-before-build gate`: the ledger moved from the root file into the `workitems/` folder.)*
2. When a workitem is checked off, it gets its own git branch named after it (with a "trivially small items may bundle by explicit decision" exception). Bootstrap caveat: until PR / commit-message / PR-description conventions land (itself a queued workitem), best-effort + direct commits to `main` are acceptable.
3. Every directory or project under this tree carries a `README.md`. New default-load shard `rules/readme-convention.md` captures the rule. Project-scope only for now; may lift to global later.

Companion behavioral additions (in `rules/hygiene.md`, items 5–6): a **push-back-on-wrong-premises** rule and a **never-edit-global-CLAUDE.md-without-asking-twice** rule. Both rules were also lifted to global `~/.claude/CLAUDE.md` in this same pass — a rule about engagement style only works if every session sees it. Discovery during execution: `~/.claude/CLAUDE.md` is a symlink to `~/Desktop/Harsh/harsh-brain/CLAUDE.md`, so the "global" write actually lands inside the `harsh-brain` project. The new ask-twice rule (which we were installing) fired on its own first use, paused the global write, and the user re-confirmed before the write went through. The global file now carries a footnote noting the symlink so future sessions are not surprised.

**Why:** Conversation scrollback is unreliable for tracking queued work — agreed items vanish between sessions. A persistent checklist closes that gap. Branch-per-workitem keeps commits scoped to one logical unit and supports clean rollback. README-everywhere keeps per-directory context co-located instead of scattering it across project-level docs. The hygiene additions close two ways the assistant was previously executing on autopilot — accepting wrong premises and making wide-blast-radius global edits without pause.

### D17. Workitems become a folder; open/done split; plan-before-build gate
**Decision:** Two structural moves bundled in one pass, both under the workitems domain:
1. **`WORKITEMS.md` (single root file) → `workitems/` folder**, following the same folder-per-domain + `INDEX.md` pattern as `rules/` and `notes/` (`D13 — Shardable-domain pattern: folder + INDEX.md routing`). Layout: `workitems/INDEX.md` (router), `workitems/open.md` (live queue — a default-load candidate), `workitems/done.md` (archive of completed items, never auto-loaded), `workitems/plans/` (one plan per workitem, loaded on demand). The root `WORKITEMS.md` is deleted; its open items move to `open.md` and its closed items to `done.md`.
2. **Plan-before-build gate** added to `rules/workitems.md`: no workitem is implemented without a plan file in `workitems/plans/<slug>.md`, written and agreed before the branch is cut. Open items with no plan show `(no plan)`; planned items link to their plan. Plans are permanent (kept after the item closes). The first real plan shipped alongside this decision is `workitems/plans/sessionstart-load-rules.md` (the queued SessionStart-hook workitem), so the new structure ships with a working example rather than an empty folder.

**Why:** (1) The workitems domain grew from one concern (a checklist) to three (open queue, done archive, per-item plans) — that's the trigger in `D13 — Shardable-domain pattern: folder + INDEX.md routing` for promoting a domain to a folder. Splitting open from done also keeps the live list lean: completed items no longer bury pending work, and if `open.md` is auto-loaded, finished items don't burn context. (2) The plan-before-build gate forces design to precede code, so work starts from a written, agreed plan instead of improvised implementation — and the plan file becomes durable design history. Note on scope tension: `rules/readme-convention.md` says every directory carries a `README.md`, but sharded domains (`rules/`, `notes/`, now `workitems/`) use `INDEX.md` as the entry doc instead; reconciling that wording is a queued workitem, not resolved here.

### D18. Rule-loading moves from SessionStart hook to CLAUDE.md @import
**Decision:** The default-load rule shards now reach session context via a `CLAUDE.md` → `@rules/INDEX.md` → per-shard `@import` chain, not via the `SessionStart` hook `hooks/load-default-rules.sh`. The hook is deleted and `.claude/settings.json` is now an empty `{}`. `rules/INDEX.md` stays the single source of truth for *which* shards load — its six `@`-import lines are both the human router and the load mechanism, so there is no list duplication (Option A of the plan).

**Why:** The hook concatenated all six shards (~20KB) to stdout, but Claude Code caps `SessionStart` hook-stdout injection at ~10,000 chars — the overflow spills to a file and only a ~2KB preview reaches context. Net effect: only ~1 of 6 shards actually loaded, so the hook was effectively broken for a payload this size. `@import` expands imported memory files in full at launch with no such cap (verified v2.1.156–157), so it is strictly better for this job.

**Note on prior state:** the hook itself never had a D-entry — it shipped 2026-05-28 and was logged only in `plans/sessionstart-load-rules.md` and `workitems/done.md`. So D18 does not supersede a prior decision; it establishes, for the first time in the decisions log, the mechanism by which default rules load. `plans/sessionstart-load-rules.md` is annotated as superseded.

**Verified behavior (not assumed):** with the hook removed, a headless `claude -p` probe (file/search tools disabled, so the agent could answer only from preloaded context) returned a unique buried token from all six shard *bodies* — hygiene, voice, island, workitems, readme-convention, git-workflow. One delta from the hook: `@import` strips each shard's leading YAML frontmatter (`WHAT:`/`LOAD:` lines), so that metadata no longer reaches context. Accepted (user, 2026-05-29): frontmatter is descriptive routing metadata, not rules, and the same routing information still loads via `rules/INDEX.md` itself. No rule text is lost.

**Compaction (resolved 2026-05-31 — live test):** A fresh session (shipped state: empty `settings.json`, no hook, `@import` `CLAUDE.md`) confirmed launch-load, then ran a real `/compact` followed by a context-only probe. All three buried tokens — git-workflow commit-type whitelist, workitems plan-path, readme-convention "discoverability" — came back correct, so imported rules are present after compaction. **Mechanism observed:** `/compact` auto-re-reads the `@import`'d shard files while rebuilding context (visible as `Read rules/*.md` entries nested under the compact step), so the rules reload *by re-import*, not merely by surviving in the summary. The B3-b fallback (`compact`-only hook) is therefore unnecessary and not built. **Honest limitation:** because `/compact` reads the shard files itself, a clean zero-read probe could not be isolated — "did the summary alone carry the rules?" stays untested, but is moot: the auto re-import makes the rules present regardless.

### D19. Project-scope Claude Code Pre/PostToolUse hooks for edit verification
**Decision:** vyasa now runs a pair of Claude Code hooks, wired in `.claude/settings.json` at project scope (matcher `Edit|Write|MultiEdit`): `hooks/snapshot-before-edit.sh` (PreToolUse) captures a file's bytes *before* an edit, and `hooks/verify-diff.sh` (PostToolUse) diffs that snapshot against the post-edit bytes to surface the **exact delta a single edit made**. The summary is user-facing (`systemMessage`); when a reported-successful edit leaves the file byte-identical, a factual, neutral note is also injected into the model's context (`hookSpecificOutput.additionalContext`). This is the first non-empty `.claude/settings.json` since `D18 — Rule-loading moves from SessionStart hook to CLAUDE.md @import` emptied it. Design and full audit trail: `workitems/plans/diff-verification-hook.md`.

**Why:** The model can assert "I edited X to do Y" when the on-disk change is different, smaller, or absent. The only prior independent checks were the Edit tool's own `old_string`-mismatch error and the harness "file state is current" line — neither produces a content-derived, user-visible record of what *this specific edit* actually changed. The hook pair derives that record from the file's real before/after bytes, so it is independent of anything the model claims, and it factually reports the changed-nothing case rather than letting a silent no-op pass as a success.

**Why a snapshot pair, not `git diff`:** An earlier design (`git diff <file>` in a single PostToolUse hook) was found blocking-flawed in plan review — `git diff` shows the *cumulative uncommitted* delta vs the last commit, not this one edit's delta, so mid-session it is almost never empty and the headline "claimed an edit, disk shows nothing" case slips through. Capturing the pre-edit bytes is the only way to recover a true per-edit delta. The snapshot approach also works for untracked and git-ignored files (git is never involved) and for brand-new files.

**Key properties:** (1) **Fail-open** — any internal error emits nothing and exits 0; a broken verifier must never block a real edit. (2) **No-loop** — snapshots are written with raw shell (`cp`/redirection), never Claude's Edit/Write tools, so the snapshot write cannot re-trigger the hooks. (3) **Pairing** — Pre and Post correlate by the payload's `tool_use_id`, so two edits to the same file in one turn each report their own delta (counter fallback if that id is ever absent). (4) **Bounded cost** — snapshots are deleted after use; a 5 MB oversize guard caps the copy (the hook also fires on large non-repo files); output is hard-capped well under Claude Code's ~10,000-char hook-output limit. (5) **NotebookEdit excluded** — it uses `notebook_path` and JSON cell-diffs are noisy; the repo has no notebooks.

**Activation caveat (verified, not assumed):** Claude Code snapshots hook config at startup and does **not** reliably hot-reload `.claude/settings.json` edits mid-session (no `/reload` command exists as of this writing) — confirmed empirically this build session: a hook added mid-session did not fire. The hooks therefore take effect only from the next fresh session. The hook *logic* was verified this session by piping hand-made Pre/Post JSON payloads directly into the scripts (22 cases: modify, new file, no-op, git-ignored, non-repo cwd, two-edits-one-turn, orphan-silent, oversize, malformed-JSON, counter-fallback — all pass); the genuine end-to-end live trigger is verified in the next session.

**Collaborator trust model (verified via docs):** project-scope `command` hooks are not run silently in a fresh clone — Claude Code prompts for approval before executing them (the defense against a malicious hook committed to a repo). A collaborator cloning vyasa is asked to approve these two hooks on first use.

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
