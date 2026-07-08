---
name: specs-go-in-planning
description: In agent-tools, design/spec docs go in planning/, never docs/superpowers/specs/
type: process
applicability: project
related: []
promoted_at: "2026-07-08T22:29:35Z"
source_harness: claude
---

In this repo, design specs and planning docs live under `planning/` (e.g. `planning/swarm/*-design.md`), **not** the superpowers brainstorming default `docs/superpowers/specs/`.

**Why:** Established `planning/` convention for this corpus; superpowers default paths are wrong here.

**How to apply:** When brainstorming/writing-plans skills say to write a spec to `docs/superpowers/specs/YYYY-MM-DD-*.md`, override and write to `planning/<area>/` using existing `*-design.md` / `implementation-plan-*.md` naming instead.
