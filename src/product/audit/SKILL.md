---
name: product:audit
description: Research-driven audit of product positioning, messaging, competitive stance, and go-to-market readiness
argument-hint: "['.', directory path, or '--focus positioning|messaging|gtm|devex|competitive']"
user-invocable: true
---

# Product & Market Audit

References: @product

Research-driven assessment of product positioning, messaging, competitive stance, and go-to-market readiness. **Research-first**: agents conduct extensive primary web research into competitors, market context, and comparable products before assessing local artifacts.

## User Input

```text
$ARGUMENTS
```

## Input Detection

Parse input to determine audit scope:

| Input Pattern | Scope | Action |
|---|---|---|
| `.` or empty | Current project | Full product audit with competitive research |
| Directory path | Target project | Audit the specified project |
| `--focus positioning` | Positioning only | Value proposition, differentiation, competitive stance |
| `--focus messaging` | Messaging only | Cross-surface consistency, tone, clarity |
| `--focus gtm` | GTM readiness | Pricing, onboarding, self-serve vs. sales-led signals |
| `--focus devex` | Developer experience | SDK, quickstart, time-to-value |
| `--focus competitive` | Competitive only | Deep competitive research and comparison |
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

## Research Phase (runs before analysis)

**This phase is mandatory.** Before any assessment agents run, conduct primary research to establish market context.

Spawn 2 parallel research agents:

**market-researcher**:
1. From the project's README/landing page, identify what problem the product solves and what category it occupies
2. Web search for: "[product category] tools", "[product category] alternatives", "best [product category] [current year]"
3. Identify 3-5 direct competitors and 2-3 indirect alternatives (including "do nothing" / manual process)
4. For each competitor, fetch and read:
   - Landing page (hero message, value prop, CTA)
   - Pricing page (model, tiers, free tier)
   - GitHub repo if open source (stars, last release, activity, contributor count via `gh`)
   - README (positioning, quickstart quality)
5. Search for community discussions: "[product name] vs [competitor]", "[product name] review", "[product name] alternative"
6. Return: competitor profiles, market category definition, community sentiment summary

**comparable-success-researcher**:
1. Identify 2-3 products in adjacent categories known for excellent positioning (not necessarily competitors — products that solve different problems but position exceptionally well)
2. Analyze what makes their positioning effective: specificity, clarity, differentiation, visual demo, onboarding speed
3. Return: positioning patterns to benchmark against, specific examples of effective messaging

**Research output feeds all subsequent analysis agents as context.**

## Product Context Adaptation

Based on detected signals, adjust audit emphasis:

- **Open-source / no commercial intent**: Skip GTM readiness and investor readiness agents. Weight value proposition, developer experience, and messaging consistency higher.
- **B2B enterprise**: De-emphasize self-serve evaluation path. Assess whether sales-enablement artifacts exist (case studies, ROI calculators, integration guides).
- **B2C consumer**: Weight trust signals and onboarding UX higher. Assess social proof and community signals.
- **Internal tool / platform**: Skip competitive positioning. Focus on internal adoption friction and documentation completeness.

## Scope Gate

Based on auto-detection, determine audit scope:

- **Small** (< 20 product-facing files): Run all tiers automatically
- **Medium** (20-80 product-facing files): Run Tier 1 on all; prompt before Tier 2/3
- **Large** (80+ product-facing files): Require explicit scoping or run Tier 1 sampling

## Agent Reasoning Standards

All audit agents must follow these reasoning principles:

- **Cite evidence.** Every finding must reference specific file paths and line numbers (or section anchors for docs). No finding without a concrete citation.
- **Use research context.** Every assessment must be informed by the Research Phase output. Don't evaluate positioning in a vacuum — compare against what competitors actually do. "Value prop is vague" is P3; "value prop is vague AND all three competitors lead with specific metrics" is P2.
- **Check the opposite hypothesis.** Before reporting a P1 or P2 finding, briefly consider: "Could this be intentional?" Look for documented positioning decisions, deliberate audience narrowing, or strategic omissions. If found, downgrade or retract.
- **Product-Strategy Trace.** Connect each finding to at least one impact category: conversion impact (will prospects bounce?), trust impact (does this erode credibility?), adoption impact (does this slow time-to-value?), retention signal (does this hurt stickiness?), or competitive impact (does this weaken differentiation?). If a finding has no clear impact connection, demote to P3 or retract.
- **Benchmark against research.** When making recommendations, reference specific examples from researched competitors or comparable products. "Consider adding a visual demo" is weak; "Competitor X's landing page leads with an interactive demo that shows the output in 3 seconds — consider a similar approach" is actionable.

## Three-Tier Analysis

All analysis agents receive the Research Phase output as context.

### Tier 1 — Artifact Surface Read (always runs)

Spawn 3 parallel agents that read product-facing artifacts + research context:

**value-proposition-analyst** — References @product (Clarity Hierarchy, Copy Patterns):
- Can a prospect understand what the product does in 30 seconds from the README or landing page?
- Is the tagline/headline specific and differentiated (not generic "fast, simple, powerful")?
- Does the value proposition name a specific pain point and audience?
- Is the primary CTA clear and compelling?
- Does the hero section answer: What is it? Who is it for? Why should I care?
- Are benefits stated (outcomes) vs. only features listed (capabilities)?
- Does metadata (package.json description, meta tags, Open Graph) align with the stated value prop?
- Is the project name memorable, searchable, and unambiguous?
- Does the README include a visual demo (screenshot, GIF, or video link) showing the product in action?
- Is there a one-liner install or usage command visible above the fold?

**messaging-consistency-auditor**:
- Cross-reference messaging across all text surfaces: README, landing page, docs, package metadata, CLI help text, error messages, onboarding copy
- Flag contradictions in product description across surfaces
- Flag audience mismatches (e.g., README says "for developers" but landing page targets business users)
- Check tone consistency (formal vs. casual, technical vs. accessible)
- Verify terminology consistency (same concepts use same words everywhere)
- Check that feature lists across surfaces are synchronized (no orphaned claims)
- Check CLI `--help` output (if CLI tool) for consistency with README description
- Check GitHub/registry metadata (repository description, topics, package.json keywords) for alignment with README positioning

**product-completeness-scanner**:
- Does the product appear production-ready or prototype? (versioning, changelog, stability indicators)
- Is there a CHANGELOG with recent entries indicating active maintenance?
- Are there "coming soon" or placeholder features visible to prospects?
- Is error handling user-friendly or does it leak internals?
- Do configuration defaults suggest production use or development hacks?
- Are there trust signals present? (security policy, compliance mentions, SLA, uptime, social proof)
- Is the license clearly stated and appropriate for the audience?
- Does the project have operational maturity indicators? (monitoring, logging, health checks)
- Is there a clear contribution path (CONTRIBUTING.md) appropriate for the product's audience?

### Tier 2 — Deep Artifact Analysis (runs if sufficient artifacts detected)

Spawn 3 parallel agents:

**developer-experience-auditor** (runs if developer-facing product detected):
- For API design correctness (REST conventions, schema completeness, security), defer to `/workflow:audit --focus api`. This agent focuses on the *onboarding and adoption path*, not API design quality.
- Trace the zero-to-value path: install → configure → first success — how many steps? (Flag if > 5 steps)
- Is the quickstart copy-pasteable and does it produce a visible result?
- Are prerequisites stated upfront (runtime versions, dependencies, accounts)?
- Is API reference complete and does it include examples for each endpoint/method?
- Are error messages actionable (tell user what to do, not just what went wrong)?
- Is there a playground, REPL, or interactive demo?
- Time-to-value estimate: how long from `npm install` / `pip install` to meaningful output?
- Does the SDK follow conventions of its ecosystem (naming, structure, error handling)?

**competitive-positioning-analyst**:
- Are there explicit comparison docs or "vs." pages? Are claims specific and verifiable?
- Do product artifacts *claim* defensible advantages (unique data, network effects, integration depth)? Are these claims specific and credible based on visible technical choices?
- Are migration guides available from competitors?
- Does the feature set suggest a clear category or is positioning ambiguous?
- Is there a "Why [Product Name]?" narrative that goes beyond feature comparison?
- Do technical choices create lock-in or switching costs (positive moat indicators)?
- Is the product positioned as a category creator, fast follower, or niche specialist?
- Are there ecosystem recognition signals (awesome-list inclusion, framework endorsements, badges)?

**gtm-readiness-auditor**:
- Is pricing visible, clear, and structured for the target audience?
- Does the pricing model match the product type (usage-based for APIs, seat-based for SaaS, free for OSS)?
- Is there a free tier or trial path that lets prospects evaluate before committing?
- Is the onboarding flow self-serve or does it require contacting sales?
- Are there conversion touchpoints (newsletter, waitlist, demo request, community)?
- Is there a clear upgrade/expansion path visible?
- Does the product have distribution channel signals (marketplace listings, integrations, partnerships)?
- Is analytics instrumentation present in the codebase (tracking snippets, event definitions, analytics SDKs)?

### Tier 3 — Strategic Synthesis (AI judgment)

Spawn 2 parallel agents:

**pmf-signal-assessor** — References @product (Positioning Frameworks) for the Sean Ellis PMF test, Gibson Biddle DHM model, and Strategyzer Value Proposition Canvas definitions:
- Note: These frameworks are applied as proxy indicators from artifact signals only — they are not substitutes for user research and financial analysis.
- Synthesize Tier 1 and Tier 2 findings into an overall product-market fit signal assessment
- Apply each framework as an artifact-signal lens per its @product definition: Sean Ellis (would users be very disappointed if this product disappeared?), DHM (delight, moat, and margin signals), Value Proposition Canvas (are Jobs, Pains, and Gains clearly addressed?)
- Identify the strongest PMF signal and the weakest signal with specific evidence
- Assess: is this product in search, early traction, or scaling phase?

**investor-buyer-readiness-evaluator**:
- Technical due diligence lens: what would an acquirer or investor flag from readable artifacts?
- Is the product differentiation defensible against well-resourced competitors?
- Does the documentation quality suggest a mature or early-stage organization?
- For technical debt signals that would concern a buyer, reference `/workflow:audit --focus code` findings rather than duplicating analysis here
- Is the product story coherent from README to architecture to deployment?
- Is the codebase organized with clear separation of concerns, consistent patterns, and documentation that would enable a new engineer to navigate it independently?
- Overall narrative: is there a clear, compelling story from problem → solution → traction → scale?

## Output: Prioritized Report

Scoring model in one line: per-check points (P1 = 10, P2 = 6, P3 = 3, fail = 0) roll up into weighted category scores, which combine into an overall graded product score; a separate findings-based health score starts at 100 and deducts per finding.

The full scoring rubric, category weights, grade scale, benchmark table, and complete report template live in @product (`references/audit-scoring.md`). Load that file when computing scores and render the final report exactly per its template.

## Actionable Next Steps

After presenting the report, offer:

```markdown
## Next Steps

1. **Fix critical findings** — Address P1 items (unclear value prop, contradictory messaging, non-functional product signals)
2. **Implement quick wins** — Low-effort, high-impact improvements from the Quick Wins table
3. **Sharpen positioning** — Use April Dunford's positioning framework to clarify competitive context
4. **Validate with prospects** — Use findings to structure prospect interviews around weak signals
5. **Re-audit after fixes** — Run `/product:audit` to verify progress
6. **Save report** — Export findings to `./planning/product-audit-report.md`
7. **Run complementary audits** — `/workflow:audit --focus docs` for documentation depth, `/workflow:audit --focus frontend` for UX quality
```

## Integration Points

Division of labor with `/workflow:audit` focus areas:

| Focus | audit-product examines | The focus agent examines | Why both matter |
|---|---|---|---|
| `--focus docs` | Whether documentation tells a compelling product story | Documentation completeness and accuracy | Excellent docs with weak positioning still lose prospects |
| `--focus frontend` | Product messaging and positioning in the UI | Component architecture, accessibility, performance | Both contribute to the user's overall impression |
| `--focus repo` | Product maturity signals | Engineering infrastructure maturity | Investor/buyer readiness depends on both |
| `--focus api` | Developer experience and time-to-value | API design quality | For developer-facing products, API quality is a core product differentiator |
| `--focus code` | Defensibility and moat signals in architecture | Code quality | Technical debt found in audit-code may surface as product completeness concerns |
| `--focus tests` | Production readiness and trust signals | Test coverage and quality | Strong test coverage is a trust signal for enterprise adoption |

Beyond audit focuses:

- **/workflow:plan and /workflow:refine** — Product audit findings can inform requirements refinement and planning — P1/P2 findings become inputs for the next planning cycle.
- **/workflow:compound** — Product audit insights about positioning, messaging, and competitive stance are excellent candidates for knowledge capture via compound.

## References

Framework definitions (Dunford positioning, Sean Ellis PMF test, DHM model, Value Proposition Canvas) live in @product (Positioning Frameworks) — apply them from there rather than re-deriving. Source links:

- [Obviously Awesome](https://www.aprildunford.com/obviously-awesome) — April Dunford
- [Sean Ellis PMF Test](https://www.startup-marketing.com/the-startup-pyramid/)
- [Gibson Biddle DHM Model](https://gibsonbiddle.medium.com/intro-to-product-strategy-60bdf72b17e3)
- [Strategyzer Value Proposition Canvas](https://www.strategyzer.com/library/the-value-proposition-canvas)
- [Crossing the Chasm](https://www.harpercollins.com/products/crossing-the-chasm-3rd-edition-geoffrey-a-moore) — Geoffrey Moore's technology adoption lifecycle and chasm-crossing strategies

Health scoring attribution (react-doctor) lives with the scoring rubric in @product (`references/audit-scoring.md`).
