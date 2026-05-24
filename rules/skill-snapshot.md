---
WHAT: How to bring a skill under test in vyasa.
TRIGGER: User wants to compare two versions of a skill, or you are about to populate `skills/<name>/`.
LOAD: When the trigger above is met.
---

# Skill snapshot

When bringing a skill under test for comparison:

## 1. Copy, never symlink

The current version of the skill is **copied** into `skills/<name>/baseline/`. The candidate version is **copied** into `skills/<name>/candidate/`. Never symlink either to the live skill at `~/.claude/skills/<name>/`.

**Why:** Promotion-gate comparisons must be reproducible. If "baseline" is a symlink to the live skill, the moment the live skill mutates, yesterday's comparison can no longer be re-run identically. Snapshot = frozen bytes = reproducible.

## 2. Per-skill subdirectories

`skills/`, `fixtures/`, and `runs/` all use per-skill subdirectories:

- `skills/<name>/baseline/` and `skills/<name>/candidate/`
- `fixtures/<name>/`
- `runs/YYYY-MM-DD-HHMM-<name>-<variant>/`

Never flat.

**Why:** Multi-skill support — vyasa is intended to evaluate the whole stack (vasudev, narada, brahma, kaya, …), not one skill. A flat layout would collide as soon as a second skill arrives.

## 3. Variant naming: `baseline` / `candidate`

Not `v1`/`v2`, not `before`/`after`. The names carry the asymmetry: the candidate must prove itself **against** the baseline, not symmetric A/B testing.

If multi-candidate bake-offs appear later: `candidate-a`, `candidate-b`, etc.
