# vyasa — Project Rules

> Self-contained rulebook. Mirrors the universal hygiene from `~/.claude/CLAUDE.md`
> (as of 2026-05-24) so the project is portable. If the global file changes and
> vyasa benefits from the change, sync manually.

## Universal Hygiene (mirrors global)

### Honesty and Verification

1. **Never assert system state from documentation alone.** Before confirming any infrastructure is running (cron, LaunchAgent, service, CI, background process), verify with a tool call. Specs describe intent — not deployed reality.

2. **Aspirational ≠ Live.** "Runs automatically at X" in a doc is a spec. Verify with tools, not text.

3. **Acknowledge uncertainty rather than fabricate confidence.** If you cannot verify a claim this session, say "the doc says X, but I haven't checked actual state — let me verify" or "I don't know, let me check."

4. **No silent assumption propagation.** If a prior-session output or doc contains a claim you haven't verified this session, flag it as unverified rather than repeating it as established fact.

### Dummy-Level English Recap

5. **After any complicated multi-step response, end with a 3-line dummy-level English recap:**
   ```
   In dummy-level words:
   - What I did: <one sentence, no jargon>
   - Why it matters: <concrete benefit or risk closed>
   - What's next: <one concrete action, or "nothing — done">
   ```
   Skip only for: trivial one-liners, direct answers to simple questions, or when the user says "quiet mode". No file paths, no tool names, no jargon in the recap.

### Context Window Status

6. Surface context window state at phase boundaries — before subagent spawns, before multi-file write sequences, when the user asks. Format:
   ```
   Context: [Fresh | Mid-session | Late/compacted]
   Remaining: <one-line estimate>
   Call: continue here | new session — <one-sentence reason>
   ```

## Project-Specific Rules

### P1. No skill-based scaffolding — ever

vyasa exists to **measure the skill system**. Using `/new-project`, `/eklavya`, `/brahma`, `/vasudev`, or any other skill to scaffold vyasa is circular — the tool under measurement would be building the measurement tool. This rule is permanent, not first-session-only.

### P2. No harsh-brain wiring

This project does **not** integrate with the harsh-brain memory layer.
- No entry in `~/memories/repo/`
- No entry in `~/memories/session/` (other than the original handoff that started the project, which lives outside vyasa)
- No line in any `MEMORY.md`
- No symlink into harsh-brain
- No entry in `harsh-brain/sync.sh`

GitHub is the only durability layer. The project is an island.

### P3. Session-end lecture-style notes

At the end of any session where {a decision was made, a plan was formed, advice was given, something was built, something was learned, OR the user manually requested it} — **ask the user for permission** to write a session-notes file to `notes/<YYYY-MM-DD>-<topic>.md` in lecture/meeting-minutes style.

Never silent. If nothing on that trigger list happened, exit clean — no prompt.

### P4. Notes filename convention

`notes/YYYY-MM-DD-<topic-slug>.md`. Date in ISO format. Slug short, lowercase, hyphen-separated.

### P5. INDEX.md update

When a notes file lands, add a one-line entry to `notes/INDEX.md` at the top (newest-first), formatted:
```
- [YYYY-MM-DD-topic.md](YYYY-MM-DD-topic.md) — one-line topic
  Two-line brief about what was decided/built/learned.
```

### P6. No skill use during harness development

Same as P1, restated: vyasa's own runner code (when it gets written) must not be scaffolded via skills. Hand-roll it.

### P7. README as full project bible

`README.md` is the project bible. Every structural decision + its rationale lives there. If the project is wiped and recreated from `README.md` alone, the new copy should still know what it is, why it exists, what's inside, and why.

When a structural decision is made or changed in a session, update `README.md`'s decisions log in the same session.
