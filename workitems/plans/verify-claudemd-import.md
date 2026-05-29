# Plan — Verify CLAUDE.md `@import` as the rule-load mechanism

> Workitem: "Verify CLAUDE.md `@import` as the rule-load mechanism" (see [`../open.md`](../open.md)).
> Status: **executed this session** — see Results at the bottom.
> Scope: verification only. The actual hook→import migration is a separate, gated workitem.

## Problem

The SessionStart hook `hooks/load-default-rules.sh` concatenates all six default-load shards
(hygiene, voice, island, workitems, readme-convention, git-workflow) and prints them to stdout
for injection at session start. That output is **~20KB (20,237 bytes)**.

Claude Code caps hook stdout injected into context at **10,000 characters** (documented in the
hooks reference). When output exceeds the cap, the full text is written to a file on disk and
only a preview is surfaced in context. Observed this session: the SessionStart hook "succeeded"
but only a ~2KB preview (the `hygiene.md` shard, partially) reached context; the other five
shards sat in a `tool-results/hook-*.txt` file and never loaded.

So the hook *runs* but its purpose — getting the rules in front of the model — is mostly defeated
for a load this size.

## Why this reopens a closed decision

[`plans/sessionstart-load-rules.md`](sessionstart-load-rules.md) considered `@import` as its
**Option 1** and rejected it in favour of the hook, on the grounds that the load-list would be
**duplicated** (CLAUDE.md imports + `rules/INDEX.md` prose) and could drift.

That rejection was made **without knowledge of the 10K hook-output cap**. The cap is decisive new
evidence: the hook cannot deliver a 20KB load regardless of how clean its single-source-of-truth
story is. So Option 1 is back on the table — but only if `@import` actually expands at launch in
this Claude Code version. Hence: verify before deciding (hygiene rule #1 — never assert system
state from docs alone).

## Options considered (for the verification method)

1. **Headless `claude -p` probe (CHOSEN).** Put a unique sentinel token in a file, `@import` it
   into `CLAUDE.md`, then run `claude -p "<ask for the token>"` from the project root. If the
   fresh headless instance returns the token, `@import` expanded at launch. Self-contained,
   observable in-session, no dependence on the user restarting. `claude` CLI confirmed present
   (v2.1.156).
2. **User `/clear` + restart (FALLBACK).** Add the sentinel import, ask the user to `/clear`, and
   check whether the token appears in the next session's context. Works, but needs a session
   boundary and a human in the loop.

## Implementation (verification steps)

1. Create branch `workitem/verify-claudemd-import` (done).
2. Create a sentinel file `rules/_import-probe.md` containing a unique token unlikely to appear by
   chance.
3. Append a temporary `@rules/_import-probe.md` import line to `CLAUDE.md`.
4. Run `claude -p` with a prompt asking only for the token. Capture stdout.
5. **Clean up unconditionally**: remove the import line from `CLAUDE.md` and delete
   `rules/_import-probe.md`, so the verification leaves no residue. The branch keeps only this
   plan + the `open.md` entry.
6. Record the verdict in this plan's Results section.

## Verification (verify — do not assert)

- **Pass:** the probe's stdout contains the sentinel token verbatim ⇒ `@import` expands into
  context at launch in this version.
- **Fail / inconclusive:** token absent ⇒ fall back to the user-restart method before drawing any
  conclusion; do not assert either way.

## Out of scope (separate workitems, gated on this result)

- The real hook→import migration (turn `CLAUDE.md`'s prose pointer into `@rules/...` import lines;
  decide the fate of the hook and the INDEX-prose-vs-import duplication).
- The `git-workflow.md` path-scoping optimization already noted in `sessionstart-load-rules.md`.

## Results

**PASS — verified 2026-05-29, Claude Code v2.1.156.**

Method: created `rules/_import-probe.md` holding the token `VYASA-IMPORT-PROBE-Z7QK9X-2026`,
appended `@rules/_import-probe.md` to `CLAUDE.md`, then ran:

```
claude -p "Output only the value of the import probe token, nothing else. \
If you do not have it in your context, reply exactly: NOT_FOUND"
→ VYASA-IMPORT-PROBE-Z7QK9X-2026   (exit 0)
```

The fresh headless instance returned the token verbatim. Confounder ruled out: the SessionStart
hook only emits shards listed in the `## Default-load` section of `rules/INDEX.md`, and
`_import-probe.md` is **not** listed there — so the only path the token could have reached context
is the `@import` line. Therefore `@import` expands imported files into context at launch in this
version.

Cleanup done: import line removed from `CLAUDE.md`, `rules/_import-probe.md` deleted. The branch
carries only this plan and the `open.md` entry; no probe residue.

**Conclusion / next step:** `@import` is a viable, no-truncation load mechanism. The hook→import
migration is now unblocked but remains a **separate workitem with its own plan** (per the
plan-before-build gate). Open design question for that workitem: `@import` reintroduces the
list-duplication concern the hook plan raised (CLAUDE.md import lines + `rules/INDEX.md` prose
list) — decide whether to (a) keep both with a note, (b) generate one from the other, or
(c) let `INDEX.md` itself be the imported file.
