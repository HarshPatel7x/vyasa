# Overview

> What vyasa is, why it exists, and where the name comes from. The substantial "why" of the
> project. For the layout and components see [structure.md](structure.md); for the design
> rationale of every structural call see [decisions.md](decisions.md).

## What it is

vyasa is a tool for comparing two versions of a Claude Code skill (a "baseline" and a "candidate") against the same set of fixture inputs, and measuring the behavioral deltas between them. It is the **measurement layer** that turns skill-version promotion from intuition into evidence.

Today's flow for promoting a skill (e.g., "did the compacted SKILL.md actually preserve behavior?"): hand-test a few cases, eyeball outputs, decide. vyasa formalizes that: same fixtures every time, captured outputs every time, comparable reports every time.

## Why it exists

This project operationalizes one of the user's standing rules:
> *Keep the legacy version during a rewrite. Don't scrap the working baseline until the replacement passes acceptance.*

Without measurement, "passes acceptance" is a feeling. With vyasa, it's a report. Specifically:
- The harsh-brain skill stack (eklavya, vasudev, narada, brahma, kaya, chitragupta, etc.) gets compacted, refactored, restructured periodically.
- Each compaction/refactor is a candidate version of the skill.
- Promoting the candidate without comparing it to the baseline on the same inputs has burned the user before.
- vyasa is the comparison gate.

## Why the name "vyasa"

In Hindu mythology, Vyasa is the sage who took the scattered, oral Vedic hymns — centuries of unorganized material — and **arranged them into the four Vedas**. The Sanskrit word "vyasa" literally translates to "arranger / compiler / divider."

The project's job description IS that translation: take messy raw skill outputs across two versions and arrange them into a structured comparable form. The name is self-documenting.
