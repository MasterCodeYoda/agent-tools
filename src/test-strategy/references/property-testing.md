# Property-Based Testing

Testing with generated inputs that verify invariants across the input space, catching edge cases that example-based tests miss.

**Posture:** encouraged when fit — not required for every behavior. One or two real properties on pure transforms beat large example matrices. Agents lower the cost of drafting properties; they do not invent true invariants for you.

## When to Use Property-Based Testing

Property-based testing excels when:

- **Data transformations** — parsers, serializers, encoders, formatters
- **Mathematical properties** — sorting, arithmetic, set operations
- **Roundtrip operations** — serialize/deserialize, encode/decode, compress/decompress
- **Business rules with wide input ranges** — pricing, scheduling, validation
- **Algorithm correctness** — sorting, searching, graph traversal

For those shapes, treat property tests as the **default primary signal**, with a few fixed examples as documentation and regression anchors.

## When not to use property-based testing

Stick with example-based tests when:

- The behavior is simple and well-understood (**CRUD**, getters, thin wrappers)
- There is **no stable invariant** you can state without restating the implementation
- The test requires **complex I/O or multi-service setup** that does not benefit from generation
- You're testing **integration points** where inputs are already constrained by the system
- Generators would mostly produce **invalid states** you then filter away (high discard rate, low signal)
- You would only assert **types/shapes/nullability** the type system or schema already enforces

Weak properties (restate production logic, only check “not null”, mirror the implementation’s formula) create false confidence — prefer fewer, stronger invariants or honest example tests.

## Five Property Patterns

### 1. Roundtrip (There and Back)

If you can transform data one way, transforming it back should give the original.

```
property "serialize/deserialize roundtrip":
  for any valid object:
    assert deserialize(serialize(object)) == object
```

Examples: JSON encoding, URL encoding, database serialization, encryption/decryption.

### 2. Invariant (Some Things Never Change)

Certain properties hold regardless of input.

```
property "sorting preserves length":
  for any list:
    assert length(sort(list)) == length(list)

property "sorting produces ordered output":
  for any list:
    sorted = sort(list)
    for each adjacent pair (a, b) in sorted:
      assert a <= b
```

Examples: collection operations preserve size, financial calculations maintain totals, valid state transitions.

### 3. Idempotent (Doing It Twice Is the Same as Once)

Applying the operation again produces the same result.

```
property "formatting is idempotent":
  for any valid code string:
    assert format(format(code)) == format(code)

property "deduplication is idempotent":
  for any list:
    assert deduplicate(deduplicate(list)) == deduplicate(list)
```

Examples: formatting, normalization, deduplication, cache operations.

### 4. Oracle (Test Against a Known-Good Implementation)

Compare your implementation against a simpler (possibly slower) reference.

```
property "optimized sort matches reference sort":
  for any list:
    assert optimizedSort(list) == referenceSort(list)
```

Examples: optimized algorithms vs. brute force, new implementation vs. legacy system.

### 5. Commutative (Order Doesn't Matter)

The order of operations doesn't affect the result.

```
property "adding items to cart is commutative":
  for any items a, b:
    cart1 = empty_cart.add(a).add(b)
    cart2 = empty_cart.add(b).add(a)
    assert cart1.total == cart2.total
```

Examples: set operations, aggregations, independent mutations.

## Tools by Language

| Language | Library | Notes |
|----------|---------|-------|
| Python | [Hypothesis](https://hypothesis.readthedocs.io/) | Most mature; excellent shrinking, stateful testing |
| TypeScript/JS | [fast-check](https://fast-check.dev/) | Good TS support; model-based testing |
| C# / .NET | [FsCheck](https://fscheck.github.io/FsCheck/) | F#-origin but works with C#; NUnit/xUnit integration |
| Java / Kotlin | [jqwik](https://jqwik.net/) | JUnit 5 integration; property-based + example-based |
| Rust | [proptest](https://proptest-rs.github.io/proptest/) | Strategy-based generation; shrinking |
| Go | [rapid](https://pkg.go.dev/pgregory.net/rapid) | Simple API; automatic shrinking |

## Writing Good Properties

### Discovery recipe: examples → name invariant → strengthen

Use this when strategy selection points at property-based testing (or when example tables are growing without new insight):

```
1. Write 2–4 concrete examples that capture intended behavior
2. Name what stays true across them (roundtrip? length preserved? total conserved? reject invalid?)
3. Match the name to a pattern above (Five Property Patterns) or a domain-specific invariant
4. Encode as a property with a generator for the valid input space
5. Keep 1–2 examples as regression anchors / documentation
6. Strengthen: replace weak asserts (not-null, type) with full value or behavioral checks
7. On failure: trust shrinking — fix the minimal case first, then widen generators if needed
```

Agents should propose step 2–4 from the examples and production type signatures; humans (or review) ratify that the invariant is true of the *intent*, not only of the current implementation.

### Start with the Simplest Property

Don't try to write the perfect property first. Start with an obvious invariant, then strengthen:

```
// weak starting point — only existence
property "result is not null":
  for any valid input:
    assert process(input) is not null

// strengthened — behavioral content
property "result contains all input elements":
  for any list:
    assert sort(list) contains all elements of list
```

Prefer landing on a **level 3–5** assertion (see `test-quality.md`) rather than stopping at “not null.”

### Use Concrete Examples to Discover Properties

```
// Examples reveal the roundtrip property
test: encode("hello") → "aGVsbG8=" → decode → "hello"
test: encode("") → "" → decode → ""
test: encode("abc") → "YWJj" → decode → "abc"

// Property: decode(encode(x)) == x for all strings
// Keep one example test as a named regression anchor if useful
```

### Shrinking Matters

When a property test fails, the framework **shrinks** the failing input to the smallest case that still triggers the failure. This is one of the biggest advantages over random testing — you get a minimal reproduction case automatically.

Good frameworks shrink automatically. If yours doesn't, consider switching.

### Agent workflow hooks

| Phase | Expectation |
|-------|-------------|
| **Plan** | For parsers/transforms/invariants, name properties in the test approach (not only example lists) |
| **Execute** | Prefer property + few anchors when fit; do not force PBT on CRUD or I/O-heavy glue |
| **Review / audit** | Example-only on pure transforms → **P3** default; **P2** if high-value pure logic / money-auth-adjacent. Cite discovery recipe. Never P1 for missing PBT alone. |

Do not install a property library solely to satisfy ritual. Use it when an invariant is real and the surface is pure enough to generate.

Hostile or crash-or-not oracles (untrusted bytes, “must not panic”) are **fuzzing**, not weak properties — see `fuzzing.md`.
