---
name: clean-architecture
description: Guide projects through Clean Architecture patterns with strict layer boundaries, vertical slicing, and dependency inversion. Use when implementing features following Clean Architecture, creating domain models, application use cases, or validating architectural compliance. Language-agnostic with support for Python, TypeScript, C#, Rust, and extensible to others.
---

# Clean Architecture

Language-agnostic guide for strict layer boundaries, vertical slicing, and dependency inversion.

## When to Use This Skill

- Starting a Clean Architecture project or feature with clear layer separation  
- Domain entities, value objects, aggregates, use cases, repositories/gateways  
- Validating layer boundaries; teaching/reviewing architectural compliance  

## Quick Decision Tree

**"Where does this code belong?"** (in order):

1. **Business rule / core concept?** → **Domain** (pure, no external deps) — `references/layer-patterns.md#domain`  
2. **Orchestrates business operations?** → **Application** — `references/layer-patterns.md#application`  
3. **Connects to external systems?** → **Infrastructure** — `references/layer-patterns.md#infrastructure`  
4. **UI / entry point?** → **Frameworks** — `references/layer-patterns.md#frameworks`  
5. **Separate packages/crates?** Team >3 or long-lived / strict compliance → yes; prototype/small team → modules OK — `references/polyglot-projects.md`  

## Core Architectural Rules

### The Dependency Rule (MANDATORY)

**Dependencies ALWAYS flow inward:**

```
[Frameworks] → [Infrastructure] → [Application] → [Domain]
  (outer)         (concrete)       (orchestration)   (pure)
```

- Domain knows nothing about outer layers  
- Application knows only Domain  
- Infrastructure knows Application + Domain  
- Frameworks may know inner layers  

**Never violate this rule.** Inner layers cannot import, reference, or know about outer layers.

### Compile-Time Enforcement

Prefer separate packages/crates where strict compliance matters (Rust crates, TS packages). Compiler prevents illegal imports — see `references/polyglot-projects.md`.

### Service Abstractions Placement

Repository/gateway interfaces live in the **application** layer, colocated with use cases — not a separate "ports" package. Keeps abstractions next to consumers.

### Implementation Strategy: Vertical Slicing + Layer Sanctity

- **When:** one user story end-to-end (all layers) before the next — `references/vertical-slicing.md`  
- **How:** dependencies only inward; each layer's responsibilities — `references/layer-patterns.md`  

Example order for "Create Task": Domain entity → Application use case → Infrastructure repo → Framework endpoint → tests → checkpoint.

## Core Concepts (load depth)

Entities vs value objects, encapsulation, use-case shape (UseCase + Request + Response in one file):  
**load** `references/core-concepts.md` and `references/layer-patterns.md` — do not re-teach full essays here.

## Language-Specific Implementation

| Language | Guide (patterns/tools) |
|----------|------------------------|
| Python | `languages/python/guide.md` |
| TypeScript | `languages/typescript/guide.md` |
| C# | `languages/csharp/guide.md` |
| Rust | `languages/rust/guide.md` |
| Other | `languages/README.md` |

## Example: Task Manager

- `example-task-manager/README.md` + domain / application / infrastructure / frameworks docs  

## Validation and Quality Checks

**Python validators** (adjust install path): import/structure validators under the skill's language tools.  
**TypeScript:** multi-package project references or `eslint-plugin-boundaries`.  

### Manual Review Checklist

- [ ] Dependencies flow inward only  
- [ ] Domain has no external dependencies  
- [ ] Use cases are framework-agnostic  
- [ ] Repositories return domain entities  
- [ ] Controllers/endpoints are thin  
- [ ] Business logic is in domain  
- [ ] Tests mirror source structure  

See `templates/architecture-review.md`. Templates: `templates/decision-tree.md`, `templates/user-story-checklist.md`. Feature workflow: `references/vertical-slicing.md`.

## Common Pitfalls

One-liners — detail in core-concepts / layer-patterns:

1. Framework/DB logic in domain → keep domain pure  
2. Anemic entities → behavior + invariants in domain  
3. Fat use cases → push rules down to domain  
4. Skipping layers (controller → repo) → always via use cases  
5. Shared mutable collections on entities → copies / immutability  

## Core References

| Ref | Contents |
|-----|----------|
| `references/core-concepts.md` | Dependency rule, SOLID, entities/VOs, domain services/events |
| `references/layer-patterns.md` | Per-layer responsibilities and patterns |
| `references/vertical-slicing.md` | Story workflow + checkpoints |
| `references/implementation-strategy.md` | Vertical + horizontal combination |
| `references/polyglot-projects.md` | Multi-package/crate monorepos |
| `references/external-resources.md` | Papers, books, courses |

## Testing by Layer

- **Domain** — pure unit tests, no mocks  
- **Application** — orchestration; mock at service abstractions (@test-strategy)  
- **Infrastructure** — integration with real resources  
- **Frameworks** — E2E critical paths  

| Language | Boundary enforcement |
|----------|----------------------|
| Rust | Compile-time separate crates |
| TypeScript | `eslint-plugin-boundaries` / multi-package |
| C# | Separate `.csproj` |
| Python | Convention + review (`import-linter` optional) |

Without compile-time enforcement, audits should flag layer violations aggressively.  
**Methodology** (strategy, assertions, mocking philosophy): @test-strategy is authoritative.

## When NOT to Use Clean Architecture

Skip for: simple CRUD, prototypes, scripts, tiny/short-lived teams.  
Use when: complex rules, multi-team, long life, tech may change, testability critical.

## Commands

- `/workflow:audit` — architectural compliance (code/api domains)  
- `/workflow:review` — dependency direction and layer compliance  

## Related Skills

- **code-patterns** — language implementation of these patterns  
- **test-strategy** — testing methodology within layers  
- **workflow** — vertical slicing / ordering in the workflow family  

## Credits

Synthesized from Clean Architecture and DDD canon (Martin, Evans, Vernon, Fowler, Percival & Gregory, and others). Citations: `references/external-resources.md`.
