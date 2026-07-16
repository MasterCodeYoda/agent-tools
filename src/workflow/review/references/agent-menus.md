# Review agent menus

Load when selecting review depth (quick / standard / deep).

## Agent Orchestration

For review criteria and quality standards, reference @workflow (`execution/quality-checkpoints.md`)

### Quick Review (2 agents)

Run in parallel:

**code-quality-reviewer**:
- Code clarity and readability
- Pattern consistency
- Obvious bugs or issues
- Test coverage

**security-basics**:
- Input validation
- Obvious vulnerabilities
- Sensitive data handling

### Standard Review (5 agents)

Run in parallel:

**code-quality-reviewer**: (as above)

**security-sentinel**:
- OWASP Top 10 checks
- Authentication/authorization
- Data protection
- Injection vulnerabilities

**performance-oracle**:
- N+1 queries
- Inefficient algorithms
- Resource leaks
- Caching opportunities

**architecture-strategist**:
- Layer violations
- Dependency direction
- Pattern consistency
- Coupling/cohesion

**test-reviewer** — References @test-strategy:
- Test coverage for changed code
- Test quality and assertion strength (see @test-strategy `references/test-quality.md`)
- Edge cases for changed logic
- Regression risk assessment
- If mutation tool available: flag domain logic changes lacking mutation testing coverage
- SCRAP structural analysis on changed test files (see @test-strategy `references/scrap-scoring.md`):
  - Score each changed/added test function and report any with SCRAP > 12 (questionable) or > 20 (poor)
  - Flag smell penalties: no-assertions, low-assertion-density, multiple-phases, high-mocking, large-example
  - If a SCRAP baseline exists, compare and report verdict (improved/worse/mixed/unchanged)
  - Report actionability class for changed test files (AUTO_REFACTOR, REVIEW_FIRST, etc.)
  - Flag duplication clusters with positive extraction pressure in changed test files

**acceptance-criteria-verifier** (only when plan/requirements/PM issue found in §3):
- Load acceptance criteria from the appropriate source: `requirements.md` (file mode) or PM issue (PM mode) via
  Issue Retrieval Strategy from @workflow (PM integration)
- Cross-reference each acceptance criterion against the changes — is it addressed?
- Check the plan's Definition of Done checklist — are all items satisfiable from the diff?
- Verify all planned tasks are reflected in the changes (no missing slices)
- Flag criteria that appear unmet or only partially addressed as P1 findings
- Flag planned tasks with no corresponding changes as P2 findings
- If the plan has an Out of Scope section, verify nothing out-of-scope crept in

### Deep Review (8+ agents)

Standard agents (including acceptance-criteria-verifier when plan available) plus:

**domain-expert** (based on file types):
- Language-specific best practices
- Framework conventions
- Idiomatic code

**data-integrity-guardian**:
- Database migrations
- Data consistency
- Transaction handling

**observability-analyst**:
- Logging adequacy
- Monitoring hooks
- Debug-ability

### Synthesis Pass (Standard and Deep)

After the parallel agents report and findings are drafted, run the Critic Pass — see @workflow
(`references/critic-pass.md`) — before producing the verdict:

- **Blind-spot pass** — one agent asks what category of risk none of the reviewers raised;
  emits any concrete gaps tagged `[blind-spot]`.
- **Refutation pass** — each P1 is handed to a skeptic that tries to refute it; P1s refuted on
  the evidence are downgraded or retracted, so a false positive cannot block the merge.

Skip this pass for Quick reviews.

