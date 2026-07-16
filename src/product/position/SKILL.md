---
name: product:position
description: Research-driven positioning exercise — competitive research, guided framework application, and positioning document generation
argument-hint: "['.', directory path, or 'continue']"
user-invocable: true
---

# Product Positioning

References: @product

Research-driven positioning exercise producing `./planning/positioning.md` (April Dunford framework + competitive research). **Not a template fill-in** — research first, then guided decisions.

## User Input

```text
$ARGUMENTS
```

## Input Detection

| Input Pattern | Scope | Action |
|---|---|---|
| `.` or empty | Current project | Full positioning from scratch |
| Directory path | Target project | Position that project |
| `continue` | Resume | Continue from `./planning/positioning.md` |
| `--from-audit` | Post-audit | Start from recent `/product:audit` report |

## Phase 1 — Discovery (research-first)

### 1a. Local Artifact Read

Read README hero, landing page, package metadata, existing `./planning/` positioning, docs intro.
Extract current claims: what / who / problem.

### 1b. Competitive Research (mandatory)

Spawn 3 parallel research agents:

- **direct-competitor-researcher** — 3–5 direct competitors; landing/pricing/GitHub/README; optional hero screenshot  
- **indirect-alternative-researcher** — what customers do with no product in category  
- **community-sentiment-researcher** — reviews, HN/Reddit/Dev.to/X; praise, complaints, unmet needs  

Return structured profiles with citations.

### 1c. Discovery Summary

Present findings using **`templates/discovery-summary.md`** (load and fill).

## Phase 2 — Positioning Exercise (guided, interactive)

For each Dunford step: present research evidence; user decides.

1. **Competitive Alternatives** — rank top 3 if product didn't exist  
2. **Unique Attributes** — 2–4 unique, verifiable, meaningful capabilities  
3. **Value Translation** — Feature → Capability → Benefit → Outcome per attribute  
4. **Target Customer** — role, org type, trigger, must/nice-haves  
5. **Market Category** — existing / sub / new with trade-offs  

## Phase 3 — Document Generation

Write `./planning/positioning.md` using **`templates/positioning-doc.md`** (load and fill from decisions + research sources + `last_research` date).

## Integration Points

- **`/product:audit`** — assess gaps then re-audit after positioning  
- **`/product:brief`** — content generation from positioning doc  
- **`/workflow:plan`** — feature gaps from claims vs codebase  
- **`/workflow:compound`** — capture competitive research findings  
