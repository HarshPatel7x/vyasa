# vyasa

> *Skill-eval harness for the harsh-brain stack. Takes two versions of a skill,
> runs them against the same fixtures, measures the deltas.*

---

vyasa compares two versions of a Claude Code skill (a "baseline" and a "candidate") against the
same fixture inputs and measures the behavioral deltas between them. It is the measurement layer
that turns skill-version promotion from intuition into evidence.

This README is a thin entry point — project identity plus a router. The substantial documentation
lives in [`docs/`](docs/README.md):

- [`docs/overview.md`](docs/overview.md) — what vyasa is, why it exists, why the name "vyasa".
- [`docs/structure.md`](docs/structure.md) — the full project tree + what each component is and why.
- [`docs/decisions.md`](docs/decisions.md) — the Decisions log: every structural call + its rationale.

## Top-level directories

| Directory | What it holds | Documented in |
|-----------|---------------|---------------|
| `rules/` | sharded project rules (router + shards) | [`rules/README.md`](rules/README.md) |
| `notes/` | session lecture-notes, newest-first | [`notes/README.md`](notes/README.md) |
| `workitems/` | the ledger of queued + completed work | [`workitems/README.md`](workitems/README.md) |
| `docs/` | the project's substantial documentation | [`docs/README.md`](docs/README.md) |
| `hooks/` | version-controlled git + Claude Code hooks | [`hooks/README.md`](hooks/README.md) |
| `.github/` | GitHub-side CI automation | [`.github/README.md`](.github/README.md) |
| `skills/`, `fixtures/`, `runs/`, `reports/`, `cli/` | eval-harness surfaces (skeleton today) | [`docs/structure.md`](docs/structure.md) |

Claude sessions bootstrap from [`CLAUDE.md`](CLAUDE.md), which loads the rules in [`rules/README.md`](rules/README.md).
