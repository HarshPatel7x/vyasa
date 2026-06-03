# 2026-06-03 — Skeleton spin-out, and the unmeasured-vyasa finding

> Session type: explore → advise → build-elsewhere. Started from the user's question "is vyasa's
> structure a transferable skeleton, and is there data behind it?" Ended by extracting a generic,
> self-configuring project skeleton into its OWN repo at `~/Desktop/Harsh/skeleton` (local only,
> 2 commits, not pushed). vyasa itself was left completely untouched — by design.

---

## What happened

The user wanted to reuse vyasa's folder-and-rules structure to organize *other* projects — their
immediate, real need being a cluttered job-search / resume / plans document pile where the mess was
making Claude's answers worse and navigation hard. Three questions drove the session: (1) is the
structure worth lifting, (2) how would you prove it works, (3) how do you de-vyasa it so it
transfers. We designed a generic "skeleton" kit, ran four rounds of adversarial review (the design,
then the in-vyasa-vs-separate-repo question, then the built files twice), and built it as a
standalone repo rather than inside vyasa.

## Findings about vyasa (the point of this note)

**1. vyasa has never measured itself.** The eval directories that justify the whole project —
`fixtures/`, `runs/`, `reports/`, `skills/` — are still `.gitkeep`-only. vyasa is described as
existing "to measure the skill system," yet every artifact it holds is about its own conventions;
it has produced zero measurements. The user's instinct ("without the data backing it") was exactly
right and sharper than expected: there is no data.

**2. The transferable value is navigation, not enforcement.** Reviewers converged: the genuinely
portable, Claude-helping parts are the thin-entry + README-router + decisions-log discoverability
spine. The *enforcement* machinery — git-workflow, the commit-msg / pre-commit hooks, the PR-format
CI, the D-code / `Touches:` apparatus — is vyasa-specific bureaucracy that breaks or is simply wrong
in a non-code project, and the always-loaded rule spine is a context tax that can *reduce*
adherence, not improve it. A clean lift keeps the spine and drops the bureaucracy.

**3. The skeleton was deliberately NOT put inside vyasa.** A reviewer flagged that a general-purpose
scaffolder living inside the skill-measurement island would muddy vyasa's identity, and that storing
a nested template (its own `CLAUDE.md`, hooks, placeholders) inside a live hooked repo invites real
problems — a nested `CLAUDE.md` auto-loading into vyasa sessions, and vyasa's own commit-scope
whitelist hard-failing `feat(skeleton): …`. Spinning it into its own repo dissolved all of those at
once and kept vyasa an island. vyasa's structure is unchanged; no D-entry was warranted.

## The eval design (parked, but captured so it isn't lost)

If the "prove the structure works" thread is ever picked up:

- **"monolith CLAUDE.md vs modular" is the wrong axis.** Because the modular setup `@import`s all
  shards at launch, Claude sees ~the same context either way; that A/B measures human file-tidiness,
  not model behaviour — expect a null result for the wrong reason.
- **The axis with teeth: how lean can the always-loaded core be before rule-adherence drops?**
  Arms: bare (no CLAUDE.md) / monolith / modular-all-loaded / modular-lean.
- **Measure (cheap, mechanical first):** rule-adherence (did it branch, recap, write a README —
  grep/git-checkable), navigation cost (tool-calls / files-read to first correct edit), token cost,
  turns. Save task-correctness (needs gold answers) for later.
- **Controls:** N≥5 runs/arm (nondeterminism), a small task battery (not one task), and grading
  ranked mechanical > LLM-judge > human-eyeball. The cheapest first experiment fills the empty
  `runs/` + `reports/` dirs and converts "I feel it's compelling" into a number.

## Loose ends

- The skeleton kit has known, deferred defects (its `apply.sh` overwrites existing files; it ships
  coding-gear by default; an orphan decisions log; no navigation rule). They live with the skeleton
  repo (`~/Desktop/Harsh/skeleton/NOTES.md`), not vyasa. Safe interim use: only ever apply it into
  an empty folder.
- The eval above is unstarted and unprioritised; this note is its only record.
