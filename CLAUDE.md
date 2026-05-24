# vyasa — project entry point

> Thin entry. The actual project rules live as shards under `rules/`.

**Before doing anything else in this project, read [`rules/INDEX.md`](rules/INDEX.md) and follow it.**
That file lists which shards to load by default and which to load on specific triggers.

---

## Convention (the one rule that lives here, not in a shard)

This project uses a uniform **folder-per-domain + `INDEX.md`** routing pattern:

- Every shardable domain lives in its own folder (`rules/`, `notes/`, future `docs/`).
- That folder contains an `INDEX.md` that acts as the router — listing which shards to load when.
- Top-level files (this one, `README.md`) stay thin and point at the relevant `INDEX.md`.

When a new domain wants to be sharded (e.g., when `README.md` itself gets split into smaller files), apply the same pattern: create the folder, create an `INDEX.md`, move content into named shards. See README decision **D13** for the recipe.
