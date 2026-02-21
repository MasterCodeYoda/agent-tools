# Spec Format Reference

Sentinel specs are structured markdown files that define what to test and what to expect. Each spec covers a single feature or functional area.

## File Location and Naming

Specs live in the configured `specs_dir` (default: `./specs` relative to sentinel config).

Naming convention: `{area}-{feature}.spec.md`
Examples: `checkout-payment.spec.md`, `auth-login.spec.md`, `dashboard-widgets.spec.md`

## YAML Frontmatter

Every spec file starts with YAML frontmatter:

```yaml
---
id: PAY-CHECKOUT
feature: Checkout Payment Flow
area: payments
priority: P1
dependencies:
  - AUTH-LOGIN
  - CART-ADD
---
```

### Fields

| Field | Required | Description |
|-------|----------|-------------|
| `id` | Yes | Unique identifier. Uppercase, hyphenated. Used for cross-references and run tracking. |
| `feature` | Yes | Human-readable feature name. |
| `area` | Yes | Functional area for grouping and coverage rollup (e.g., `payments`, `auth`, `catalog`). |
| `priority` | Yes | `P1` (critical path), `P2` (important), or `P3` (edge cases / nice-to-have). Determines execution order within a run. |
| `dependencies` | No | List of spec `id` values that must pass before this spec runs. Sentinel resolves these into execution order. |

## Spec Body Sections

### Context

Brief description of the feature under test and why it matters. Gives Claude enough background to understand the domain.

```markdown
## Context

The checkout payment flow handles credit card processing for customer orders.
Users reach this flow after adding items to their cart and clicking "Proceed to Checkout."
This is the primary revenue path and must work reliably across supported card types.
```

### Preconditions

State that must be true before any scenario in this spec can run. Sentinel ensures these are met before execution begins.

```markdown
## Preconditions

- User is logged in with a valid account
- At least one item exists in the shopping cart
- Test payment gateway is configured in sandbox mode
```

### Scenarios

The core of the spec. Scenarios are grouped into categories and written as checklist items with a specific format.

#### Scenario Line Format

```
- [ ] `SCENARIO-ID` Description of the action or behavior → expected result
```

The format has four parts:
- `- [ ]` — Checkbox (unchecked). Sentinel marks these `[x]` for pass or `[!]` for fail during execution.
- `` `SCENARIO-ID` `` — Unique within this spec. Convention: `{SPEC-ID-PREFIX}-{NN}` (e.g., `PAY-01`, `PAY-02`).
- **Description** — What the user does or what happens. Be specific about actions.
- **Expected result** (after `→`) — What should be observable. Must be concrete and verifiable.

#### Scenario Groups

Organize scenarios under these standard headings:

```markdown
## Scenarios

### Happy Path

Core user flows that must always work.

- [ ] `PAY-01` Enter valid Visa card (4111111111111111, future expiry, any CVV) and submit → payment succeeds, order confirmation page displays with order number
- [ ] `PAY-02` Enter valid Mastercard and submit → payment succeeds, confirmation shown

### Validation

Input validation and error handling.

- [ ] `PAY-03` Submit payment with empty card number → inline error "Card number is required" appears below the card field
- [ ] `PAY-04` Enter expired card (any past date) and submit → error message "Card has expired" is displayed, form is not submitted

### Edge Cases

Boundary conditions and unusual but valid situations.

- [ ] `PAY-05` Rapidly double-click the Pay button → only one payment is processed, no duplicate charges
- [ ] `PAY-06` Navigate away during payment processing and return → payment status is resolved (success or clear error), no stuck spinner
```

### Test Data

Specific data values needed for scenarios. Keeps test data close to the scenarios that use it.

```markdown
## Test Data

| Label | Value | Notes |
|-------|-------|-------|
| Valid Visa | 4111111111111111 | Standard Stripe/Braintree test number |
| Valid Mastercard | 5555555555554444 | Standard test number |
| Expired date | 01/2020 | Any past month/year |
| Valid CVV | 123 | Any 3-digit number for test cards |
| Test user | qa-buyer@example.com | Pre-seeded account with items in cart |
```

### Notes

Optional section for anything that doesn't fit elsewhere — known issues, environment constraints, related specs.

```markdown
## Notes

- Payment gateway must be in sandbox/test mode. Live credentials will process real charges.
- The double-click guard (PAY-05) was added after incident INC-2024-087.
- Related specs: CART-ADD (dependency), ORDER-HISTORY (downstream).
```

## Complete Example (Good)

```markdown
---
id: PAY-CHECKOUT
feature: Checkout Payment Flow
area: payments
priority: P1
dependencies:
  - AUTH-LOGIN
  - CART-ADD
---

## Context

The checkout payment flow handles credit card processing for customer orders.
Users reach this flow after adding items to their cart and clicking "Proceed to Checkout."
This is the primary revenue path and must work reliably across supported card types.

## Preconditions

- User is logged in with a valid account (qa-buyer@example.com)
- At least one item exists in the shopping cart
- Payment gateway is in sandbox mode

## Scenarios

### Happy Path

- [ ] `PAY-01` Enter valid Visa (4111111111111111, exp 12/2028, CVV 123) and click "Pay Now" → order confirmation page loads with order number starting with "ORD-"
- [ ] `PAY-02` Enter valid Mastercard (5555555555554444, exp 12/2028, CVV 456) and click "Pay Now" → payment succeeds, confirmation page shows correct order total

### Validation

- [ ] `PAY-03` Leave card number empty and click "Pay Now" → inline error "Card number is required" appears, payment is not submitted
- [ ] `PAY-04` Enter card with past expiration (01/2020) and click "Pay Now" → error "Card has expired" is shown, form remains on payment page
- [ ] `PAY-05` Enter card number with only 8 digits and click "Pay Now" → inline error "Invalid card number" appears

### Edge Cases

- [ ] `PAY-06` Double-click "Pay Now" rapidly with valid card details → only one charge is created, confirmation page shows single order
- [ ] `PAY-07` Fill in valid card, disconnect network, click "Pay Now" → error message about connection failure, no partial charge

## Test Data

| Label | Value | Notes |
|-------|-------|-------|
| Valid Visa | 4111111111111111 | Stripe test card |
| Valid Mastercard | 5555555555554444 | Stripe test card |
| Test user | qa-buyer@example.com | Password in QA_BUYER_PASS env var |

## Notes

- All test card numbers are Stripe sandbox numbers. They will not work against live payment endpoints.
- PAY-07 requires network condition emulation via Chrome DevTools.
```

## Bad Example (Common Mistakes)

```markdown
---
id: payment
feature: Payment
area: payments
priority: high
---

## Scenarios

- [ ] Test payment works
- [ ] Check validation
- [ ] Try edge cases
- [ ] Make sure errors show up
```

**What's wrong:**

| Problem | Why it matters |
|---------|----------------|
| `id` is lowercase, non-standard | Breaks cross-referencing and run file matching |
| `priority` uses "high" instead of P1/P2/P3 | Not machine-parseable, inconsistent with other specs |
| No scenario IDs | Cannot track individual scenario results across runs |
| No expected results (missing `→`) | Claude cannot judge pass/fail without knowing what to expect |
| Vague descriptions ("test payment works") | Not actionable — what card? what flow? what does "works" mean? |
| Missing Context, Preconditions, Test Data | Claude has to guess the setup, leading to flaky or incorrect execution |
| No scenario grouping | Hard to prioritize and report on categories of coverage |

## What Makes a Good Spec

1. **Specific expected results** — Every scenario states exactly what should be observable after the action. "Payment succeeds" is vague; "order confirmation page loads with order number starting with ORD-" is testable.

2. **Concrete actions** — Scenarios describe exactly what to do: which button to click, what value to enter, which page to navigate to. Claude should not have to guess the interaction steps.

3. **Clear preconditions** — State required before testing begins is documented, including test accounts, data setup, and environment configuration.

4. **Unique, trackable IDs** — Every spec and scenario has an ID that survives across runs, enabling regression tracking over time.

5. **Appropriate scope** — One spec per feature. If a spec has more than ~15 scenarios, consider splitting it into sub-features.
