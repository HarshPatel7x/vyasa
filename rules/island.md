---
WHAT: Identity guards — what vyasa is NOT.
LOAD: Default — every session.
---

# Island

vyasa is an **island**. It does not integrate with the harsh-brain memory layer, and it does not use skills to scaffold itself.

---

## No skill-based scaffolding — ever

vyasa exists to **measure** the skill system. Using `/new-project`, `/eklavya`, `/brahma`, `/vasudev`, or any other skill to scaffold vyasa is circular — the tool under measurement would be building the measurement tool.

This rule is permanent. It applies to the runner/harness code (`cli/`) when that eventually gets written: hand-rolled, not skill-scaffolded.

---

## No harsh-brain wiring

This project does **not** integrate with the harsh-brain memory layer.

- No entry in `~/memories/repo/`
- No entry in `~/memories/session/` (other than the original handoff that started the project, which lives outside vyasa)
- No line in any `MEMORY.md`
- No symlink into harsh-brain
- No entry in `harsh-brain/sync.sh`

GitHub is the only durability layer. The project can be moved, cloned, or shared without dragging the harsh-brain ecosystem along.

---

## README is the project bible

`README.md` is the project bible. Every structural decision and its rationale lives there. If the project is wiped and recreated from `README.md` alone, the new copy should still know what it is, why it exists, what's inside, and why.

When a structural decision is made or changed in a session, the README decisions log gets updated **in the same session**. See [readme-decisions-log.md](readme-decisions-log.md) for the trigger.
