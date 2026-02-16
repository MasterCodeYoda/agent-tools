---
name: workflow:audit-frontend
description: Audit frontend code for accessibility, component architecture, performance, state management, and security
argument-hint: "[directory path, component glob, or 'all']"
---

# Frontend Audit

Examine frontend code for accessibility, component architecture, performance, state management, and security — and produce prioritized, actionable findings.

## User Input

```text
$ARGUMENTS
```

## Input Detection

Parse input to determine audit scope:

| Input Pattern | Scope | Action |
|---|---|---|
| `./src/components/` | Directory | Audit components in directory |
| `./src/pages/` or `./app/` | Pages/routes | Audit page-level code |
| `*.tsx` or `*.vue` | File glob | Audit matching files |
| `all` or empty | Full frontend | Auto-detect frontend structure, audit everything |
| `--focus a11y` | Accessibility | Accessibility-only audit |
| `--focus perf` | Performance | Performance-only audit (CWV, bundles) |
| `--focus security` | Security | Frontend security audit |

## Auto-Detection Phase

Before analysis, detect the project's frontend setup:

```
1. Detect frontend framework (React, Vue, Angular, Svelte, Astro, vanilla)
2. Detect meta-framework (Next.js, Nuxt, SvelteKit, Remix, Astro)
3. Detect styling approach (CSS Modules, Tailwind, styled-components, Sass, vanilla CSS)
4. Detect state management (Zustand, Redux, Pinia, Context API, signals)
5. Detect build tooling (Vite, webpack, Turbopack, esbuild)
6. Detect testing setup (Vitest, Jest, Playwright, Cypress, Testing Library)
7. Count component files and estimate complexity
```

## Scope Gate

Based on auto-detection, prompt user for scope confirmation:

- **Small** (< 30 component files): All tiers automatically
- **Medium** (30-150 files): Tier 1 on all; prompt before Tier 2/3
- **Large** (150+ files): Require explicit scoping or Tier 1 sampling

## Three-Tier Analysis

### Tier 1 — Static Analysis (always runs)

Spawn 2 parallel agents that read frontend code:

**frontend-lint-analyst**:
- ESLint rule coverage and violations (framework-specific plugin active)
- TypeScript strict mode compliance
- Accessibility lint rules (jsx-a11y or framework equivalent)
- Security lint rules (no unsanitized raw HTML injection)
- Browser compatibility lint (eslint-plugin-compat against browserslist)
- Stylelint violations (if CSS/SCSS present)

**dependency-and-bundle-analyst**:
- Dependency vulnerabilities (npm/yarn audit — flag critical/high only)
- Unused dependencies (depcheck)
- Unused CSS detection (PurgeCSS analysis or Coverage API)
- Bundle size per-route (if build output available)
- Heavy dependency detection (packages > 50KB gzipped contributing to bundle)
- Duplicate dependencies in bundle

### Tier 2 — Build-Dependent Analysis (auto-detect: runs if build possible)

Spawn 2 parallel agents:

**performance-metrics-runner**:
- Core Web Vitals via Lighthouse CI (LCP < 2.5s, INP < 200ms, CLS < 0.1)
- Bundle analysis (webpack-bundle-analyzer or source-map-explorer)
- Code splitting verification (route-level splitting present)
- Image optimization check (WebP/AVIF, explicit dimensions, lazy loading)
- Render-blocking resources in critical path
- Tree shaking effectiveness (no CommonJS in app code)

**accessibility-scanner**:
- axe-core automated WCAG 2.2 checks (covers approx 57% of criteria)
- Color contrast (4.5:1 normal, 3:1 large text)
- Missing alt text, missing form labels
- Keyboard navigability (tab order, focus indicators)
- ARIA usage correctness (roles, states, properties)
- Touch target sizes (minimum 44x44px)

### Tier 3 — Heuristic Analysis (AI judgment)

Spawn 3 parallel agents:

**component-architecture-reviewer** — References @code-patterns (TypeScript/React patterns):
- God components (rendering + data fetching + business logic in one file)
- Component size (flag > 200 lines, render methods > 50 lines)
- Prop count (flag > 7 props — suggests missing abstraction)
- Prop drilling depth (flag > 3 levels without context/store extraction)
- Composition patterns (children/slots preferred over deep inheritance)
- Colocation (component + test + styles + stories together)
- Circular component dependencies

**state-and-data-flow-reviewer**:
- State duplication (same data in multiple stores/contexts)
- Server state vs UI state separation (TanStack Query/SWR for server state)
- Unnecessary re-render patterns (missing memo, unstable references in deps)
- Context provider stacking (flag > 5 nested providers)
- Derived state stored instead of computed
- Global state overuse (auth/theme/locale are global; form state is local)

**ux-completeness-reviewer**:
- Error boundary coverage (every route/feature boundary wrapped)
- Loading state coverage (all async paths have loading UI — skeletons preferred)
- Empty state coverage (no blank screens when data is absent)
- Error message quality (user-friendly, not raw API errors)
- Responsive breakpoint consistency (consistent set, no ad-hoc magic numbers)
- Design token consistency (colors, spacing, typography from single source)
- CSP headers configured (no unsafe-inline/unsafe-eval in production)

## Output: Prioritized Report

Present findings using the same P1/P2/P3 structure as `/workflow:review`:

```markdown
## Frontend Audit Complete

**Scope**: [directory/files audited]
**Framework**: [detected framework + meta-framework]
**Styling**: [detected approach]
**State Management**: [detected library]
**Component Files**: [N] files
**Tiers Run**: [1, 2, 3] or [1 only]

### Health Summary

| Metric | Value | Status |
|--------|-------|--------|
| Accessibility (axe) | N violations | [ok/warning/critical] |
| Core Web Vitals | LCP/INP/CLS | [pass/fail per metric] |
| Bundle size (main) | X KB gzipped | [ok/warning/critical] |
| Dependency vulnerabilities | N critical/high | [ok/warning/critical] |
| Component health | N god components | [ok/warning] |
| State management | [clean/issues] | [ok/warning] |
| Error boundary coverage | X/Y routes | [ok/warning/critical] |
| Design token compliance | [consistent/drift] | [ok/warning] |

### Findings

#### P1 — Critical (Accessibility / Security / Failing CWV)
[Accessibility violations (legal risk), security issues, failing Core Web Vitals — these affect users directly]

#### P2 — Important (Architecture / State / Error Handling)
[God components, state duplication, missing error boundaries, prop drilling]

#### P3 — Suggestions (Consistency / Polish)
[Design token drift, responsive inconsistencies, colocation improvements]

### Positive Observations
[Well-structured areas, good patterns found, strong accessibility posture]

### Recommended Actions
1. [Highest-impact fix — usually P1 items]
2. [Second priority]
3. [Tool recommendation if static analysis not configured]
```

## Actionable Next Steps

After presenting the report, offer:

```markdown
## Next Steps

1. **Fix critical findings** — Address P1 items (accessibility violations and security issues)
2. **Create follow-up tasks** — Track P2/P3 improvements
3. **Re-audit after fixes** — Run `/workflow:audit-frontend [same scope]` to verify
4. **Install frontend tooling** — [if not configured: recommend axe-core, Lighthouse CI, eslint-plugin-jsx-a11y]
5. **Save report** — Export findings to `./planning/frontend-audit-report.md`
```

## Integration Points

### With /workflow:audit-code

audit-code examines backend/general code quality; audit-frontend examines frontend-specific concerns. They are complementary — run both for full-stack coverage.

### With /workflow:review

Review checks UI changes in diffs/PRs. Audit-frontend examines the current frontend state regardless of when components were written.

### With /workflow:execute

During execution, if a frontend audit was recently run, reference its findings for the components being worked on.

### With @code-patterns

TypeScript/React patterns from `languages/typescript.md` inform component standards. The audit checks current code against those patterns.

### With @clean-architecture

Framework layer patterns ensure frontend code doesn't leak into domain/application layers. Frontend components should consume application-layer use cases, not implement business logic.
