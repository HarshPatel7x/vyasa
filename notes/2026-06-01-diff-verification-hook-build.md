# 2026-06-01 — Building the edit-verification hook (and an audit-until-clean loop)

> Session minutes. Built and shipped the diff-verification hook pair planned on 2026-05-31;
> shipped via PR #9. Branch `workitem/diff-verification-hook` (rebased onto current main first).

---

## What we set out to do

Pick up the parked `workitem/diff-verification-hook` plan and actually build it. The plan
(rev 4, already through three architect audits at planning time) specified a **snapshot pair**:
a PreToolUse hook that copies a file's bytes *before* an edit, and a PostToolUse hook that diffs
that snapshot against the after-bytes — so the change a single edit really made is derived from
the file's bytes, not from anything the model says it did.

## What happened, in order

1. **Rebased the parked branch onto main first.** The branch predated the voice-rule work and the
   2026-05-31 session note that had since merged, so it was behind. Rebased (one INDEX conflict,
   resolved by keeping the union of plan entries), force-pushed with `--force-with-lease`.

2. **Found the foundational constraint by testing, not assuming.** Wired a temporary logger hook
   into `.claude/settings.json` mid-session and triggered an edit — it never fired. Claude Code
   **snapshots hook config at startup and does not reliably hot-reload it** (no `/reload` command).
   This reshaped the whole session: the hook *logic* could be built and tested here, but the genuine
   live end-to-end trigger has to wait for a fresh session.

3. **Resolved the plan's open schema questions against the docs** (via the claude-code-guide agent).
   The big unknown — does a per-tool-call id exist? — resolved YES: `tool_use_id` is present in both
   Pre and Post payloads, so the two hooks pair deterministically. Also confirmed: `systemMessage`
   is user-facing, `additionalContext` injects into the model's context, the output cap is ~10,000
   chars, and `MultiEdit`/`NotebookEdit` both exist.

4. **Wrote the two scripts** and tested the logic by piping 22 hand-made JSON payloads straight into
   them — no live hooks needed for that. All green.

5. **Ran the audit-until-clean loop the user asked for** (three independent `auditor` agents):
   - **Round 1** found three real defects: the output cap used `cut -c` (per-line, so multi-line
     output ballooned to ~72k chars), the `+/-` counter miscounted content lines beginning with
     `++`/`--`, and `session_id` flowed unsanitized into a filesystem path (traversal). All fixed.
   - **Round 2** returned SHIP with two nice-to-haves (a misleading comment; a counter-fallback that
     orphaned snapshots). Both cleared — the fallback was upgraded to a FIFO queue.
   - **Round 3** returned SHIP with **zero faults** in every actionable tier.

6. **Shipped:** D19 added to the README decisions log, workitem moved to `done.md`, committed
   (passing both git hooks), PR #9 opened and merged, branch deleted.

## Decisions / departures from the plan

- **`NotebookEdit` deliberately excluded** from the hook matcher (`Edit|Write|MultiEdit` only): it
  carries `notebook_path` not `file_path`, its JSON cell-diffs are noisy, and the repo has no
  notebooks. Documented in `hooks/README.md` and D19.
- **Counter fallback kept but rewritten as a FIFO queue** rather than dropped. `tool_use_id` is
  confirmed always present, so the fallback is dead code on the live path — but making it correct
  (each snapshot consumed by exactly one Post, queue self-removing) was cheap and closed the only
  audit finding left standing.
- **D19** is the first non-empty `.claude/settings.json` since D18 emptied it.

## Lessons

- **A documented hook is not a live hook.** The single most important finding came from *trying* the
  thing (wire a logger, trigger an edit, watch nothing happen) rather than trusting either the plan
  or the docs. Hooks don't hot-reload here; that fact had to be discovered, and it changes what
  "verified" can honestly mean this session.
- **"Audit until zero faults" earns its keep on round 1, not round 3.** The first auditor found a
  real 7×-over-limit output bug and a path-traversal hole that the 22 in-house tests had not. The
  later rounds mostly confirmed — but the loop is justified by the round that finds the thing you
  could not see in your own code.
- **Honest scoping beats a fake green check.** Rather than claim a live test that can't run, the
  build records "logic verified by tests + audits; live trigger verified next fresh session" in the
  PR, the README, and `done.md`. The caveat travels with the artifact.

## Follow-on state

- The hooks are wired and merged but **dormant until the next fresh Claude Code session** — that
  session is where the real live trigger gets observed for the first time.
- Still open in the ledger: PR-side CI enforcement, the README-convention tweak, per-session token
  logging — all still `(no plan)`.
