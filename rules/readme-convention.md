---
WHAT: Every directory carries a README.md; its shape follows the directory's role.
LOAD: Default — every session.
---

# README convention

## The rule

Every directory carries a `README.md` — one filename, everywhere. It is the file GitHub, IDEs,
and file browsers auto-render, so it is always the first thing a reader or tool looks for.
(`INDEX.md` is retired in favor of it.)

A README takes one of two shapes (plus a tie-breaker for the in-between case), by what its
directory holds:

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
