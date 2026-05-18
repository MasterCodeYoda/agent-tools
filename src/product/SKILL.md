---
name: product
description: Product strategy skill covering positioning frameworks, competitive research methodology, messaging principles, and go-to-market patterns. Research-first — agents conduct extensive primary web research before analysis.
---

# Product Strategy

A research-driven skill for product positioning, competitive analysis, messaging, and go-to-market strategy. Every assessment and recommendation must be grounded in primary research, not assumptions.

## When to Use This Skill

Activate this skill when:

- Assessing product-market fit and positioning quality
- Running competitive analysis and comparison
- Crafting or refining product positioning
- Generating product briefs, one-pagers, or pitch content
- Evaluating developer experience and onboarding paths
- Planning go-to-market strategy

## Research-First Principle

**Every product command must conduct primary research before analysis.**

The agent does not rely solely on local codebase artifacts. Before any assessment, the agent researches:

1. **The competitive landscape** — Who else solves this problem? How do they position?
2. **The market category** — What category does this product compete in? What are category norms?
3. **Comparable successes** — What products in adjacent categories have strong positioning? What can we learn?
4. **Community signal** — What do users, developers, and industry observers say about products in this space?

### Research Tools

| Tool | When to Use |
|------|-------------|
| Web Search | Discover competitors, market analysis, industry trends, community discussions |
| Web Fetch | Read competitor landing pages, pricing pages, docs, READMEs, changelogs |
| Browser (Chrome DevTools MCP) | Screenshot competitor UX, analyze onboarding flows, inspect design quality |
| GitHub API (`gh`) | Analyze competitor repos — stars, activity, issues, contributor health, release cadence |
| Social/Community | Search X/Twitter, Hacker News, Reddit, Dev.to for product mentions and sentiment |

### Research Standards

- **Breadth**: Research at least 3-5 competitors or comparable products per analysis
- **Depth**: For each competitor, read at minimum: landing page, pricing page, docs/README, and GitHub repo (if open source)
- **Recency**: Prefer recent sources (last 12 months). Flag findings based on older data.
- **Attribution**: Cite sources for every competitive claim. "Competitor X charges $Y/month" must link to the pricing page.
- **Objectivity**: Report what competitors do well, not just weaknesses. Honest assessment is more useful than cheerleading.

## Positioning Frameworks

### April Dunford — Obviously Awesome (Primary)

The core positioning exercise. Work through these five components in order:

1. **Competitive Alternatives** — What would customers use if your product didn't exist? (Not just direct competitors — include manual processes, spreadsheets, hiring, building in-house)
2. **Unique Attributes** — What do you have that alternatives don't? (Technical capabilities, design choices, architectural decisions — must be verifiable from the codebase)
3. **Value** — What does each unique attribute enable for the customer? (Translate features into outcomes)
4. **Target Customer** — Who cares most about that value? (Define the characteristics of your best-fit customer)
5. **Market Category** — What category makes your value obvious to your target customer? (Category choice frames expectations)

### Gibson Biddle — DHM Model (Assessment)

Evaluate product strategy through three lenses:
- **Delight**: Does the product create genuine delight? (UX quality, surprising capabilities, emotional response)
- **Hard-to-copy**: What makes this defensible? (Unique data, network effects, integration depth, technical moat, community)
- **Margin-enhancing**: Does the business model scale? (Self-serve, usage-based pricing, low marginal cost)

### Sean Ellis — PMF Test (Measurement)

Proxy indicators from artifacts (since we can't survey users directly):
- **Problem articulation depth**: Does the product name a specific pain, or generic value?
- **Solution specificity**: Is the solution concrete, or vague promises?
- **Usage signals**: Stars, downloads, community activity, issue velocity
- **Retention signals**: Changelog activity, release cadence, documentation depth

### Strategyzer — Value Proposition Canvas (Discovery)

Map the value proposition:
- **Customer Jobs**: What are they trying to accomplish?
- **Pains**: What obstacles, risks, or frustrations do they face?
- **Gains**: What outcomes or benefits do they desire?
- **Pain Relievers**: How does the product address specific pains?
- **Gain Creators**: How does the product enable specific gains?

## Messaging Principles

### Clarity Hierarchy

1. **What it is** — One sentence, no jargon
2. **Who it's for** — Specific audience, not "everyone"
3. **Why it matters** — The outcome, not the mechanism
4. **How it works** — Only after the above are clear
5. **Why now** — Urgency or timeliness (if applicable)

### Cross-Surface Consistency

Product messaging appears on many surfaces. All must align:

| Surface | Role | Common Failure |
|---------|------|----------------|
| README | Technical first impression | Too much implementation, not enough "why" |
| Landing page | Commercial first impression | Vague benefits, no specifics |
| Package metadata | Discovery (npm, PyPI, crates.io) | Generic description, wrong keywords |
| CLI help text | In-product guidance | Different terminology than docs |
| Error messages | Failure experience | Leaks internals, not actionable |
| Docs intro | Onboarding first page | Assumes context the reader doesn't have |
| GitHub description | Search/browse discovery | Doesn't match README positioning |

### Copy Patterns

- **Specificity over superlatives**: "Processes 10K events/sec on a single core" beats "blazing fast"
- **Show, don't claim**: Demo, screenshot, or benchmark > adjective
- **Name the pain**: "Tired of writing boilerplate auth middleware?" > "Simple authentication"
- **Comparison anchoring**: "Like X but for Y" or "X without the Z" — only if the anchor is well-known

## Developer Experience Patterns (for dev-facing products)

### Time-to-Value Path

The critical metric: how long from discovery to first meaningful output?

```
Discovery → Install → Configure → First success → "Aha" moment
```

Each step should be:
- **One command** where possible (install)
- **Zero config** for the default case (configure)
- **Copy-pasteable** quickstart (first success)
- **Visibly valuable** output (aha moment)

### DX Anti-Patterns

- Requiring account creation before trying the product
- Multi-page setup instructions before any value
- "Coming soon" features prominently displayed
- Requiring specific environment/OS without stating upfront
- Error messages that say what went wrong but not how to fix it

## Competitive Analysis Methodology

### Research Protocol

For each identified competitor:

1. **Landing page analysis**: What do they lead with? What's the hero message? What's the CTA?
2. **Pricing analysis**: What model? What's the free tier? Where do they gate?
3. **Documentation analysis**: How's the quickstart? API reference completeness? Example quality?
4. **GitHub analysis** (if open source): Stars, forks, recent activity, issue response time, contributor count, release cadence
5. **Community analysis**: Search for "[product name] vs" discussions, reviews, complaints, praise
6. **Technical analysis**: What's their architecture? What trade-offs did they make? Where are they strong/weak technically?

### Comparison Matrix Template

```markdown
| Dimension | Our Product | Competitor A | Competitor B | Competitor C |
|-----------|-------------|-------------|-------------|-------------|
| Core value prop | | | | |
| Target audience | | | | |
| Pricing model | | | | |
| Free tier | | | | |
| Key differentiator | | | | |
| Weakness | | | | |
| GitHub stars | | | | |
| Last release | | | | |
| Docs quality | | | | |
| Community size | | | | |
```

## Commands

- `/product:audit` — Research-driven assessment of product positioning and readiness
- `/product:position` — Guided positioning exercise with competitive research
- `/product:brief` — Generate product one-pagers and pitch content from research + positioning

## Related Skills

- **audit** — The unified audit command assesses code/test/infrastructure quality, which feeds into product completeness signals
- **visual-design** — UI polish patterns that contribute to product delight
- **qa** — Test coverage as a product trust/quality signal
