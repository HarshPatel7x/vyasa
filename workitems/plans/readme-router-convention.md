# Plan — unify on README-as-router; retire INDEX.md; shard the root README into docs/

> Workitem: **Tweak `rules/readme-convention.md` rule** (from [`../open.md`](../open.md)), expanded
> in-session (2026-06-01) into a full convention change + the long-planned README sharding (executes,
> WITH MODIFICATIONS, the "Recipe for next session" inside `D13 — Shardable-domain pattern: folder +
> INDEX.md routing`).
> Status: DRAFT v3 — hardened through TWO critique/improve/audit review passes. Awaiting build
> sign-off. No branch cut yet.
> Branch when signed off: `workitem/readme-router-convention`.

---

## Problem

**(1) The README rule contradicts the layout.** `rules/readme-convention.md` says *every* directory
carries a `README.md`, yet `rules/`, `notes/`, `workitems/`, `workitems/plans/` carry an `INDEX.md`
and no README — standing violations flagged in `D17 — Workitems become a folder; open/done split;
plan-before-build gate` and in `.github/README.md`'s deferred note.

**(2) Two entry-doc filenames cost more than they buy.** The "worked-in-directly" criterion is fuzzy
(it mislabels `rules/`, which you edit constantly yet is INDEX-only); "one file, not both" outlaws the
README-with-an-index-section hybrid `.github/README.md` already uses; and **GitHub/IDEs auto-render
`README.md` but not `INDEX.md`**, so the four INDEX folders silently lose the affordance the README
rule exists to provide.

**Decisions (user, 2026-06-01):** (a) one entry-doc filename everywhere (`README.md`); retire
`INDEX.md`. (b) A README is thin: *what this is* + a *router*; substantial prose lives in shards.
(c) The Decisions log **moves to `docs/decisions.md`** — it is the only monotonically-growing section
(append-only, never deleted), so leaving it in the README re-creates the bloat the change exists to
prevent. The one-time hook re-point this needs is far cheaper than perpetual growth.

## The new convention (replaces the body of `rules/readme-convention.md`)

```markdown
## The rule

Every directory carries a `README.md` — one filename, everywhere. It is the file GitHub, IDEs,
and file browsers auto-render, so it is always the first thing a reader or tool looks for.
(`INDEX.md` is retired in favor of it.)

A README takes one of two shapes, by what its directory holds:

- **Routing directory** — holds other docs/shards (e.g. `rules/`, `docs/`). Its README is **thin**:
  one or two sentences of *what this directory is*, then a **router** — a list of, and links to, the
  contents. Substantial prose lives in the files it points to, never here. A signpost, never a
  destination.
- **Leaf directory** — holds artifacts, not sub-docs (e.g. `hooks/`, `.github/`). Its README **is**
  the documentation for those artifacts and carries narrative inline — there is nothing to route to.
- **Mixed directory (tie-breaker)** — holds both artifacts and sub-docs → it is **routing**: the
  README stays thin and routes to both. Per-artifact narrative lives in that artifact's nearest
  README, not the parent's. Rule of thumb: if a directory has any child that is itself documented,
  the parent routes.

## Anti-sprawl test (the "no dumpster" guard)

Before creating a new doc file, ask: *"would a reader ever open this file on its own?"* If no, it
belongs inside a sibling — cluster docs by topic, not by heading. A subdirectory whose contents are
trivial may be covered by its parent's README. An empty placeholder dir (only `.gitkeep`) needs no
README until it holds real content.

## The root README

The root `README.md` is a routing README: project identity (tagline + 2-sentence what-it-is) + a
router into the `docs/` tree that holds the substantial content. Anything append-only (the decisions
log) gets its own file under `docs/` so its growth never re-bloats the entry point.

## Scope

vyasa-only for now; written to generalize — "README everywhere, content shape follows the directory's
role" carries to any project unchanged. May lift to global once exercised here.
```

The leaf/routing/mixed trichotomy kills the fuzzy "worked-in-directly" criterion and resolves
`hooks/`/`.github/` *by rule* (leaf dirs → inline narrative).

## Final layout after the change

```
README.md            # THIN: tagline + 2-sentence what-it-is + router (link to docs/ + top-level dir list)
docs/
  README.md          # routing-dir README: what docs/ holds + links to the 3 shards
  overview.md        # "What it is" + "Why it exists" + "Why the name vyasa"   (identity cluster)
  structure.md       # "Project structure" tree (UPDATED) + "What each component is" + "How to use (future)"
  decisions.md       # full Decisions log D1..D22 + a trailing "## Provenance"; `### D<N>. ` headings PRESERVED
rules/README.md            # was rules/INDEX.md (router + the six @import lines)
notes/README.md            # was notes/INDEX.md
workitems/README.md        # was workitems/INDEX.md
workitems/plans/README.md  # was workitems/plans/INDEX.md
hooks/README.md      # leaf — narrative kept; stale "README blob" seam prose repointed
.github/README.md    # leaf — narrative kept; stale "README blob" seam prose + convention note repointed
```

`docs/` = 3 content files + 1 router. `name`, `provenance`, `how-to-use` each fail the "open it
alone?" test, so they fold in (`name` → overview; `how-to-use` → structure; `provenance` →
decisions.md, since it is itself historical-record material).

## Precise, file-by-file changes

### A. `hooks/commit-msg` — re-point the Touches check (the load-bearing edit)

The hook has **7 functional `README.md` references** (NOT 3): the blob helper (line 28), the
changed-file gate (line 112), the heading grep (line 120), and four failure-message strings (lines
113, 122, 125, 127) — plus comment references (lines 11, 13, 26). All must move to `docs/decisions.md`:

- Add `DECISIONS_FILE="docs/decisions.md"` after the `COMMIT_REF` block.
- Rename `readme_blob()` → `decisions_blob()` (its body changes meaning); body:
  `git show "${COMMIT_REF}${DECISIONS_FILE}" 2>/dev/null`. Update its one call site (line 120).
- **Keep `readme_changed()` as-is** (it lists *all* changed files; renaming it is cosmetic churn in
  the safety-critical file — skip it). Change only its line-112 use: `grep -qx "$DECISIONS_FILE"`.
- Update the four failure messages (113/122/125/127): `README.md` → `docs/decisions.md`.
- Update the COMMIT_REF seam comments (11, 13, 26): "the staged README" → "`docs/decisions.md`".

Verified safe: `git show "${COMMIT_REF}docs/decisions.md"` resolves for both `COMMIT_REF=":"` (local
index) and `"<sha>:"` (CI tree); the path has no spaces/globs so existing quoting suffices.

**GOTCHA — heading format is load-bearing.** The hook greps `^### D${d_num}\. ` (three hashes, space,
`D`, number, period, space). `docs/decisions.md` MUST keep every decision as `### D<N>. <title>`
verbatim — no heading-level promotion.

### B. `.github/scripts/pr-format-check.sh` — comments only

No logic change. Update the comments at lines 7–8 and 14–16 ("resolves README from each commit's
tree") → "resolves `docs/decisions.md`". The `COMMIT_REF` seam already resolves any path.

### C. `rules/git-workflow.md` — spec moves with enforcement (same commit family)

Four spots reference README-as-decisions-home:
- Line 46 — the `Touches:` footer description "`<title verbatim from README>`" AND the sentence "the
  hook verifies that `README.md` is in the commit AND … the staged `README.md`" → `docs/decisions.md`.
- Line 75 — PR-body template "`D<N> — title-verbatim-from-README`" → "from `docs/decisions.md`".
- Line 93 — enforcement-table row "(README staged + title match)" → "(docs/decisions.md staged …)".
- Line 110 — "Append a D-entry to `README.md` if the change is structural" → "to `docs/decisions.md`".

### D. `rules/readme-decisions-log.md` — where future decisions are appended (critical)

This triggered shard tells future sessions where the log lives — if stale, future decisions go to the
wrong file and the hook rejects them. Update the operational instructions: "Decisions log section in
`README.md`" / "Append to the bottom of the Decisions log section in `README.md`" → `docs/decisions.md`
(lines 9, 26), and the bible framing (line 9). **Keep the shard filename** `readme-decisions-log.md`
(it is referenced by name in the rules router; renaming is churn) but update the `# README decisions
log` heading + `WHAT:` frontmatter wording to be location-accurate ("the decisions log in
`docs/decisions.md`").

### E. `rules/island.md` — amend the "bible" principle (line 36, 38)

- "`README.md` is the project bible" → "the `README.md` + `docs/` tree is the project bible".
- "Every structural decision and its rationale lives there" → "lives in `docs/decisions.md`".
- "recreated from `README.md` alone" → "from the `README.md` + `docs/` tree".
- Update the decisions-log pointer (line 38).

### F. `CLAUDE.md` — @import pointer + Convention section

- Line 5 prose link, line 9 (×2 occurrences), line 12 `@import`: `rules/INDEX.md` → `rules/README.md`.
- Lines 18–24 "Convention" section: rewrite "folder-per-domain + `INDEX.md`" → "+ `README.md` router";
  "create an `INDEX.md`" → "create a `README.md` router"; "point at the relevant `INDEX.md`" → "…
  `README.md`"; "future `docs/`" → `docs/` now exists; "See README decision **D13**" → cite `D22`.

### G. Shard the root `README.md` into `docs/`

- **`docs/overview.md`** ← `## What it is` + `## Why it exists` + `## Why the name "vyasa"` (verbatim;
  fix internal links — `rules/…` becomes `../rules/…` one level deeper).
- **`docs/structure.md`** ← `## Project structure` (the tree, **UPDATED** to the new layout:
  `rules/README.md` not `INDEX.md`; add `docs/`; root README = thin entry, not "bible + decisions
  log") + `## What each component is, and why` (the ~70-line block, lines 98–122) + `## How to use
  vyasa (future state)`.
- **`docs/decisions.md`** ← `## Decisions log` (D1..D21) + a trailing `## Provenance` (the old
  `## Provenance` section). **Pure verbatim relocate — do NOT reorder** (see O1). `### D<N>. ` headings
  preserved byte-for-byte. D22 added in step I.
- **`docs/README.md`** ← new routing-dir README: one line on what `docs/` is + links to the 3 shards.
- **Root `README.md`** ← trimmed to tagline + 2-sentence what-it-is + a router: link to
  `docs/README.md` + a compact top-level dir list (name + one-line purpose + where documented). The
  list is a *router*, NOT a duplicate of `docs/structure.md`'s full tree — keep it one line per dir or
  it re-grows into the thing we are shrinking.

### H. Retire `INDEX.md` → `README.md` (4 renames)

`git mv` each: `rules/INDEX.md`, `notes/INDEX.md`, `workitems/INDEX.md`, `workitems/plans/INDEX.md` →
`README.md` in place (no collisions — only root/`​.github`/`hooks` have READMEs today). Then fix LIVE
references:
- **Self-references** inside each renamed file.
- **Live links** in: `rules/workitems.md` (links to `../workitems/INDEX.md`,
  `../workitems/plans/INDEX.md`), `rules/session-end-notes.md`, `workitems/open.md` (the ONE
  `plans/INDEX.md` link at line 4), and the renamed routers' own cross-links → `plans/README.md` etc.
- **DO NOT** repoint `workitems/done.md` — it has **zero** live INDEX.md links; its INDEX mentions are
  frozen historical prose in past done-entries (leave them).
- **DO NOT** "fix" historical prose: `rules/voice.md` line 63's `D13 — … folder + INDEX.md routing`
  (an accurate historical D-title example), `notes/README.md`'s body index-entry descriptions, and
  `notes/*.md` / closed `workitems/plans/*.md` bodies all keep their `INDEX.md` strings per
  `rules/voice.md`'s no-retroactive-edit rule.

### I. Log `D22` + annotate superseded entries (in `docs/decisions.md`)

- Append `### D22. README-as-router: retire INDEX.md, shard root README into docs/` capturing: the
  leaf/routing/mixed convention, the three weaknesses fixed (incl. INDEX auto-render loss), the
  decisions-log move + hook re-point, and the island.md amendment.
- Annotate (do NOT delete): `D13` recipe — `*(Executed WITH MODIFICATIONS by D22 — …: README.md
  routers, single docs/decisions.md.)*`; `D15` clause 3 — `*(Scoped by D22 — …)*`; `D17` tension note
  — `*(Resolved by D22 — …)*`; `D11` — `*(INDEX.md router renamed to README.md by D22 — …)*`.
- Commit carries `Touches: D22 — README-as-router: retire INDEX.md, shard root README into docs/`,
  stages `docs/decisions.md`. **Footer title and `### D22.` heading title must be byte-identical.**

### J. `hooks/README.md` + `.github/README.md` — stale enforcement-location prose

These describe where enforcement reads from; a grep-for-`INDEX.md` sweep will NOT catch them:
- `hooks/README.md`: lines 15 + 17 describe "`### D<N>.` heading … staged `README.md`" / "`git show
  :README.md` (the README blob)" → repoint to `docs/decisions.md`; also its "README decision D19/D20"
  references → "decision D19/D20 (`docs/decisions.md`)"; and its 3 live `INDEX.md` strings.
- `.github/README.md`: lines 32–33 + 42–43 ("resolves `README.md` from each commit's tree") → repoint
  to `docs/decisions.md`; AND rewrite the "Note on the README convention" prose (lines 46–54), which
  describes the *old* resolution as settled fact, to past tense citing `D22 — …`.

### K. `workitems/open.md` → `workitems/done.md`

Repoint open.md's one `plans/INDEX.md` link (line 4) before moving. Move this workitem to `done.md`
with honest history: "Originally scoped (2026-05-28) to keep `INDEX.md` for sharded subdomains;
reversed in-session 2026-06-01 to README-everywhere (Option A) after the GitHub-auto-render finding —
see plan." Link the plan.

## Commit sequence + chicken-and-egg choreography

One branch, one PR. **Squash-merge (`D21`) collapses all commits into one mainline commit (the PR
title)** — the per-commit structure is for PR reviewability and to satisfy the per-commit CI check
(which validates each commit against its own tree using the PR-head, already-re-pointed hook).

**Commit scopes must be in the whitelist** (`rules|notes|readme|workitems|hooks|cli|skills|fixtures|
runs|reports`). There is no `repo` or `docs` scope (`docs` is a *type*; `readme` is the scope for
`docs/` files). Cross-cutting commits omit the scope.

1a. **`refactor: relocate decisions log to docs/decisions.md and re-point Touches enforcement`** —
   change A (hook) + B (CI comments) + create `docs/decisions.md` (verbatim, provenance appended). The
   atomic, hook-testable unit: after it, the log lives in docs/ and the hook reads it. **No `Touches:`
   footer.**
1b. **`docs(rules): repoint decisions-location spec and bible references`** — changes C + D + E.
2. **`docs(readme): shard descriptive sections into docs/ and thin the root README`** — change G +
   the F edits that describe the bible/structure. No footer.
3. **`refactor: retire INDEX.md in favor of README.md`** — change H (4 `git mv` + ref fixes) + the F
   `@import`/Convention-section edits. Mechanical. No footer. **Run the fresh-session launch-load probe
   AFTER this commit.**
4. **`docs(rules): rewrite readme-convention to leaf-vs-routing rule`** — change to
   `rules/readme-convention.md`. No footer.
5. **`docs(readme): log D22 and annotate superseded decisions`** — change I + J. **Carries
   `Touches: D22 — …`**; stages `docs/decisions.md`. Any other `D<N>` in this commit *message* must be
   inline-expanded `D<N> — title` (hook lines 91–106).
6. **`docs(workitems): close readme-router workitem`** — change K. No footer.

**No-footer legitimacy (stated, not assumed):** commits 1a–4 and 6 relocate/rename structural material
without a `Touches:` footer. This is accepted: the `D22` entry that records the whole change is logged
in commit 5 of the *same PR*, and the hook only enforces `Touches:` when the footer is present.
Structural-relocation commits legitimately ship footerless when the D-entry lands elsewhere in the
same PR. Do NOT bolt a footer onto an earlier commit — it would break the choreography (the footer
requires the `### D22.` heading to already exist in that commit's `docs/decisions.md`).

## Gotchas catalogue

1. **`### D<N>. ` heading format is load-bearing** — preserve verbatim in `docs/decisions.md`.
2. **Chicken-and-egg** — `Touches: D22` validates only after 1a re-points the hook AND `docs/
   decisions.md` (with `### D22.`) is staged; hence D22 is commit 5, re-point is commit 1a.
3. **Footer/heading title byte-identical** — exact string compare.
4. **`### D22.` won't reach `main`** — squash keeps only the PR title; `Touches:` trailers are not
   carried (`D21`). Local hook + CI still validate pre-merge — that's the point.
5. **No hot-reload** — the `@import` rename is verifiable only in a *fresh* session (`D18`/`D19`).
6. **`git grep INDEX.md` will NOT return zero** — many mentions live in frozen historical prose
   (`notes/*.md`, closed `plans/*.md`, `done.md` entries, `notes/README.md` index entries, `voice.md`
   line 63). Verification checks files *named* INDEX.md and live *links*, not raw string count.
7. **`.github/README.md` + `hooks/README.md` have no/few `INDEX.md` strings** but carry stale
   "README blob" enforcement prose — needs manual repoint (change J), not a grep sweep.
8. **`docs/structure.md` tree is NOT a verbatim move** — update it to the new layout.
9. **Two README sections collapse into `structure.md`** — `## Project structure` AND `## What each
   component is, and why` (don't drop the 70-line block).
10. **Relative links shift** — content moving into `docs/` is one level deeper (`rules/` → `../rules/`).
11. **`rules/README.md` must keep its six `@import` lines** — it's both human router and machine-load
    target; trimming below the imports breaks launch-load.
12. **D-code inline-expansion in commit *messages*** — any `D<N>` followed by ` — <title>` (em-dash).
13. **Commit scopes are whitelisted** — no `repo`/`docs` scope; omit scope for cross-cutting commits.

## Verification

- **No INDEX.md files remain:** `git ls-files | grep -iE '(^|/)INDEX\.md$'` → empty.
- **Every non-placeholder dir has a README:** root, `docs/`, `rules/`, `notes/`, `workitems/`,
  `workitems/plans/`, `hooks/`, `.github/`. Placeholders exempt: `fixtures/`, `runs/`, `skills/`,
  `reports/`, `reports/decisions/` (the five dirs that hold only `.gitkeep`). `cli/` is exempt because
  it does not exist on disk yet (not a `.gitkeep` placeholder).
- **No broken live link:** in the LIVE-LINK set (`CLAUDE.md`, `rules/*.md`, root `README.md`, `docs/**`,
  `hooks/README.md`, `.github/README.md`, `workitems/open.md`, `workitems/README.md`,
  `workitems/plans/README.md`), no Markdown link targets an `INDEX.md` and none links into a moved
  `README.md` section. Frozen historical prose (`done.md` entries, `notes/README.md` index entries,
  `notes/*.md`, closed `plans/*.md`, `voice.md` line 63) is EXCLUDED — its `INDEX.md` strings stay.
- **Hook green (tested directly):** with the re-pointed hook — (a) `Touches: D22 — <title>` + matching
  `### D22.` in staged `docs/decisions.md` PASSES; (b) mismatched title FAILS; (c) `Touches:` footer
  with `docs/decisions.md` NOT staged FAILS; (d) CI seam: `COMMIT_REF=<sha>:` resolves `git show
  "<sha>:docs/decisions.md"`. Drive with hand-made inputs + exit-code assertions.
- **Decisions log integrity:** `docs/decisions.md` holds D1..D22; diff the extracted text against the
  old `README.md` section — the ONLY deltas are D22 + the four annotations + the appended Provenance
  (no reorder, so the diff is otherwise empty → nothing lost).
- **Launch-load (DEFERRED to next fresh session):** confirm the six rule shards still reach context via
  `CLAUDE.md → @rules/README.md → shards` (re-run the `D18` probe). Cannot self-verify mid-session.
- **GitHub render (after push):** formerly-INDEX folders + `docs/` now auto-render their README.

## Resolved review questions

- **O1 — reorder D15/D16?** NO. Pure verbatim relocate keeps the integrity diff clean and auditable.
  If numeric order is wanted, do it as a separate trivial follow-up workitem (logged, not bundled).
- **O2 — `hooks/`/`.github/` leaf READMEs:** keep narrative inline per the leaf-dir rule (no
  re-sharding); the trichotomy makes this unambiguous.
- **O3 — root README dir-list:** compact (name + one-line + where-documented), not a duplicate tree.
