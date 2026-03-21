---
name: product:position
description: Research-driven positioning exercise — competitive research, guided framework application, and positioning document generation
argument-hint: "['.', directory path, or 'continue']"
---

# Product Positioning

References: @product

A guided, research-driven positioning exercise that produces a positioning document. Uses the April Dunford "Obviously Awesome" framework as the primary structure, enriched with extensive competitive research.

**This is not a template fill-in.** The agent conducts primary research into competitors, market context, and comparable successes before guiding you through positioning decisions.

## User Input

```text
$ARGUMENTS
```

## Input Detection

| Input Pattern | Scope | Action |
|---|---|---|
| `.` or empty | Current project | Full positioning exercise from scratch |
| Directory path | Target project | Position the specified project |
| `continue` | Resume | Continue from existing `./planning/positioning.md` |
| `--from-audit` | Post-audit | Start from a recent `/product:audit` report |

## Phase 1 — Discovery (research-first)

### 1a. Local Artifact Read

Read the project's current positioning surface:
- README (hero section, tagline, description)
- Landing page (if exists)
- Package metadata (description, keywords)
- Existing positioning docs (if any in `./planning/`)
- Docs introduction page

Extract: What does the product currently claim to be? Who does it currently claim to serve? What problem does it currently claim to solve?

### 1b. Competitive Research (mandatory)

Spawn 3 parallel research agents:

**direct-competitor-researcher**:
1. From the product's description and category, identify the problem space
2. Web search: "[problem space] tools [current year]", "[product category] alternatives", "best [product category]"
3. Identify 3-5 direct competitors (products that solve the same problem for the same audience)
4. For each competitor:
   - Fetch and read their landing page — extract: hero message, value prop, CTA, key claims
   - Fetch and read their pricing page — extract: model, tiers, free tier boundaries
   - Check their GitHub (if open source) via `gh`: stars, last release, contributor count, issue velocity
   - Read their README: positioning, quickstart, feature highlights
   - Screenshot their landing page hero section (via Chrome DevTools MCP) for visual comparison
5. Return: structured competitor profiles with positioning analysis

**indirect-alternative-researcher**:
1. Identify what customers would do if NO product in this category existed
   - Manual processes, spreadsheets, hiring, building in-house, using a general-purpose tool
2. Web search for evidence of these alternatives being used: "[problem] without [category]", "[problem] manually", "[problem] spreadsheet"
3. Identify 2-3 indirect alternatives and their trade-offs
4. Return: alternative landscape with why-not-just-X analysis

**community-sentiment-researcher**:
1. Search for discussions about the product and its competitors:
   - Web search: "[product name] review", "[product name] vs", "[product name] experience"
   - Search Hacker News, Reddit, Dev.to, X/Twitter for mentions
2. Search for category discussions:
   - "[product category] comparison [current year]"
   - "[product category] recommendations"
3. Extract: What do users praise? What do they complain about? What do they wish existed?
4. Return: community sentiment summary with source citations

### 1c. Discovery Summary

Present findings to the user:

```markdown
## Discovery Summary

### Current Positioning
- **What you claim**: [extracted from artifacts]
- **Who you target**: [extracted or implied]
- **Problem you address**: [extracted]

### Competitive Landscape
| Competitor | Hero Message | Key Differentiator | Pricing | Strength | Weakness |
|-----------|-------------|-------------------|---------|----------|----------|
| [name] | [message] | [diff] | [model] | [strength] | [weakness] |

### Indirect Alternatives
- [Alternative 1]: [why people use it, what it costs in time/effort]
- [Alternative 2]: ...

### Community Sentiment
- **What users praise in this category**: [themes]
- **What users complain about**: [themes]
- **Unmet needs**: [gaps no product fills well]

### Key Insight
[One-sentence synthesis of the most important finding from research]
```

## Phase 2 — Positioning Exercise (guided, interactive)

Work through the Dunford framework with the user. For each component, present the research evidence and ask the user to make a decision.

### Step 1: Competitive Alternatives

**Question**: "If your product didn't exist, what would your best-fit customers use instead?"

Present research-informed options:
- Direct competitors found in research
- Indirect alternatives (manual process, spreadsheets, building in-house)
- "Do nothing" / live with the problem

Ask the user to rank the top 3 alternatives. These anchor the rest of the exercise.

### Step 2: Unique Attributes

**Question**: "What capabilities do you have that your top alternatives don't?"

Present:
- Technical capabilities visible in the codebase (architecture, features, integrations)
- Claims from the current README/landing page
- Gaps in competitors found during research

For each proposed attribute, validate:
- Is it actually unique? (Did research show a competitor with the same capability?)
- Is it verifiable from the codebase? (Not aspirational — actually built)
- Is it meaningful to customers? (Not a technical detail only developers care about)

Ask the user to select 2-4 truly unique, defensible attributes.

### Step 3: Value Translation

**Question**: "What does each unique attribute enable for the customer?"

For each selected attribute, translate:
- **Feature** → **Capability** → **Benefit** → **Outcome**
- Example: "WASM sandbox" → "run untrusted code safely" → "no security review needed" → "ship integrations 10x faster"

Use research context: How do competitors describe similar value? What language resonates in community discussions?

### Step 4: Target Customer

**Question**: "Who cares most about this value? What are their characteristics?"

Present research-informed segments:
- Who's talking about this problem in community discussions?
- Who are the competitors targeting? (extracted from their landing pages)
- What adjacent audiences exist that competitors aren't serving?

Ask the user to define their best-fit customer with specifics:
- Role/title (not just "developers" — what kind?)
- Organization type (startup, enterprise, agency, individual?)
- Trigger event (what makes them start looking for a solution?)
- Must-have vs. nice-to-have criteria

### Step 5: Market Category

**Question**: "What market category makes your value obvious to your target customer?"

Present options with trade-offs:
- **Existing category** (e.g., "API gateway") — instant comprehension but direct comparison to incumbents
- **Sub-category** (e.g., "AI-native API gateway") — narrower but sets different expectations
- **New category** (e.g., "API intelligence platform") — maximum differentiation but requires education

Use research: What category do competitors claim? What category terms appear in community discussions? What do prospects search for?

## Phase 3 — Document Generation

Based on the positioning decisions, generate `./planning/positioning.md`:

```markdown
---
title: Product Positioning
created: [date]
framework: April Dunford - Obviously Awesome
last_research: [date]
competitors_researched: [list]
---

# [Product Name] Positioning

## Positioning Statement

For [target customer] who [trigger/need], [product name] is a [market category] that [key value]. Unlike [primary alternative], [product name] [key differentiator].

## Competitive Alternatives

| Alternative | Type | What They Offer | Where They Fall Short |
|-------------|------|----------------|----------------------|
| [name] | Direct competitor | [offering] | [gap our product fills] |
| [name] | Indirect alternative | [offering] | [gap our product fills] |

## Unique Attributes

| Attribute | Why It's Unique | Evidence |
|-----------|----------------|----------|
| [attribute] | [competitor comparison] | [codebase reference] |

## Value Translation

| Attribute | Capability | Benefit | Outcome |
|-----------|-----------|---------|---------|
| [attr] | [capability] | [benefit] | [outcome] |

## Target Customer

- **Who**: [specific description]
- **Trigger**: [what makes them look for a solution]
- **Must-haves**: [non-negotiable criteria]
- **Nice-to-haves**: [preference criteria]

## Market Category

- **Category**: [chosen category]
- **Rationale**: [why this category, based on research]
- **Category expectations**: [what prospects expect from this category]
- **How we exceed expectations**: [where we over-deliver]

## Messaging Implications

### Hero Message (30-second version)
[Draft hero message based on positioning decisions]

### Elevator Pitch (2-minute version)
[Draft pitch incorporating all positioning components]

### Key Claims (with evidence)
1. [Claim] — [evidence from codebase or benchmarks]
2. [Claim] — [evidence]
3. [Claim] — [evidence]

## Research Sources

- [Competitor 1 landing page URL — accessed date]
- [Competitor 2 pricing page URL — accessed date]
- [Community discussion URL — key insight]
- [Market analysis URL — relevant finding]

## Next Steps

- [ ] Review positioning with team
- [ ] Update README hero section to match positioning statement
- [ ] Update landing page messaging
- [ ] Run `/product:brief` to generate formatted product content
- [ ] Run `/product:audit` to validate positioning implementation
```

## Integration Points

### With /product:audit

Audit assesses current positioning quality. Position helps fix it. Run audit first to identify gaps, then position to address them. After positioning, re-audit to verify the new positioning is properly implemented across surfaces.

### With /product:brief

Brief generates formatted content (one-pagers, pitch decks, README rewrites) from the positioning document. Position decides what to say; brief decides how to say it.

### With /workflow:plan

Positioning decisions may reveal feature gaps ("we claim X but haven't built it yet"). Feed these into planning as requirements.

### With /workflow:compound

Document competitive research findings via compound for future reference. Market landscapes change — dated research is still valuable context.
