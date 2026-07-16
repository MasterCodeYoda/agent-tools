---
name: product:brief
description: Generate product content — one-pagers, pitch decks, README rewrites, comparison pages — from positioning research and codebase artifacts
argument-hint: "[format: readme|onepager|pitch|comparison|all] [--from positioning.md path]"
user-invocable: true
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

For each requested format, **load the template** and fill from positioning + verified codebase facts.
Constraints for each format stay with the template file (honest comparisons, verified install commands, etc.).

| Format | Template | Notes |
|--------|----------|-------|
| README | `templates/readme.md` | 30-second hero test; value-themed features |
| One-pager | `templates/one-pager.md` | Under ~400 words; live metrics |
| Pitch | `templates/pitch-narrative.md` | Slide narrative, research-sourced |
| Comparison | `templates/comparison.md` | Honest "choose them when"; cite competitor sources |

Apply @product messaging clarity hierarchy throughout.

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
