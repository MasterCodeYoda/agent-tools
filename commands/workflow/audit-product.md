---
name: workflow:audit-product
description: Audit product-market fit, positioning, messaging, go-to-market readiness, and competitive stance from readable artifacts
argument-hint: "['.', directory path, or '--focus positioning|messaging|gtm|devex']"
---

# Product & Market Audit

Examine product artifacts — landing pages, README, docs, configs, onboarding flows, pricing pages, metadata — for value proposition clarity, messaging consistency, positioning strength, go-to-market readiness, and trust signals. Produce prioritized, actionable findings.

## User Input

```text
$ARGUMENTS
```

## Input Detection

Parse input to determine audit scope:

| Input Pattern | Scope | Action |
|---|---|---|
| `.` or empty | Current project | Full product audit across all readable artifacts |
| Directory path | Target project | Audit the specified project |
| `--focus positioning` | Positioning only | Value proposition, differentiation, competitive stance |
| `--focus messaging` | Messaging only | Cross-surface consistency, tone, clarity |
| `--focus gtm` | GTM readiness | Pricing, onboarding, self-serve vs. sales-led signals |
| `--focus devex` | Developer experience | SDK, quickstart, time-to-value (developer-facing products) |
| `--recent 7d` | Recent changes | Audit product-facing files modified in last N days |
| `--diff main` | Changed files | Audit product-facing files changed vs. specified branch |

## Auto-Detection Phase

Before analysis, detect the project's product surface:

```
1. Detect product type (library/SDK, SaaS, CLI tool, framework, API service, desktop/mobile app)
2. Detect audience signals (developer-facing, business-facing, consumer-facing, mixed)
3. Detect landing page / marketing site (index.html, landing page templates, marketing directory)
4. Detect README quality and positioning content (tagline, value prop, comparison tables)
5. Detect onboarding artifacts (quickstart, getting-started, tutorials, examples directory)
6. Detect pricing/plan information (pricing page, plan configs, feature gating)
7. Detect metadata and SEO (package.json description, meta tags, Open Graph, manifest)
8. Detect trust signals (security policy, compliance docs, changelog, testimonials, logos)
9. Detect competitive positioning artifacts (comparison docs, migration guides, "why us" pages)
10. Detect developer experience artifacts (SDK, API reference, playground, sample apps)
```

## Scope Gate

Based on auto-detection, determine audit scope:

- **Small** (< 20 product-facing files): Run all tiers automatically
- **Medium** (20-80 product-facing files): Run Tier 1 on all; prompt before Tier 2/3
- **Large** (80+ product-facing files): Require explicit scoping or run Tier 1 sampling

## Agent Reasoning Standards

All audit agents must follow these reasoning principles:

- **Cite evidence.** Every finding must reference specific file paths and line numbers (or section anchors for docs). No finding without a concrete citation.
- **Check the opposite hypothesis.** Before reporting a P1 or P2 finding, briefly consider: "Could this be intentional?" Look for documented positioning decisions, deliberate audience narrowing, or strategic omissions. If found, downgrade or retract.
- **Product-Strategy Trace.** Connect each finding to at least one impact category: conversion impact (will prospects bounce?), trust impact (does this erode credibility?), adoption impact (does this slow time-to-value?), retention signal (does this hurt stickiness?), or competitive impact (does this weaken differentiation?). If a finding has no clear impact connection, demote to P3 or retract.

## Three-Tier Analysis

### Tier 1 — Artifact Surface Read (always runs)

Spawn 3 parallel agents that read product-facing artifacts:

**value-proposition-analyst**:
- Can a prospect understand what the product does in 30 seconds from the README or landing page?
- Is the tagline/headline specific and differentiated (not generic "fast, simple, powerful")?
- Does the value proposition name a specific pain point and audience?
- Is the primary CTA clear and compelling?
- Does the hero section answer: What is it? Who is it for? Why should I care?
- Are benefits stated (outcomes) vs. only features listed (capabilities)?
- Does metadata (package.json description, meta tags, Open Graph) align with the stated value prop?
- Is the project name memorable, searchable, and unambiguous?

**messaging-consistency-auditor**:
- Cross-reference messaging across all text surfaces: README, landing page, docs, package metadata, CLI help text, error messages, onboarding copy
- Flag contradictions in product description across surfaces
- Flag audience mismatches (e.g., README says "for developers" but landing page targets business users)
- Check tone consistency (formal vs. casual, technical vs. accessible)
- Verify terminology consistency (same concepts use same words everywhere)
- Check that feature lists across surfaces are synchronized (no orphaned claims)

**product-completeness-scanner**:
- Does the product appear production-ready or prototype? (versioning, changelog, stability indicators)
- Are there "coming soon" or placeholder features visible to prospects?
- Is error handling user-friendly or does it leak internals?
- Do configuration defaults suggest production use or development hacks?
- Are there trust signals present? (security policy, compliance mentions, SLA, uptime, social proof)
- Is the license clearly stated and appropriate for the audience?
- Does the project have operational maturity indicators? (monitoring, logging, health checks)

### Tier 2 — Deep Artifact Analysis (runs if sufficient artifacts detected)

Spawn 3 parallel agents:

**developer-experience-auditor** (runs if developer-facing product detected):
- Trace the zero-to-value path: install → configure → first success — how many steps?
- Is the quickstart copy-pasteable and does it produce a visible result?
- Are prerequisites stated upfront (runtime versions, dependencies, accounts)?
- Is API reference complete and does it include examples for each endpoint/method?
- Are error messages actionable (tell user what to do, not just what went wrong)?
- Is there a playground, REPL, or interactive demo?
- Time-to-value estimate: how long from `npm install` / `pip install` to meaningful output?
- Does the SDK follow conventions of its ecosystem (naming, structure, error handling)?

**competitive-positioning-analyst**:
- Are there explicit comparison docs or "vs." pages? Are claims specific and verifiable?
- Does the architecture reveal defensible moats? (unique data, network effects, integration depth)
- Are migration guides available from competitors?
- Does the feature set suggest a clear category or is positioning ambiguous?
- Is there a "Why [Product Name]?" narrative that goes beyond feature comparison?
- Do technical choices create lock-in or switching costs (positive moat indicators)?
- Is the product positioned as a category creator, fast follower, or niche specialist?

**gtm-readiness-auditor**:
- Is pricing visible, clear, and structured for the target audience?
- Does the pricing model match the product type (usage-based for APIs, seat-based for SaaS, free for OSS)?
- Is there a free tier or trial path that lets prospects evaluate before committing?
- Is the onboarding flow self-serve or does it require contacting sales?
- Are there conversion touchpoints (newsletter, waitlist, demo request, community)?
- Is there a clear upgrade/expansion path visible?
- Does the product have distribution channel signals (marketplace listings, integrations, partnerships)?
- Are analytics/tracking configured for understanding user behavior?

### Tier 3 — Strategic Synthesis (AI judgment)

Spawn 2 parallel agents:

**pmf-signal-assessor**:
- Synthesize Tier 1 and Tier 2 findings into an overall product-market fit signal assessment
- Apply the Sean Ellis "very disappointed" test heuristic: based on artifacts, would users be very disappointed if this product disappeared?
- Evaluate the Gibson Biddle DHM model from artifacts: Delight (is the UX compelling?), Hard-to-copy (are there moat signals?), Margin-enhancing (does the pricing model scale?)
- Apply the Strategyzer Value Proposition Canvas: are Jobs, Pains, and Gains clearly addressed?
- Identify the strongest PMF signal and the weakest signal with specific evidence
- Assess: is this product in search, early traction, or scaling phase?

**investor-buyer-readiness-evaluator**:
- Technical due diligence lens: what would an acquirer or investor flag?
- Is the product differentiation defensible against well-resourced competitors?
- Does the documentation quality suggest a mature or early-stage organization?
- Are there signals of technical debt that would concern a buyer? (outdated deps, prototype code in production paths)
- Is the product story coherent from README to architecture to deployment?
- Would a competitor's engineer understand and respect this codebase in a due diligence review?
- Overall narrative: is there a clear, compelling story from problem → solution → traction → scale?

## Output: Prioritized Report

Present findings using the following structure:

```markdown
## Product & Market Audit Complete

**Scope**: [project path]
**Product Type**: [detected type — SaaS, SDK, CLI, framework, etc.]
**Target Audience**: [detected audience — developers, business users, etc.]
**Product Phase**: [search, early traction, scaling]
**Tiers Run**: [1, 2, 3] or [1 only]

  ============================================
  ||     PRODUCT SCORE: [N]/100            ||
  ||     Grade: [Letter] — [Label]         ||
  ============================================

### Category Scores

| Category | Weight | Score | Grade | Bar |
|----------|--------|-------|-------|-----|
| Value Proposition Clarity | 20% | [N]/100 | [A-F] | [████████░░] |
| Messaging Consistency | 15% | [N]/100 | [A-F] | [██████░░░░] |
| Positioning & Differentiation | 15% | [N]/100 | [A-F] | [████████░░] |
| Product Completeness | 15% | [N]/100 | [A-F] | [██████████] |
| Go-to-Market Readiness | 10% | [N]/100 | [A-F] | [████████░░] |
| ICP & Audience Definition | 10% | [N]/100 | [A-F] | [████░░░░░░] |
| Developer Experience | 10% | [N]/100 | [A-F] | [██████░░░░] |
| Trust & Credibility | 5% | [N]/100 | [A-F] | [████░░░░░░] |

### Health Score

Calculate from findings:
- Start at 100
- Each P1: -12 points
- Each P2: -4 points
- Each P3: -1 point
- Floor: 0

| Score Range | Label |
|-------------|-------|
| 90-100 | Excellent |
| 75-89 | Good |
| 60-74 | Fair |
| 40-59 | Needs Work |
| 0-39 | Critical |

**Score: [N]/100 — [Label]**

### Health Summary

| Metric | Value | Status |
|--------|-------|--------|
| Value proposition | [clear/vague/missing] | [ok/warning/critical] |
| Messaging consistency | [consistent/mixed/contradictory] | [ok/warning/critical] |
| Positioning clarity | [differentiated/generic/absent] | [ok/warning/critical] |
| Product completeness | [production/beta/prototype] | [ok/warning/critical] |
| GTM readiness | [ready/partial/missing] | [ok/warning/critical] |
| Target audience | [explicit/implied/unclear] | [ok/warning/critical] |
| Developer experience | [polished/functional/rough] | [ok/warning/critical] |
| Trust signals | [strong/present/weak] | [ok/warning/critical] |

### Findings

#### P1 — Critical (Prospect Cannot Evaluate Product)
[Prospect cannot determine what the product does, major messaging contradictions across surfaces, product appears non-functional or unstable, security posture blocks enterprise adoption]

#### P2 — Important (Weakened Positioning / Adoption Friction)
[Inconsistent messaging across surfaces, incomplete onboarding path, weak or generic differentiation, missing GTM artifacts, unclear target audience]

#### P3 — Suggestions (Polish & Optimization)
[Tone inconsistencies, minor copy improvements, SEO optimization opportunities, additional trust signals, competitive comparison gaps]

### PMF Signal Assessment

| Signal | Strength | Evidence |
|--------|----------|----------|
| Problem clarity | [strong/moderate/weak] | [specific citation] |
| Solution fit | [strong/moderate/weak] | [specific citation] |
| Differentiation | [strong/moderate/weak] | [specific citation] |
| Audience definition | [strong/moderate/weak] | [specific citation] |
| Traction indicators | [strong/moderate/weak] | [specific citation] |

**Overall PMF Signal: [Strong / Emerging / Unclear / Absent]**

### Quick Wins

| Action | Impact | Effort | Category |
|--------|--------|--------|----------|
| [highest-impact, lowest-effort action] | High | < 1 hour | [category] |
| [second action] | High | < 2 hours | [category] |
| [third action] | Medium | < 4 hours | [category] |

### Positive Observations
[Strong product elements, effective positioning, clear audience targeting, compelling trust signals]

### Recommended Actions
1. [Highest-impact fix — usually P1 items]
2. [Second priority]
3. [Strategic investment recommendation]
```

## Scoring Methodology

### Per-Check Scoring
- P1 check passed: 10 points
- P2 check passed: 6 points
- P3 check passed: 3 points
- Failed check: 0 points

### Category Scoring
Category score = (earned points / maximum possible points) × 100

### Overall Score
Weighted sum across categories using the weights in the Category Scores table.

### Grade Scale

| Grade | Score Range | Label |
|-------|-------------|-------|
| A | 90-100 | Market-Ready |
| B | 80-89 | Strong Foundation |
| C | 70-79 | Needs Positioning Work |
| D | 60-69 | Significant Gaps |
| F | 0-59 | Critical |

## Actionable Next Steps

After presenting the report, offer:

```markdown
## Next Steps

1. **Fix critical findings** — Address P1 items (unclear value prop, contradictory messaging, non-functional product signals)
2. **Implement quick wins** — Low-effort, high-impact improvements from the Quick Wins table
3. **Sharpen positioning** — Use April Dunford's positioning framework to clarify competitive context
4. **Validate with prospects** — Use findings to structure prospect interviews around weak signals
5. **Re-audit after fixes** — Run `/workflow:audit-product` to verify progress
6. **Save report** — Export findings to `./planning/product-audit-report.md`
7. **Run complementary audits** — `/workflow:audit-docs` for documentation depth, `/workflow:audit-frontend` for UX quality
```

## Integration Points

### With /workflow:audit-docs

audit-product evaluates whether documentation tells a compelling product story; audit-docs evaluates documentation completeness and accuracy. A product with excellent docs but weak positioning still loses prospects.

### With /workflow:audit-frontend

audit-product examines product messaging and positioning in the UI; audit-frontend examines component architecture, accessibility, and performance. Both contribute to the user's overall impression.

### With /workflow:audit-repo

audit-product assesses product maturity signals; audit-repo assesses engineering infrastructure maturity. Investor/buyer readiness depends on both.

### With /workflow:audit-api

audit-product examines developer experience and time-to-value; audit-api evaluates API design quality. For developer-facing products, API quality is a core product differentiator.

### With /workflow:audit-code

audit-product examines defensibility and moat signals in architecture; audit-code examines code quality. Technical debt found in audit-code may surface as product completeness concerns in audit-product.

### With /workflow:audit-tests

audit-product examines production readiness and trust signals; audit-tests evaluates test coverage and quality. Strong test coverage is a trust signal for enterprise adoption.

### With /workflow:plan and /workflow:refine

Product audit findings can inform requirements refinement and planning — P1/P2 findings become inputs for the next planning cycle.

### With /workflow:compound

Product audit insights about positioning, messaging, and competitive stance are excellent candidates for knowledge capture via compound.

## References

- [Obviously Awesome](https://www.aprildunford.com/obviously-awesome) — April Dunford's positioning framework: competitive alternatives, unique attributes, value, target customer, market category
- [Sean Ellis PMF Test](https://www.startup-marketing.com/the-startup-pyramid/) — "How would you feel if you could no longer use this product?" — the "very disappointed" benchmark
- [Gibson Biddle DHM Model](https://gibsonbiddle.medium.com/intro-to-product-strategy-60bdf72b17e3) — Delight customers, in Hard-to-copy, Margin-enhancing ways
- [Strategyzer Value Proposition Canvas](https://www.strategyzer.com/library/the-value-proposition-canvas) — Jobs-to-be-done, Pains, and Gains mapping
- [react-doctor](https://github.com/millionco/react-doctor) — Health scoring concept adapted from this React diagnostic CLI
