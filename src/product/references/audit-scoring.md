# Product Audit — Scoring Rubric & Report Template

Scoring methodology, grade scale, benchmark table, and the full report scaffold for `/product:audit`. The audit procedure lives in `audit/SKILL.md`; load this file when computing scores and assembling the final report.

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
| B | 75-89 | Strong Foundation |
| C | 60-74 | Needs Positioning Work |
| D | 40-59 | Significant Gaps |
| F | 0-39 | Critical |

## Report Template

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

| Category | Score | Grade | Bar |
|----------|-------|-------|-----|
| Value Proposition Clarity (20%) | [N]/100 | [A-F] | [████████░░] |
| Messaging Consistency (15%) | [N]/100 | [A-F] | [██████░░░░] |
| Positioning & Differentiation (15%) | [N]/100 | [A-F] | [████████░░] |
| Product Completeness (15%) | [N]/100 | [A-F] | [██████████] |
| Go-to-Market Readiness (10%) | [N]/100 | [A-F] | [████████░░] |
| ICP & Audience Definition (10%) | [N]/100 | [A-F] | [████░░░░░░] |
| Developer Experience (10%) | [N]/100 | [A-F] | [██████░░░░] |
| Trust & Credibility (5%) | [N]/100 | [A-F] | [████░░░░░░] |

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

### Benchmark Comparison

| Dimension | This Product | Typical OSS | Funded Startup | Market Leader |
|-----------|-------------|-------------|----------------|---------------|
| Value Proposition | [score] | 30-50 | 60-75 | 85+ |
| Messaging | [score] | 20-40 | 55-70 | 80+ |
| Positioning | [score] | 15-35 | 50-70 | 85+ |
| Product Completeness | [score] | 30-50 | 60-75 | 90+ |
| GTM Readiness | [score] | 10-25 | 50-70 | 85+ |
| Developer Experience | [score] | 25-45 | 55-70 | 85+ |
| Trust Signals | [score] | 15-30 | 45-65 | 85+ |

### Positive Observations
[Strong product elements, effective positioning, clear audience targeting, compelling trust signals]

### Recommended Actions
1. [Highest-impact fix — usually P1 items]
2. [Second priority]
3. [Strategic investment recommendation]
```

## Attribution

- [react-doctor](https://github.com/millionco/react-doctor) — Health scoring concept adapted from this React diagnostic CLI
