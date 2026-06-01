# Plan — Diff-verification hook to catch hallucinated edits

> Workitem (from `workitems/open.md`): "Diff-verification hook to catch hallucinated edits. After
> any Edit/Write tool call, run a PostToolUse hook that diffs the file against pre-edit state and
> surfaces the actual delta. Goal: stop silent 'I edited X' claims from going unnoticed. Wire via
> `~/.claude/settings.json` at project scope (not global, until proven here)."

Status: **planned (rev 4, final — three audits folded in), awaiting build sign-off.** Plan-before-build
gate per `rules/workitems.md`.

> **Revision history.**
> - **Rev 1 → 2:** `architect` audit found a BLOCKING flaw — `git diff <file>` shows the *cumulative
>   uncommitted* delta vs the last commit, **not this one edit's** delta, so mid-session it is almost
>   never empty and the headline "claimed an edit, disk shows nothing" case slips through. Reworked
>   to a **PreToolUse-snapshot + PostToolUse-compare pair** (user decision, 2026-05-31).
> - **Rev 2 → 3:** a second `architect` audit confirmed the BLOCKING flaw is structurally fixed
>   (verdict: APPROVE WITH CHANGES) and surfaced nine refinements (NEW-1…NEW-9). All folded in below
>   and tagged inline as `[NEW-n]`.
> - **Rev 3 → 4:** a third `architect` audit (final sign-off check) confirmed all nine are genuinely
>   present and the D19 commit footer will pass `commit-msg`; it added five tightenings — folded in
>   and tagged `[final-1]`/`[final-2]` (the rest: oversize guard, `.meta` format, `jq` probe) inline.

---

## Problem

The model can assert "I edited file X to do Y" when the on-disk change is different, smaller, or
absent. Today the only independent checks are: (a) the Edit tool errors loudly if `old_string`
doesn't match, and (b) the harness line "file state is current in your context." Neither produces a
**user-visible, content-derived record of what *this specific edit* actually changed**. We want an
automatic signal — sourced from the file's real before/after bytes, not from the model's claim —
that surfaces the real per-edit delta and factually reports when a "successful" edit changed nothing.

## Mechanism (final): snapshot pair

True per-edit truth requires capturing the file *before* the edit, because anything read *after* the
edit (git diff, the post-edit file) cannot recover what this single edit changed.

- **PreToolUse hook** (`hooks/snapshot-before-edit.sh`): fires *before* Edit/Write/MultiEdit. Copies
  the target file's current bytes to a snapshot outside the repo, plus a sidecar metadata file. If
  the file does not exist yet (new file via Write), writes a metadata record marking it `new` and an
  empty snapshot.
- **PostToolUse hook** (`hooks/verify-diff.sh`): fires *after* the same tools. Diffs the snapshot
  against the file's current bytes → **the exact delta this edit made**, for *any* file (tracked,
  untracked, or git-ignored — git is not involved). Surfaces a compact summary; if the tool reported
  success but the bytes are identical, factually reports "no change."

This sidesteps the rev-1 blocking flaw and the non-git / git-ignored holes in one move.

## Honest scope — what this hook does and does NOT add

- **Does add:** a true per-edit, content-derived diff the *user* sees, plus a factual
  **changed-nothing** note injected into the model's context when an edit was byte-identical
  (a neutral signal, not an accusation — see `[NEW-2]`). Independent of anything the model claims.
  Works for non-git files.
- **Does NOT add:**
  - Protection against a *correct* edit *described* misleadingly in prose — it shows the diff, a
    human still reads it.
  - **Coverage of failed edits.** PostToolUse fires only on tool *success*. An Edit the harness
    *rejects* (e.g. `old_string` mismatch) produces no PostToolUse event, so "failed edit narrated
    as success" is out of scope — already covered by the tool's own loud error.
  - Catching edits made outside Claude's Edit/Write tools (e.g. a `Bash` `sed`); only matched tools
    are snapshotted.
- **Cost:** fires on *every* edit. Output is hard-capped tiny; user-facing by default; model-context
  injection ONLY in the changed-nothing case, to keep the hot path cheap. Snapshots are full-file
  copies — acceptable here because this repo holds only small text files (see `[NEW-8]`).

## Verified technical facts (treat ALL as build-verify; capture a real payload in step 2)

Per hygiene rule 1 (never assert system state from docs), every item below is provisional until a
real hook payload confirms it. The guide-sourced starting points:

- Pre/PostToolUse receive JSON on stdin including `session_id`, `cwd`, `tool_name`, and
  `tool_input.file_path` (absolute). PostToolUse additionally has `tool_response`.
- **Field names are harness-specific.** The guide reported Edit fields as `old_str`/`new_str`, but
  this harness's Edit tool uses `old_string`/`new_string` and Write uses `content`. The mechanism
  depends only on `file_path` + `session_id` (+ a per-call id if one exists — `[NEW-1]`), which are
  stable; it deliberately does not parse the brittle old/new fields.
- **Output routing (verify in step 2 — `[NEW-9]`):** `hookSpecificOutput.additionalContext` is
  believed to inject into the *model's* context; `systemMessage` is believed *user-facing only*;
  plain stdout is shown. Confirm by emitting a known sentinel string from each and observing where
  it lands.
- **Output size cap (verify in step 2 — `[NEW-9]`):** believed ~10,000 chars (the cap that defeated
  the old SessionStart loader — see `D18 — Rule-loading moves from SessionStart hook to CLAUDE.md
  @import`). That number is asserted *by analogy* to a different hook event; confirm the actual cap
  for Pre/PostToolUse. Regardless, keep output well under it and truncate hard.
- **Project-dir variable (verify in step 2):** the settings.json `command` is believed to expand
  `$CLAUDE_PROJECT_DIR`; confirm that is the variable this harness exposes.
- Matcher scopes by tool name, pipe-separated regex (e.g. `"Edit|Write"`). Config lives under
  `hooks.PreToolUse[]` and `hooks.PostToolUse[]` (each `matcher` + `.hooks[].{type,command}`) in
  `.claude/settings.json` (project scope). Currently `.claude/settings.json` is `{}`.

## Snapshot storage design

- **Location:** outside the repo so snapshots never appear in `git diff` and never get committed —
  `${TMPDIR:-/tmp}/claude-diff-verify/<session_id>/`.
- **Key `[NEW-1]`:** `<path-hash>.<call-id>` where `path-hash = shasum(resolved-abs-path)` and
  `call-id` is a per-tool-call identifier. In step 2, check the payload for a `tool_use_id`/`call_id`
  field and use it as `call-id`; if none exists, use a monotonic counter file
  (`${dir}/.counter`, incremented via a raw shell write) so two edits to the *same* file in one turn
  get *distinct* snapshots and cannot overwrite each other. PostToolUse recovers the matching id from
  its OWN payload's `tool_use_id`/`call_id` (the same field), so Pre and Post pair **deterministically**
  whenever that id exists. **Counter fallback (only if step 2 finds no per-call id):** Pre records the
  assigned counter value in a turn-scoped marker (`${dir}/<path-hash>.last`) that Post reads; even so,
  without a real per-call id, two same-file edits in one turn are a *documented best-effort*, and
  step 4(f) **records the observed behavior** rather than asserting a guaranteed pass.
- **Sidecar metadata `[NEW-3]`:** alongside each `<key>.snap`, write `<key>.meta` for the label.
  **Format (pinned to survive odd paths):** fixed `key=value` lines — `existed=yes|no`,
  optionally `skipped=oversize` (see oversize guard in step 3), and `path_b64=<base64 of the resolved
  path>` (base64 so a path containing `=`, spaces, or newlines cannot break the parse). PostToolUse
  reads it with a fixed parser, not a fuzzy `grep`. **`.meta` is authoritative:** PostToolUse trusts a
  result only if `.meta` exists. Absent `.meta` → fail-open silent (see `[NEW-4]`) — this is how
  "new file" (`existed=no`, `.meta` present) is distinguished from "Pre never ran" (`.meta` absent).
- **Symlinks `[NEW-7]`:** snapshot the *resolved target's* bytes and key by the *resolved* absolute
  path (the Edit tool writes through a symlink to its target), so a link and its target never get two
  divergent snapshots.
- **Writes use raw shell `cp`/redirection — never Claude's Edit/Write tools** — so the snapshot write
  cannot re-trigger Pre/PostToolUse. This is the load-bearing no-loop guarantee; step 4 *verifies* it
  rather than assuming it (`[#7]`).
- **Cleanup:** PostToolUse deletes its own `<key>.snap`+`<key>.meta` after use. Snapshots orphaned by
  a rejected/denied edit (Pre fired, Post never did) are swept by best-effort removal of the whole
  `<session_id>/` dir — decide at build whether to add a `SessionEnd`/`Stop` sweeper hook or rely on
  OS `TMPDIR` cleanup (Risk 4).

## Output shape

Compact, fixed-size — not the raw diff dumped wholesale:
```
[edit-verify] <relative-or-abs path>  +<added> -<removed> lines   (modified | NEW file | no change)
  <up to ~25 lines of unified diff, then "... (truncated, N more lines)">
```
- **`+/-` counts `[#11]`:** computed from `diff` output **excluding** the `+++`/`---` file headers and
  `@@` hunk headers, so they reflect a real line delta.
- **Hard-cap** total emitted text at ~3,000 chars — never approaches the output-size threshold.
- **Changed-nothing case `[NEW-2]`:** when bytes are identical after a reported success, emit a
  user line `(no change)` AND `hookSpecificOutput.additionalContext` worded **factually and
  neutrally** — e.g. `"edit-verify: <path> is byte-identical to its pre-edit state; this edit
  changed nothing on disk."` No "verify your claim" / accusatory phrasing (avoids crying wolf on
  legitimate no-op edits, e.g. `new_string` == `old_string`). The model self-assesses from the fact.

## Implementation steps (bite-size, for the build session)

1. Create branch `workitem/diff-verification-hook`.
2. **Capture a real payload FIRST (resolves the build-verify items above).** Temporarily wire a
   one-line PreToolUse + PostToolUse hook that appends stdin to a tmp log; trigger one Edit and one
   Write; confirm: (a) field names (`file_path`, `cwd`, `session_id`, `tool_response`); (b) whether a
   per-call id (`tool_use_id`/`call_id`) exists `[NEW-1]`; (c) where `additionalContext` vs
   `systemMessage` vs stdout land `[NEW-9]`; (d) the actual output-size cap `[NEW-9]`; (e) that
   `$CLAUDE_PROJECT_DIR` is the real project-dir variable; (f) whether `jq` is on the hook's PATH
   (else use a `sed`/`grep` fallback, so step 3 isn't written against an unconfirmed dependency
   `[Risk 3]`). Remove the logger.
3. Write `hooks/snapshot-before-edit.sh` (PreToolUse) and `hooks/verify-diff.sh` (PostToolUse), both
   executable, both **fail-open** (any internal error → emit nothing meaningful and `exit 0`; never
   block a real edit because the verifier failed `[#4/#5]`). **Pin the `set -e` guard idiom `[NEW-5]`:**
   capture diffs as `out=$(diff "$snap" "$file" || true)` (`diff` exits 1 when files differ — normal,
   not an error). PostToolUse with no matching `<key>.meta` → emit nothing, `exit 0` `[NEW-3/NEW-4]`.
   **Oversize guard (enforces the `[NEW-8]` decision in code, not just prose):** before copying, if
   the pre-edit file exceeds a size cap (default 5 MB), Pre writes `.meta` with `existed=…` +
   `skipped=oversize` and snapshots no bytes; Post then emits one line `(skipped: file too large to
   verify)` and `exit 0`. This bounds cost because the hook also fires on large *non-repo* / git-
   ignored files, not only this repo's small text files.
4. Poke each script with hand-made JSON for: (a) modify a tracked file; (b) modify a git-ignored
   file; (c) create a NEW file (`existed=no`); (d) success but byte-identical content (no-op);
   (e) `cwd` outside any repo; (f) **two edits to the same file in one turn** (`[NEW-1]` collision
   test); (g) PostToolUse with no prior snapshot (`[NEW-4]` → silent). Confirm correct summary +
   `exit 0` each time, and **confirm the snapshot `cp` does NOT trigger another Pre/PostToolUse**
   (`[#7]` no-loop check).
5. Wire both hooks in `.claude/settings.json` (project scope), matcher `"Edit|Write"` — **verify at
   build whether `MultiEdit`/`NotebookEdit` exist in this harness** and add them if so. `command` =
   explicit interpreter + project-dir-resolved path, e.g.
   `bash "$CLAUDE_PROJECT_DIR/hooks/verify-diff.sh"` — never a bare relative path `[#6]`.
6. **Verify collaborator auto-run behavior `[#9]`:** determine *with a tool, not a guess* what a
   fresh clone does when it hits a committed auto-run `command` hook (silent trust? approval
   prompt?). Document the finding in `hooks/README.md`.
7. Update `hooks/README.md` to cover the two new Claude-Code hooks (distinct from the git hooks
   `pre-commit`/`commit-msg`, which ride `core.hooksPath`; these ride the settings.json `command`).
8. **Write README decisions-log entry D19 `[#8]`.** Pin the exact heading string ONCE and copy it
   verbatim into the commit footer `[NEW-6]`:
   `### D19. Project-scope Claude Code Pre/PostToolUse hooks for edit verification`
   The commit touching `README.md` MUST carry, verbatim (em-dash U+2014, per `commit-msg`):
   `Touches: D19 — Project-scope Claude Code Pre/PostToolUse hooks for edit verification`
   (The `commit-msg` hook compares the footer against the *staged* `### D19.` heading; heading and
   footer must be authored in the same commit and match exactly.) **Also `[final-1]`:** any *other*
   D-code mentioned anywhere in this commit message (e.g. `D18`) must carry its own ` — <title>`
   em-dash expansion, or `commit-msg` hard-fails the whole message.
9. Live test in-session: a real Edit, a real Write, and a deliberately staged "claim big, change
   small / change nothing" case to confirm the per-edit diff and the factual no-change note are
   content-derived.
10. Move the workitem to `done.md`; open PR (title + body per `rules/git-workflow.md`).

## Verification (how we'll know it works)

- **True per-edit delta:** two sequential edits to the same file → the second summary shows only the
  *second* edit's lines, not the cumulative since last commit (the rev-1 failure mode). `[#1]`
- **Changed-nothing signal:** an edit that leaves bytes identical after a reported success → `(no
  change)` shows AND the factual `additionalContext` note is injected, with no accusatory wording.
  `[NEW-2]`
- **Same-file-twice-in-one-turn `[final-2]`:** *if* step 2 found a per-call id → each edit reports
  its own correct delta (a pass/fail gate); *if* only the counter fallback exists → record the
  observed behavior, and a collision is a documented limitation, not a build failure. This matches
  the best-effort caveat in the mechanism section (no contradiction). `[NEW-1]`
- **New vs missing baseline:** a genuinely new file reports the whole file as the delta; a
  PostToolUse with no prior snapshot stays silent (no false giant `NEW file`). `[NEW-3/NEW-4]`
- **Non-git coverage:** a git-ignored file still shows a correct delta. `[#12]`
- **Fail-open:** malformed JSON / missing snapshot / non-repo cwd → emits nothing harmful, `exit 0`,
  edit never blocked. `[#4/#5]`
- **No re-entrancy:** the snapshot `cp` does not trigger another Pre/PostToolUse (no infinite loop).
  `[#7]`
- **Respects the cap:** a 5,000-line edit → output truncated well under the cap, no file spill.
- **Scoped correctly:** neither hook fires on Bash/Read.

## Risks / open questions to resolve at build time

1. Exact stdin field names + per-call id + output keys + cap — all captured in step 2 before real
   logic (`[NEW-1]`, `[NEW-9]`).
2. Whether `MultiEdit`/`NotebookEdit` exist here and belong in the matcher.
3. `jq` availability in the hook exec environment vs a `sed`/`grep` fallback.
4. Stale/orphaned snapshot lifecycle for rejected/denied edits — `TMPDIR` cleanup vs a `SessionEnd`
   sweeper hook; decide at build.
5. Symlink behavior confirmation (intended rule pinned in Snapshot storage `[NEW-7]`; verify
   empirically).
6. Collaborator auto-run-approval behavior (step 6) — a real answer before shipping a committed
   `command` hook (`[#9]`).

## Audit trail

- Rev-1 audit (BLOCKING flaw → snapshot rework) and rev-2 audit (APPROVE WITH CHANGES, NEW-1…NEW-9)
  were performed by the `architect` agent on 2026-05-31. This rev-3 folds all NEW-n items in; a final
  review of rev 3 was requested before build sign-off.
