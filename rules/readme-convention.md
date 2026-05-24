---
WHAT: Every directory or project under this tree carries a README.md.
LOAD: Default — every session.
---

# README convention

## The rule

Every directory or project — whether it contains code or not — carries a `README.md` at its root. The file is the discoverability hub: it explains what lives in that directory, why, and how to use it. New directory created in this project? Create its README in the same session.

## Why

README files have affordances that plain folders don't:

- They render automatically in GitHub, IDEs, and most file browsers.
- They are the conventional entry point — readers look for them first.
- They keep per-directory context co-located with the directory itself instead of being scattered across project-level docs.

Skipping the README pushes that context elsewhere, where it gets lost or forgotten.

## Minimum content

A README does not need to be long. The minimum:

1. **What this directory is** — one or two sentences.
2. **What lives here** — a brief inventory if non-obvious from filenames.
3. **How to use / contribute / extend** — only if the directory has a usage pattern.

If a directory is truly trivial (e.g., a single-file utility folder), a one-line README is fine — but the file must exist.

## Scope of this rule

This rule applies to **vyasa only** for now. It may be lifted to global in a future pass once the convention has been exercised here.
