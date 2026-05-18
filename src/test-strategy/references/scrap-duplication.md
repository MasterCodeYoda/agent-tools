# SCRAP Duplication Analysis

How SCRAP detects structural repetition in test suites and determines whether extraction yields net benefit. Companion to `references/scrap-scoring.md`.

## Why Duplication in Tests Is Different

Not all test duplication is harmful. The question isn't "is there repetition?" — it's "does this repetition hurt or help?"

| Duplication Type | Harmful? | Why |
|-----------------|----------|-----|
| **Harmful duplication** | Yes | Repeated setup, assertion scaffolding, or fixture construction that obscures intent and inflates maintenance cost |
| **Coverage-matrix repetition** | No (usually) | Many small, low-complexity tests with similar structure exercising different inputs — this is table-driven testing done manually |
| **Subject repetition** | Lightly | Repeated calls to the same production API — expected when testing multiple behaviors of one function |

SCRAP separates these categories so that harmful duplication inflates the score while coverage-matrix and subject repetition appear in diagnostics without disproportionate penalty.

## Fuzzy Structural Normalization

Before comparing tests, SCRAP normalizes their structure to remove superficial differences:

| Original | Normalized |
|----------|------------|
| Variable names, symbols | `sym` |
| String literals | `:string` |
| Number literals | `:number` |
| Boolean literals | `:boolean` |
| Keywords | Preserved as-is |
| Collection shapes | Preserved (list, vector, map, set structure) |

This allows matching tests that differ only in variable names, literal values, or minor structural variations while preserving their overall shape.

### Example

Two tests that look different textually:

```python
def test_add_positive():
    calc = Calculator()
    result = calc.add(3, 5)
    assert result == 8

def test_add_negative():
    calc = Calculator()
    result = calc.add(-1, -4)
    assert result == -5
```

After normalization, both become:

```
def sym():
    sym = sym()
    sym = sym.sym(:number, :number)
    assert sym == :number
```

These are structurally identical — coverage-matrix candidates.

## Similarity Detection

### Jaccard Similarity

SCRAP computes similarity between test pairs using the Jaccard coefficient on their structural feature sets:

```
similarity(A, B) = |features(A) ∩ features(B)| / |features(A) ∪ features(B)|
```

**Threshold:** Tests are considered related when similarity ≥ 0.5.

### Feature Extraction

Features are extracted from four channels of each test:

- **Setup features** — Fixture construction, variable initialization, precondition establishment
- **Assert features** — Assertion patterns and shapes
- **Fixture features** — Data structures used in setup (maps, lists, object construction)
- **Arrange features** — Action/arrangement patterns before assertions

The harmful features used for clustering are the union of setup, assert, fixture, and arrange features.

### Cluster Detection

Related tests form clusters via connected components:

1. Build an edge map: test A connects to test B if their Jaccard similarity ≥ threshold
2. Find connected components via depth-first traversal
3. Each component with > 1 member is a potential duplication cluster

## Extraction Pressure

For each duplication cluster, SCRAP calculates whether extracting shared scaffolding yields net benefit.

### The Formula

```
shared_forms    = |features shared across all cluster members|
variable_points = |all features in cluster| - shared_forms
instances       = cluster member count

D_before = 0                              when shared_forms ≤ 3 or variable_points > 4
D_before = (max(0, shared_forms - 3) × (instances - 1)^1.5) / (variable_points + 1)

D_after = 0  (after extraction, duplication is eliminated)

helper_cost = shared_forms + variable_points  (cost of the new helper/fixture)

extraction_pressure = max(0, D_before - D_after - helper_cost)
```

### Interpretation

- **shared_forms ≤ 3** — Too little shared structure to justify extraction. SCRAP reports the similarity but assigns zero pressure.
- **variable_points > 4** — Too much variation between instances. A helper would need many parameters, reducing its value. Zero pressure.
- **Positive pressure** — Extraction would reduce net complexity. Higher pressure = stronger recommendation.
- **Zero pressure** — Extraction would cost more than it saves. Leave the duplication in place.

### Why This Matters

Naive deduplication tools flag all repetition equally. SCRAP's extraction pressure model prevents:

- Extracting trivially similar tests into a confusing helper
- Creating parameterized helpers that need 6 arguments
- Breaking readable test isolation for marginal DRY benefit

## Coverage-Matrix Detection

A test is a **coverage-matrix candidate** when it meets ALL of:

| Criterion | Threshold |
|-----------|-----------|
| SCRAP score | ≤ 18 |
| Line count | ≤ 12 |
| Assertions | ≤ 1 |
| Branches | 0 |
| Setup depth | ≤ 2 |
| Mocks/patches | 0 |
| Temp resources | 0 |
| Helper-hidden lines | 0 |
| Table-driven or has harmful features + subject symbols ≤ 2 | Yes |

Coverage-matrix clusters get a **credit** that reduces refactor pressure rather than inflating it. These are tests doing the right thing (many simple cases) — they just happen to look repetitive.

### When to Table-Drive Coverage Matrices

Convert coverage-matrix clusters to parameterized/table-driven tests when:

- The cluster has ≥ 3 members with the same structure
- Each member differs only in input values and expected output
- The test name pattern follows "test_X_with_Y" or similar

```python
# Before: coverage-matrix cluster (3 similar tests)
def test_discount_10_percent():
    assert calculate_discount(100, 0.1) == 10

def test_discount_20_percent():
    assert calculate_discount(100, 0.2) == 20

def test_discount_50_percent():
    assert calculate_discount(100, 0.5) == 50

# After: table-driven
@pytest.mark.parametrize("amount,rate,expected", [
    (100, 0.1, 10),
    (100, 0.2, 20),
    (100, 0.5, 50),
])
def test_discount_calculation(amount, rate, expected):
    assert calculate_discount(amount, rate) == expected
```

Do NOT table-drive when:
- Tests verify fundamentally different behaviors (not just different inputs)
- The test names describe different business rules
- Collapsing them would lose documentation value

## Duplication Score Channels

SCRAP reports duplication across multiple channels to provide granular diagnostics:

| Channel | What It Measures |
|---------|-----------------|
| **harmful_duplication** | Total structural repetition across setup, assertion, fixture, and arrange patterns — the primary concern |
| **setup_duplication** | Repeated fixture construction / variable initialization |
| **assertion_duplication** | Repeated assertion patterns |
| **fixture_duplication** | Repeated data structure construction |
| **arrange_duplication** | Repeated action/arrangement patterns |
| **literal_duplication** | Repeated large literal values |
| **case_matrix_repetition** | Coverage-matrix candidate count (informational, reduces pressure) |
| **subject_repetition** | Repeated calls to the same production API (lightly penalized) |

Only `harmful_duplication` feeds into the refactor pressure score. The other channels appear in verbose reports and guide specific extraction recommendations.

## Extraction Recommendations

When extraction pressure is positive, SCRAP produces specific recommendations:

```
Extraction Recommendation:
  Cluster: tests at lines 15-22, 28-35, 41-48
  Shared forms: 6
  Variable points: 2
  Instances: 3
  Net benefit: 4.2

  Suggestion: Extract shared setup (Calculator initialization + input formatting)
  into a fixture or helper. Parameterize the 2 varying values.
  
  Examples:
    - test_add_with_formatting (line 15)
    - test_subtract_with_formatting (line 28)
    - test_multiply_with_formatting (line 41)
```

### Recommendation Priority

Recommendations are sorted by:
1. Line position (earliest first, for natural reading order)
2. Net benefit (highest first, within the same position range)

Only recommendations with positive net benefit are included. The policy default limits output to the top 4 recommendations per file.

## Shape Diversity

SCRAP also measures **shape diversity** — how structurally varied the tests in a file are. A file where all tests have identical structure (same setup, same assertion pattern, same length) may be a coverage matrix. A file with high shape diversity has tests of varying complexity and structure, which is typical of a well-designed test suite covering multiple behaviors.

Low shape diversity + high duplication → table-drive candidate
Low shape diversity + low duplication → naturally focused file
High shape diversity + high duplication → harmful duplication (different behaviors sharing too much scaffolding)
High shape diversity + low duplication → healthy, varied test suite

## Integration with Audit

The duplication analysis feeds into the SCRAP audit agent's recommendations:

- **AUTO_TABLE_DRIVE** actionability class triggers when coverage-matrix repetition is high and harmful duplication is manageable
- **LOCAL** remediation mode uses extraction recommendations to guide specific refactoring
- **SPLIT** remediation mode uses subject repetition and duplication spread to recommend file splitting

See `references/scrap-scoring.md` for the full actionability and remediation framework.
