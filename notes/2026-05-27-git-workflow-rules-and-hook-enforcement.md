# 2026-05-27 — Git workflow rules + hook enforcement

> Three rule additions shipped in one session, the last of them landing under its own enforcement.

---

## Context

The session started with two queued workitems from prior sessions (Inline decision-code expansion, Define PR/commit/PR-desc conventions) and an in-conversation rule addition (Log every workitem) shipped on the fly. By the end, all three were closed, `D16 — PR / commit-message / PR-description conventions defined + commit validation enforced via hooks` was appended to the README's Decisions log, two version-controlled git hooks were live, and the project's first real pull request (#1) was merged.

---

## Three rules shipped

### 1. Log every workitem — shipped-on-the-fly or deferred (`rules/workitems.md`)

Closed a gap in the existing workitems convention. Previously the rule only covered deferred work: "agreed-and-queued items live in `WORKITEMS.md`'s Open section." It didn't cover items agreed-and-completed in the same exchange — those silently skipped the ledger, making `git log` the only audit trail.

New rule: shipped-on-the-fly work appends directly to `WORKITEMS.md`'s Closed section with the commit/branch that delivered it. Treat the ledger as authoritative for every agreed change, not just queued ones. The rule's own addition was the first example.

### 2. Inline expansion of decision codes (`rules/voice.md`)

Decision codes (D1, D13, …) in `README.md`'s Decisions log are internal shorthand. They're not self-documenting; a reader landing in a commit log or PR title stalls on every bare code.

New rule: every D-code citation — anywhere, every mention — expands inline as `D<N> — <title verbatim from README's D-entry>`. Source of truth is the heading text in `README.md`'s Decisions log. Renames don't retroactively update old citations (history stays historical). Em-dash U+2014, not hyphen.

### 3. Git workflow conventions + enforcement (`rules/git-workflow.md` + `hooks/`)

The big one. Three sub-conventions in one shard, with hard enforcement.

- **PR convention.** Every workitem branch ships via GitHub PR. Self-merge fine; no required review delay. **No direct commits to `main`.**
- **Commit-message convention.** Conventional Commits with a fixed type whitelist (`feat`, `fix`, `docs`, `refactor`, `chore`, `test`, `eval`) and scope whitelist (`rules`, `notes`, `readme`, `workitems`, `hooks`, `cli`, `skills`, `fixtures`, `runs`, `reports`). ≤72-char subject, ≤100-char body lines (URL-only and trailer-style lines exempt). Optional `Closes-workitem:` footer; required `Touches: D<N> — <title>` footer when a structural decision is touched. Honor-system `Co-Authored-By:` trailer when AI assisted.
- **PR-description convention.** Fixed template: `## Summary`, `## Why`, `## Workitem`, `## Decisions touched`, `## Verification`, `## Followups`.

Enforcement: `hooks/commit-msg` (bash + perl) and `hooks/pre-commit` (bash). Version-controlled under `hooks/`, wired with `git config core.hooksPath hooks` as a one-time per-clone setup. Bypass via `--no-verify` requires explicit user permission per the universal hygiene rules.

The bootstrap exception in earlier `rules/workitems.md` ("best-effort + direct-to-main acceptable until rules exist") is retired.

---

## Decision recorded

`D16 — PR / commit-message / PR-description conventions defined + commit validation enforced via hooks` appended to `README.md`'s Decisions log. The decision is structural because it changes how every future change to the project flows into history.

---

## Hook implementation — non-obvious learnings

Caught during the test loop, worth keeping:

- **macOS BSD `grep` lacks `-P` (Perl-compatible regex).** The first pass of `hooks/commit-msg` used `grep -P '\bD\d+\b(?!\s+—)'` (negative lookahead). Silently no-op'd on macOS. Switched to perl for the D-code check (real regex + native Unicode `\x{2014}`). Same fix used for the body-line-length check, where `${#var}` in bash counts bytes not chars, and em-dashes (3 bytes UTF-8) inflate the count.

- **Trailer-syntax constraints: hyphenate the token.** Initial spec had `Closes workitem:` (with a space). That doesn't match standard git-trailer syntax (single hyphenated or CamelCase token, then `: `), and meant the exemption regex `^[A-Z][A-Za-z][A-Za-z-]*: ` would have to be loosened. Renamed to `Closes-workitem:`. Now plays nice with `git interpret-trailers` and the exemption regex stays tight.

- **`pos()` in perl follows the variable that was matched.** Initial D-code check looped `while (/\bD\d+\b/g)` (matches against `$_`) but called `pos($line)` (a different variable). `pos($line)` was undef, so the lookahead always saw an empty rest-of-line and never failed any D-code. Switched to `while ($line =~ /\bD\d+\b/g)` so `pos($line)` is meaningful.

- **macOS filesystem is case-insensitive by default.** `cp WORKITEMS.md /tmp/X/WORKITEMS.md.final` followed by `cp rules/workitems.md /tmp/X/workitems.md.final` collide on APFS. Use distinct names (`root-workitems.md`, `rules-workitems.md`) when staging copies.

---

## Topology of the three commits

A real puzzle. The session shipped three logical units but the new git-workflow rules (commit-3) retire the bootstrap exception that allowed commits 1 and 2 to go directly to `main`. The order matters.

Final sequence:

1. **Commit 1** (`6ef028e` — `docs(rules): log every workitem — shipped-on-the-fly or deferred`) lands on `main`. Bootstrap exception still active; hooks not wired.
2. **Commit 2** (`cf098e3` — `docs(rules): expand decision codes inline on every mention`) lands on `main`. Same.
3. `git push origin main` — durable.
4. `git checkout -b workitem/git-workflow-conventions`.
5. **All workitem-3 edits applied** (4 new files, 4 existing files updated).
6. `git config core.hooksPath hooks` — enforcement now live.
7. **Commit 3** (`4057f92` → rebased to `114829f` on main — `feat(rules): define PR/commit/PR-desc conventions and enforce via hooks`) passes its own hooks: `Touches: D16 — …` footer validated against the staged README, subject under 72, no bare D-codes, body lines under cap.
8. PR #1 opened, rebase-merged, branch deleted. Local main fast-forwarded.

Self-application achieved: the convention-creating commit IS the first commit governed by the convention.

---

## Outstanding state

- **`WORKITEMS.md` working-tree has one uncommitted bullet** (SessionStart hook to auto-load default rules into context). User chose to leave it uncommitted; next real workitem commit folds it in. Do not `git restore WORKITEMS.md` at the start of the next session — `git diff WORKITEMS.md` to confirm the bullet is still present.
- **Notes file + INDEX update** (this session): same fate. Uncommitted in working tree. Same fold-in plan.

---

## Queued workitems (post-session)

Open:

- Diff-verification hook to catch hallucinated edits
- **SessionStart hook to auto-load default rules into context** (added this session, uncommitted)
- PR-side CI enforcement (title + body-section checks via GitHub Actions)
- Tweak `rules/readme-convention.md` rule
- Record token usage per session for later analysis

Closed in this session:

- Log every workitem — shipped-on-the-fly or deferred
- Inline decision-code expansion
- Define PR, commit-message, and PR-description conventions

---

## Provenance

- Session date: 2026-05-27
- Commits added to `main`: `6ef028e`, `cf098e3`, `114829f`
- PR: <https://github.com/HarshPatel7x/vyasa/pull/1> (merged 2026-05-27 23:10 UTC)
- Hooks tested: 23/23 commit-msg cases + pre-commit branch-block + Touches: footer correctness
