# Fuzzing (selective)

Coverage-guided or generative input campaigns that seek **crashes, hangs, and sanitizer violations** — not business-rule invariants (those belong to property-based testing).

**Posture: rare.** Out of the default execute/QA loop. Use only for untrusted-input boundaries and security/robustness surfaces. Agents help with harness stubs and crash triage; they do not make continuous campaigns free.

## When to use

- Parsers, codecs, deserializers that accept **untrusted** bytes or text
- Protocol or file-format handlers at a trust boundary
- Native/FFI bridges where memory safety matters
- Surfaces where “does not crash / does not hang” is a first-class requirement

## When not to use

- Ordinary CRUD domain rules (use examples or property tests)
- Pure business invariants (roundtrip, conservation) — use **property-based testing**
- Measuring whether tests catch logic bugs — use **mutation** or **sabotage**
- Default CI on every PR without a dedicated harness, corpus, and owner
- E2E UI flows — stay in `@qa` / Playwright

Do **not** add fuzz to a project solely because agents can write a harness. Prefer a property or strong examples when the oracle is an invariant, not “process does not die.”

## Agent economics

| What agents unlock | What remains hard |
|--------------------|-------------------|
| Harness scaffolding, seed ideas, corpus hints | Harness correctness, sanitizer setup, corpus hygiene |
| Crash grouping, draft repro steps, guard suggestions | Campaign wall-clock, flaky hangs, production integration |
| Explaining a minimal crashing input | Ownership of ongoing fuzz jobs |

## Minimal harness sketch

```
1. Identify the pure entry point (parse/decode/validate) — no network, no full app boot
2. Define input: bytes or constrained text; start with a tiny seed corpus of valid + edge samples
3. Oracle: abort/sanitizer = fail; optional: reject invalid without crash
4. Run short campaign (timebox wall-clock); keep corpus under version control or artifact store
5. On crash: minimize input, write regression test or fixed seed, fix root cause
```

Language pointers (install only when the surface warrants it):

| Language | Typical tools |
|----------|----------------|
| Rust | `cargo-fuzz` (libFuzzer) |
| C/C++ | libFuzzer, AFL++ |
| Python | Atheris, Hypothesis (stateful/fuzz-adjacent for Python objects) |
| Go | `go test -fuzz` |
| JVM | Jazzer |

Prefer the platform’s built-in fuzz when available. Deep tool configuration is out of scope for this skill — link project docs once a harness exists.

## Crash triage (agent workflow)

```
1. Dedup by stack hash / signature (do not open one issue per raw crash)
2. Minimize input; attach minimized case to the bug
3. Classify: memory unsafety / panic on valid input / hang / intentional reject path
4. Fix production code; add a regression test or corpus seed that would have caught it
5. Re-run a short campaign before closing
```

## Workflow hooks

| Phase | Expectation |
|-------|-------------|
| **Plan / execute** | Fuzz only when the unit owns an untrusted parser/codec boundary; timebox; not DoD for ordinary domain slices |
| **Review** | New untrusted parser without robustness story → **P3** (or **P2** if security-sensitive and no tests at all); never require continuous fuzz CI as a skill default |
| **Audit (`tests`)** | Detect harness configs if present; absence is **not** a P1 on product apps without trust-boundary parsers |
| **QA / E2E** | Out of scope — hand off unit-level crash surfaces to @test-strategy |

## Relation to other techniques

| Need | Technique |
|------|-----------|
| Invariant across valid inputs | Property-based testing |
| Tests catch injected logic faults | Mutation / sabotage |
| Process survives hostile inputs | Fuzzing |
| User journey works in UI | `@qa` E2E / NL specs |

## Anti-goals

- Fuzz as execute or `@qa` default
- Blanket CI fuzz without harness ownership
- Replacing property tests with “random inputs and hope”
- Full-app fuzzing through HTTP as the first harness (start at the pure parse entry)
