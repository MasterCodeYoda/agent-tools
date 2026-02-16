# Property-Based Testing

Testing with generated inputs that verify invariants across the input space, catching edge cases that example-based tests miss.

## When to Use Property-Based Testing

Property-based testing excels when:

- **Data transformations** — parsers, serializers, encoders, formatters
- **Mathematical properties** — sorting, arithmetic, set operations
- **Roundtrip operations** — serialize/deserialize, encode/decode, compress/decompress
- **Business rules with wide input ranges** — pricing, scheduling, validation
- **Algorithm correctness** — sorting, searching, graph traversal

Stick with example-based tests when:

- The behavior is simple and well-understood (CRUD operations)
- The test requires complex setup that doesn't benefit from generation
- You're testing integration points where inputs are constrained by the system

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

### Start with the Simplest Property

Don't try to write the perfect property first. Start with an obvious invariant:

```
property "result is not null":
  for any valid input:
    assert process(input) is not null
```

Then strengthen it:

```
property "result contains all input elements":
  for any list:
    assert sort(list) contains all elements of list
```

### Use Concrete Examples to Discover Properties

If you're struggling to identify properties, start with example-based tests and look for patterns:

```
// Examples reveal the roundtrip property
test: encode("hello") → "aGVsbG8=" → decode → "hello"
test: encode("") → "" → decode → ""
test: encode("abc") → "YWJj" → decode → "abc"

// Property: decode(encode(x)) == x for all strings
```

### Shrinking Matters

When a property test fails, the framework **shrinks** the failing input to the smallest case that still triggers the failure. This is one of the biggest advantages over random testing — you get a minimal reproduction case automatically.

Good frameworks shrink automatically. If yours doesn't, consider switching.
