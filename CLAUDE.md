# vyasa — project entry point

> Thin entry. The actual project rules live as shards under `rules/`.

**Before doing anything else in this project, read [`rules/README.md`](rules/README.md) and follow it.**
That file lists which shards to load by default and which to load on specific triggers.

The default-load shards are pulled into context automatically by the import below
(`CLAUDE.md` → `rules/README.md` → the six shards). `rules/README.md` stays the single
source of truth for *which* shards load; this line is just the mechanism that loads them.

@rules/README.md

---

## Convention (the one rule that lives here, not in a shard)

This project uses a uniform **folder-per-domain + `README.md` router** pattern:

- Every shardable domain lives in its own folder (`rules/`, `notes/`, `docs/`).
- That folder contains a `README.md` that acts as the router — a thin signpost listing which shards to load when.
- Top-level files (this one) stay thin and point at the relevant `README.md` router.

When a new domain wants to be sharded, apply the same pattern: create the folder, create a `README.md` router, and move the substantial content into named shards beside it. The root `README.md` itself was sharded this way into `docs/`. See decision **D22 — README-as-router: retire INDEX.md, shard root README into docs/** in `docs/decisions.md` for the recipe.
