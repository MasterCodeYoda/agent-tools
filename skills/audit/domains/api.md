# API Design Domain

Agents and criteria for auditing API surface design — REST conventions, OpenAPI/GraphQL schema quality, security, and consistency.

Consumed by `/workflow:audit` orchestrator. Use `--focus api` for this domain only.

## User Input

```text
$ARGUMENTS
```

## Input Detection

Parse input to determine audit scope:

| Input Pattern | Scope | Action |
|---|---|---|
| `openapi.yaml` or `*.swagger.json` | Spec file | Audit the API spec directly |
| `schema.graphql` or `*.graphql` | GraphQL schema | Audit GraphQL schema |
| `./src/api/` or `./routes/` | Code directory | Discover endpoints from source code |
| `all` or empty | Full project | Auto-detect API type and specs |
| `--type rest` | REST only | Focus on REST endpoints and OpenAPI |
| `--type graphql` | GraphQL only | Focus on GraphQL schema and resolvers |
| `--recent 7d` | Recent changes | Audit files modified in last N days |
| `--diff main` | Changed files | Audit files changed vs. specified branch |

## Auto-Detection Phase (Exhaustive Discovery)

**Discovery mandate**: Complete ALL steps below before reporting any findings. Use multiple search strategies for each step. You have a dedicated 1M token context window; use it for thoroughness, not sampling. See the orchestrator's Exhaustive Discovery Protocol for general principles.

### Step 1: Discover ALL API surfaces
- Search for ALL API types in the repo: REST endpoints, GraphQL schemas, gRPC protos, IPC commands (Tauri, Electron), MCP tools
- Projects may have multiple API surfaces (public HTTP, internal IPC, admin API) — find all of them
- Search for route definitions using both glob (`routes/`, `api/`) and content grep (`#[tauri::command]`, `@app.route`, `router.get`)

### Step 2: Locate specs and tooling
- Search for ALL spec files: `openapi.*`, `swagger.*`, `schema.graphql`, `*.proto`
- Detect API framework(s) per surface
- Check for API tooling (Spectral, Vacuum, graphql-eslint, Redocly)

### Step 3: Count and classify
- Count endpoints/operations per API surface using exhaustive search
- Cross-reference discovered endpoints against any spec files for completeness

## Scope Gate

Based on auto-detection, prompt user for scope confirmation:

- **Small** (< 20 endpoints): All tiers automatically
- **Medium** (20-100 endpoints): Tier 1 on all; prompt before Tier 2/3
- **Large** (100+ endpoints): Require explicit scoping or Tier 1 sampling

## Agent Reasoning Standards

Follow all standards from the orchestrator's Agent Reasoning Standards (cite evidence, check opposite hypothesis, verify absence claims, complete discovery before findings, use full 1M context budget, tag domain, flag cross-domain connections). Additionally:

- **Trace endpoint behavior.** When a finding involves a handler or resolver, follow it to its actual implementation. Don't assume behavior from route names or schema types alone.

## Three-Tier Analysis

### Tier 1 — Spec & Convention Analysis (always runs)

Spawn 2 parallel agents that read API specs and source code:

**api-spec-linter** — If OpenAPI/GraphQL spec exists:
- Schema completeness (request/response types, required fields, examples)
- Description coverage on operations, parameters, and properties
- Response code coverage (4xx/5xx defined, not just 200)
- Security scheme definitions present and applied
- Unused components detection
- Naming consistency (operationId pattern, property casing)
- Spec version currency

**api-convention-checker** — Read source code for endpoint patterns:
- Resource naming (plural nouns, kebab-case URIs, camelCase JSON)
- HTTP method semantics (GET is safe/idempotent, POST creates, etc.)
- HTTP status code correctness (201 for creation, 204 no content, proper 4xx)
- Error response format (RFC 9457 Problem Details or consistent org format)
- Versioning strategy consistency (URL path, header, or query — one approach)
- Pagination on all list endpoints (cursor-based preferred for large datasets)
- Filtering/sorting parameter patterns

### Tier 2 — Security & Contract Analysis (auto-detect: runs if tooling or specs found)

Spawn 2 parallel agents:

**api-security-analyst** — References OWASP API Security Top 10 (2023):
- Object-level authorization (BOLA) — ID params checked against authenticated user
- Authentication robustness — token validation, brute-force protection
- Property-level authorization — sensitive fields not exposed
- Resource consumption limits — rate limiting, request size limits, timeouts
- Function-level authorization — admin endpoints protected
- Input validation — server-side validation on all parameters
- SSRF vectors — URL parameters not used for server-side requests unsafely

**api-contract-completeness-checker**:
- Schema validation coverage (all inputs validated against schema)
- Breaking change detection (if previous spec version available)
- Request/response example validity (examples match schema)
- Content-type negotiation (Accept/Content-Type headers handled)
- GraphQL-specific: query depth limits, complexity limits, N+1 in resolvers

### Tier 3 — Design Quality (AI judgment)

Spawn 2 parallel agents:

**api-design-reviewer** — References Zalando/Microsoft API guidelines:
- Resource modeling quality (decomposition appropriate for domain)
- Consistency across endpoints (patterns repeat predictably)
- Pagination strategy fit (cursor vs offset appropriate for data shape)
- Error message quality and actionability
- Developer experience (DX) assessment — is the API intuitive?
- Caching strategy (Cache-Control, ETag, conditional requests)
- Async pattern usage (202 Accepted for long operations)

**api-evolution-reviewer**:
- Backward compatibility patterns (additive changes only, deprecation headers)
- API inventory hygiene (no undocumented/shadow endpoints)
- Documentation-to-implementation alignment (spec matches actual behavior)
- SDK/client generation readiness (spec quality sufficient for codegen)

## Output: Prioritized Report

Present findings using the same P1/P2/P3 structure as `/workflow:review`:

```markdown
## API Audit Complete

**Scope**: [spec files / directories / endpoints audited]
**API Type**: [REST / GraphQL / gRPC / hybrid]
**Framework**: [detected framework]
**Endpoints**: [N] operations
**Tiers Run**: [1, 2, 3] or [1 only]

### Health Summary

| Metric | Value | Status |
|--------|-------|--------|
| Spec completeness | X% operations documented | [ok/warning/critical] |
| Naming conventions | [consistent/issues] | [ok/warning] |
| Error format | [RFC 9457/custom/inconsistent] | [ok/warning/critical] |
| Security schemes | [defined/missing] | [ok/critical] |
| OWASP API Top 10 | N issues | [ok/warning/critical] |
| Pagination coverage | X/Y list endpoints | [ok/warning/critical] |
| Rate limiting | [present/missing] | [ok/warning/critical] |
| Breaking changes | N risks | [ok/warning] |

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

### Findings

#### P1 — Critical (Security / Missing Auth)
[Security violations, missing authentication/rate-limiting, BOLA risks — these are exploitable]

#### P2 — Important (Consistency / Missing Specs)
[Naming inconsistencies, missing OpenAPI/GraphQL schemas, broken contracts]

#### P3 — Suggestions (DX / Polish)
[Developer experience improvements, caching opportunities, documentation alignment]

### Positive Observations
[Well-designed areas, consistent patterns, strong security posture]

### Recommended Actions
1. [Highest-impact fix — usually P1 items]
2. [Second priority]
3. [Tool recommendation if API linting not configured]
```

## Actionable Next Steps

After presenting the report, offer:

```markdown
## Next Steps

1. **Fix critical findings** — Address P1 items (security violations and missing auth)
2. **Create follow-up tasks** — Track P2/P3 improvements
3. **Re-audit after fixes** — Run `/workflow:audit --focus api [same scope]` to verify
4. **Install API tooling** — [if linting not configured: recommend Spectral, Vacuum, or Redocly]
5. **Save report** — Export findings to `./planning/api-audit-report.md`
```

## Integration Points

### With /workflow:audit --focus code

audit-code checks code quality; audit-api checks API design quality. They are complementary — code quality doesn't guarantee good API design and vice versa.

### With /workflow:audit --focus docs

audit-docs checks if API documentation exists; audit-api checks if it's correct and matches the implementation.

### With /workflow:review

Review checks API changes in diffs/PRs. Audit-api examines the current API state regardless of when endpoints were written.

### With /workflow:execute

During execution, if an API audit was recently run, reference its findings for the endpoints being worked on.

### With @clean-architecture

Framework layer patterns from `references/layer-patterns.md#frameworks` inform API endpoint structure. Controller thinness and use case delegation are shared concerns.

### With @code-patterns

Language-specific API framework best practices (FastAPI, Express, ASP.NET, Axum) provide the implementation standards that audit-api checks against.

## References

- [react-doctor](https://github.com/millionco/react-doctor) — Health scoring concept adapted from this React diagnostic CLI
