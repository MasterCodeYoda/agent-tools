---
name: test-strategy
description: Testing strategy for agents. Covers strategy selection (TDD, spec-first, property-based, contract, characterization), Red-Green-Refactor, tracer bullet testing, behavior-driven test design, mocking, property testing, and test quality verification. Language-agnostic with AI-specific anti-patterns.
---

# Testing Strategy

A framework for selecting and applying the right testing approach for each situation, ensuring every test provides genuine confidence in system behavior.

## When to Use This Skill

Activate this skill when:

- Executing work via `/workflow:execute` — testing integrates with the execution loop
- Writing tests for new functionality
- Planning test strategy during `/workflow:plan`
- Refactoring existing code while preserving behavior
- Designing interfaces for testability
- Evaluating test quality beyond coverage percentages

## Strategy Selection

Not every situation calls for the same testing approach. Select based on what you're building:

| Situation | Strategy | Why |
|-----------|----------|-----|
| Interface is unclear or evolving | **TDD (Red-Green-Refactor)** | Tests drive the design; each cycle reveals the next interface decision |
| Contract is well-known upfront | **Spec-First Testing** | Write tests from the specification, then implement to satisfy them |
| Data transformations / parsers | **Property-Based Testing** | Generates edge cases humans miss; verifies invariants across input space |
| Service boundaries / APIs | **Contract Testing** | Ensures producer and consumer agree on the interface shape |
| Legacy code, original authors gone | **Characterization Testing** | Intent unknown — capture what it does as proxy before making changes |
| AI-generated code, not fully reviewed | **Characterization → Specification** | Intent unverified — capture what it does, then validate against intended behavior |
| Refactoring code with known intent | **Specification Testing** | Intent known — encode what it *should* do, not what it currently does. Catches bugs too. |
| Straightforward CRUD | **Example-Based Tests** | Simple input/output cases are sufficient; don't over-engineer |

### Characterization vs. Specification: The Intent Decision

The choice depends on **whether intent is verified**, not on code age:

- **Specification tests** encode what the code *should* do (known, reviewable intent). Catch bugs — characterization would enshrine them.
- **Characterization tests** encode what the code *currently does* (unknown/unverified intent — legacy or unreviewed AI output).
- **AI-generated code** is a special case of unverified intent: characterize first, then specify.

**Emergent interactions** (transaction boundaries, commit ordering, shared mutable state, error propagation) warrant targeted characterization even when individual components have known intent — before refactoring those seams.

### Combining Strategies

Most features use more than one strategy (e.g. TDD for domain, contract tests at API, property tests for parsers, examples at framework).

Pre-refactoring investment: specification tests for planned components → transaction-boundary tests → skip broad characterization of complex units you already understand.

## Philosophy (short)

- **Behavior over implementation** — public outcomes; tests should survive private renames  
- **Mock at architectural boundaries** — service abstractions / external systems; not internal collaborators. Detail: `references/mocking-and-contracts.md`  
- **Tests as documentation** — names read as specifications  
- **Respect static guarantees** — don't re-test the compiler/linter  

### AI-Specific Discipline

Guard against: tautological tests, assertion-free tests, context leakage, unverified intent (characterize AI code first), untested mutations (`references/mutation-testing.md`), structural complexity creep (SCRAP: `references/scrap-scoring.md`). Full quality framework: `references/test-quality.md`.

## TDD: Red-Green-Refactor

When the interface is unclear or tests should drive design, use TDD. **Load** `references/tdd-cycle.md` for the full cycle, rules, and per-phase checklist.

## Testing with Vertical Slices

1. **Planning** — list behaviors the slice must exhibit  
2. **Tracer bullet** — one end-to-end test for the simplest behavior; minimum code across layers  
3. **Incremental** — remaining behaviors with the appropriate strategy each  
4. **Slice complete** — full suite green; refactor; commit  

## Anti-Patterns & Debugging

- Common galleries (all-tests-first, testing HOW, internal mocks, static-guarantee tests, private methods, AI tautology/assertion-free/leakage): **load** `references/anti-patterns.md`  
- Failing-test diagnosis (crash site vs root cause, trace, opposite hypothesis): **load** `references/debugging-failing-tests.md`  

## Load for depth

| Need | Open |
|------|------|
| Good test design / naming / assert | `references/test-design.md` |
| Mocking / contracts / DI | `references/mocking-and-contracts.md` |
| Testable interfaces | `references/interface-design.md` |
| Safe refactor under tests | `references/refactoring.md` |
| Property-based testing | `references/property-testing.md` |
| Quality / coverage trap | `references/test-quality.md` |
| Mutation testing ops | `references/mutation-testing.md` |
| SCRAP scoring / duplication | `references/scrap-scoring.md`, `references/scrap-duplication.md` |
| TDD cycle detail | `references/tdd-cycle.md` |
| Anti-pattern examples | `references/anti-patterns.md` |

### Language-Specific Test Organization

**Rust:** For large source files, prefer sibling `tests.rs` submodule — see `@code-patterns` → Rust → **Test File Organization**.

## Commands

- `/workflow:audit` — test suite quality (tests domain)  
- `/workflow:review` — test quality in reviews  

## Related Skills

- **code-patterns** — language tools/frameworks  
- **clean-architecture** — which layer gets which test type; this skill owns *how* to test within a layer  
- **qa** — *what* E2E to cover / NL→Playwright; this skill owns assertion design for E2E too  

## Credits

Adapted from [Matt Pocock's TDD skill](https://github.com/mattpocock/skills/tree/main/tdd), reshaped for agent-driven workflow integration, expanded with strategy selection, property-based testing, contract testing, and AI-specific anti-patterns.
