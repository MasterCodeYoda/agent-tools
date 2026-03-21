---
name: product:brief
description: Generate product content — one-pagers, pitch decks, README rewrites, comparison pages — from positioning research and codebase artifacts
argument-hint: "[format: readme|onepager|pitch|comparison|all] [--from positioning.md path]"
---

# Product Brief Generator

References: @product

Generate polished product content from your positioning document and codebase. Every claim is grounded in positioning decisions backed by research, and every technical claim is verifiable from the codebase.

## User Input

```text
$ARGUMENTS
```

## Input Detection

| Input Pattern | Scope | Action |
|---|---|---|
| `readme` | README rewrite | Generate a positioning-aligned README |
| `onepager` | Product one-pager | Generate a one-page product summary |
| `pitch` | Pitch content | Generate pitch deck narrative and key slides content |
| `comparison` | Comparison page | Generate competitive comparison from research |
| `all` or empty | All formats | Generate all content types |
| `--from <path>` | Source | Use specified positioning doc (default: `./planning/positioning.md`) |

## Prerequisites

- **Positioning document** — Run `/product:position` first to create `./planning/positioning.md`. Brief generates content from positioning decisions; without them, it has nothing to ground in.
- If no positioning doc exists, offer to run `/product:position` first or proceed with a lightweight version using only codebase artifacts (with a warning that content will be weaker).

## Research Refresh

Before generating content, validate that positioning research is current:

1. Check the `last_research` date in the positioning document
2. If older than 30 days, spawn a **research-refresh agent**:
   - Re-check competitor landing pages for messaging changes
   - Re-check pricing pages for model changes
   - Search for new entrants in the category
   - Report: "Research is [N] days old. [Changes found / No significant changes]"
3. If significant changes found, recommend re-running `/product:position` before generating content

## Content Generation

### README Format

Generate a positioning-aligned README that follows the @product messaging clarity hierarchy:

```markdown
# [Product Name]

[One-line description — what it is, who it's for, why it matters]

[Visual demo — screenshot, GIF, or video link]

## Why [Product Name]?

[2-3 sentences translating unique attributes into value, using language validated by positioning exercise]

### vs. [Alternative 1]
[One sentence — specific, factual comparison grounded in research]

### vs. [Alternative 2]
[One sentence]

## Quick Start

[Copy-pasteable install + first-success commands — verified against actual codebase]

## Features

[Feature list organized by value themes from positioning, not by technical architecture]

## How It Works

[Brief architecture/approach for technical credibility — extracted from codebase]
```

Constraints:
- Hero section must pass the 30-second test (reader knows what/who/why)
- Every claim must trace to a positioning decision or codebase fact
- Install commands must be verified against actual package manager config
- Feature list organized by customer value, not internal modules
- No "coming soon" features unless explicitly marked

### One-Pager Format

Generate a single-page product summary suitable for stakeholders, investors, or enterprise buyers:

```markdown
# [Product Name] — [Category]

## The Problem
[2-3 sentences — the pain point, grounded in community research from positioning]

## The Solution
[2-3 sentences — what the product does, in outcome terms]

## Key Differentiators
1. [Differentiator] — [evidence from codebase + competitive gap from research]
2. [Differentiator] — [evidence]
3. [Differentiator] — [evidence]

## Target Customer
[From positioning: who, trigger event, must-haves]

## Traction / Social Proof
[GitHub stars, downloads, community size, notable users — verified live data]

## Competitive Landscape
[2x2 or positioning map showing where product sits vs. alternatives]

## Business Model
[From positioning research: pricing model, free tier, expansion path]
```

Constraints:
- Must fit conceptually on one page (under 400 words)
- Every number must be current (fetch latest GitHub stats, download counts)
- Traction section must use verified data, not claims from the README

### Pitch Content Format

Generate narrative content for pitch deck slides:

```markdown
# Pitch Narrative

## Slide 1: The Problem
**Hook**: [Opening question or statistic that frames the pain — sourced from research]
**Context**: [Why this problem matters now — market trend or catalyst]
**Evidence**: [Community quotes, search volume, or market data]

## Slide 2: Current Solutions Fall Short
**Alternative 1**: [What it does, where it fails — from competitive research]
**Alternative 2**: [What it does, where it fails]
**The gap**: [What no existing solution addresses well]

## Slide 3: Our Approach
**Insight**: [The non-obvious insight that makes this product possible]
**How it works**: [Simple explanation, not technical architecture]

## Slide 4: Key Differentiators
[From positioning: unique attributes translated to value]

## Slide 5: Traction
[Verified metrics: stars, downloads, community, growth rate]

## Slide 6: Market
[Category size, growth signals, comparable exits/raises in the space — researched]

## Slide 7: Ask
[What you want from the audience — investment, partnership, adoption]
```

### Comparison Format

Generate a competitive comparison page from research data:

```markdown
# [Product Name] vs. Alternatives

## Overview

| | [Product] | [Competitor 1] | [Competitor 2] | [Competitor 3] |
|---|---|---|---|---|
| **Best for** | [target customer] | [their target] | [their target] | [their target] |
| **Pricing** | [model] | [model] | [model] | [model] |
| **Open source** | [yes/no] | [yes/no] | [yes/no] | [yes/no] |
| **Key strength** | [from positioning] | [from research] | [from research] | [from research] |

## Detailed Comparison

### [Product] vs. [Competitor 1]
[Honest comparison — acknowledge their strengths, highlight genuine differences]
**Choose [Product] when**: [specific scenario where our product is better]
**Choose [Competitor 1] when**: [honest — when they're the better fit]

### [Product] vs. [Competitor 2]
[Same structure]

## Migration Guides
[If applicable — how to switch from each competitor]
```

Constraints:
- **Honest comparisons only.** Acknowledge competitor strengths. Users trust fair comparisons and distrust ones that claim superiority in everything.
- Every claim about a competitor must cite the source (their landing page, pricing page, docs)
- Include "choose them when" — this builds trust and helps readers self-select
- All competitor data must be current (fetched during this session, not from positioning doc cache)

## Output

Save generated content to `./planning/product-content/`:

```
planning/product-content/
  readme-draft.md
  one-pager.md
  pitch-narrative.md
  comparison.md
```

Present each generated document with a summary of sources used and confidence level.

## Integration Points

### With /product:position

Brief consumes the positioning document. Position decides what to say; brief decides how to say it. Always run position first.

### With /product:audit

After generating content and applying it to the project, run audit to verify the new content is consistent across all surfaces.

### With /workflow:execute

README and comparison page content can be applied to the project as implementation tasks via execute.
