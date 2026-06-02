# Project structure

> The full layout of vyasa, what each component is for and why, and how the tool will be used
> once `cli/` lands. The root `README.md` routes here for the detail.

## Project structure

```
vyasa/
├── CLAUDE.md                    # thin entry point — points at rules/README.md
├── README.md                    # thin entry — project identity + a router into docs/
├── .gitignore                   # ignores runs/, draft reports, OS junk
│
├── docs/                        # the project's substantial documentation (routing README)
│   ├── README.md                # router: what docs/ holds
│   ├── overview.md              # what vyasa is, why it exists, why the name
│   ├── structure.md             # this file — the tree + what each component is
│   └── decisions.md             # the Decisions log (every structural call + rationale) + provenance
│
├── .github/                     # GitHub-side automation (CI)
│   ├── README.md                # what the CI surface is + the COMMIT_REF-seam note
│   ├── workflows/
│   │   └── pr-format-check.yml  # enforces PR title/body + per-commit msgs server-side
│   └── scripts/
│       └── pr-format-check.sh   # the validation logic (title | body | commits)
│
├── hooks/                       # version-controlled git + Claude Code hooks
│   ├── commit-msg               # validates commit message format (COMMIT_REF seam for CI)
│   ├── pre-commit               # blocks direct commits on main
│   ├── snapshot-before-edit.sh  # PreToolUse: snapshots a file before an edit
│   └── verify-diff.sh           # PostToolUse: surfaces the real per-edit delta
│
├── rules/                       # sharded project rules (routing README + shards)
│   ├── README.md                # router: which shards load when (+ the six @import lines)
│   ├── hygiene.md               # default-load: honesty, verification, context status
│   ├── voice.md                 # default-load: dummy-language voice + recap
│   ├── island.md                # default-load: no harsh-brain wiring; README + docs/ is bible
│   ├── workitems.md             # default-load: workitems/ folder convention + plan-before-build
│   ├── session-end-notes.md     # triggered: session end with decision/plan/build/learn
│   ├── skill-snapshot.md        # triggered: bringing a skill under test
│   └── readme-decisions-log.md  # triggered: a structural decision is made or changed
│
├── workitems/                   # the ledger of queued + completed work (folder-per-domain)
│   ├── README.md                # router
│   ├── open.md                  # live queue of pending work (default-load candidate)
│   ├── done.md                  # archive of completed items (never auto-loaded)
│   └── plans/                   # one plan per workitem; plan-before-build gate
│       ├── README.md
│       └── <slug>.md            # load on demand when you pick up an item
│
├── notes/                       # session lecture-notes (newest-first index)
│   ├── README.md
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
Why it's here: every Claude Code session in this directory needs a starting instruction. The actual project rules live as shards under `rules/`; `CLAUDE.md` just says "read `rules/README.md` and follow it." Keeps the auto-loaded file tiny and signals at the top of context that the rules are modular. The one rule that DOES live in `CLAUDE.md` itself is the folder-per-domain + `README.md` router convention — because that convention describes how every other rule is organized, it has to be known before any of them.

### `rules/`
Why it's here: project rules are sharded by concern rather than lumped into one rulebook. `rules/README.md` is the router; each shard handles one concern (`voice.md`, `hygiene.md`, `island.md`, …). Three wins: (1) **opt-in control** — even rules currently always loaded can be skipped on specific sessions without restructuring the project (coffee-machine analogy: milk is a separate pour even if you take it every cup); (2) **uniform pattern** — same shape as `notes/` and `docs/`; (3) **cleaner top-of-context signal** — `CLAUDE.md` becomes a 6-line directive instead of a thick wall of rules.

### `docs/`
Why it's here: the root `README.md` is a thin entry point, so the substantial documentation — what vyasa is (`overview.md`), the full structure (`structure.md`), and the decisions log (`decisions.md`) — lives in shards under `docs/` with `docs/README.md` as the router. The decisions log in particular is append-only and monotonically growing; giving it its own file keeps the entry point from re-bloating as decisions accrue, and it is the file the `Touches: D<N>` commit-message footer validates against.

### `notes/`
Why it's here: chat transcripts are unreadable later. Lecture/meeting-minutes notes are. After every significant session (decision/plan/advice/built/learnt), the assistant prompts to write a notes file capturing what was decided + why. `README.md` makes the folder navigable — without it, the folder is a graveyard.

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

## How to use vyasa (future state)

> **Skeleton-only today.** No runner code exists. This section will be filled in when `cli/` lands.

The intended flow:
1. Bring a skill under test: copy its current state to `skills/<name>/baseline/`, copy the candidate version to `skills/<name>/candidate/`.
2. Write fixtures: trigger cases + negative cases (and golden outputs if you have them) in `fixtures/<name>/`.
3. Run the comparator (TBD): produces output under `runs/<timestamp>-<name>-<variant>/`.
4. Generate a report (TBD): lands in `reports/`.
5. If the report justifies promotion, move it to `reports/decisions/` and commit.
