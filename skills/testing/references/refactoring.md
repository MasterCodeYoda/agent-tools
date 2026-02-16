# Refactoring Under Tests

How to improve code structure safely when tests protect behavior.

## When to Refactor

Refactor **after Green, before the next Red**. The cycle is:

```
RED → GREEN → REFACTOR → RED → GREEN → REFACTOR → ...
```

**After Green** because you have passing tests that verify current behavior. Any refactoring that breaks a test has changed behavior, not just structure.

**Before the next Red** because refactoring with a failing test means you're changing behavior and structure simultaneously — a recipe for confusion.

## The Refactoring Rule

> If your tests break during refactoring, you changed behavior.

Tests should be on the **public interface**. Refactoring operates **below** that interface. As long as inputs and outputs stay the same, tests stay green.

```
// Before refactoring
function calculateTotal(items):
  total = 0
  for item in items:
    total += item.price * item.quantity
  return total

// After refactoring — same interface, same behavior
function calculateTotal(items):
  return items
    .map(item => item.price * item.quantity)
    .reduce((a, b) => a + b, 0)

// Tests don't change — they test the outcome, not the loop style
```

## Code Smells That Signal Refactoring

### Duplication

The same logic appears in multiple places. Extract it.

```
// Before: duplicated discount logic
function orderTotal(items):
  subtotal = sum(items.map(i => i.price))
  if subtotal > 100: return subtotal * 0.9
  return subtotal

function quoteTotal(items):
  subtotal = sum(items.map(i => i.price))
  if subtotal > 100: return subtotal * 0.9
  return subtotal

// After: extracted
function applyDiscount(subtotal):
  if subtotal > 100: return subtotal * 0.9
  return subtotal

function orderTotal(items):
  return applyDiscount(sum(items.map(i => i.price)))
```

### Long Methods

A method doing too much. Split into focused methods with clear names.

**Signal:** You need comments to explain sections of the method. Each comment-worthy section is likely a separate method.

### Shallow Modules

Many small classes or functions that do almost nothing individually. Combine related ones into deeper modules with more substantial behavior behind simpler interfaces.

### Feature Envy

A method that uses more data from another class than its own. Move it closer to the data it operates on.

```
// Feature envy: Order knows too much about Discount
function applyDiscount(order):
  if order.discount.type == "percentage":
    return order.total * (1 - order.discount.rate)
  if order.discount.type == "fixed":
    return order.total - order.discount.amount

// Better: let Discount handle its own logic
function applyDiscount(order):
  return order.discount.applyTo(order.total)
```

### Primitive Obsession

Using primitive types (strings, ints) where a domain concept exists.

```
// Primitive obsession
function createUser(email: string):
  if not email.contains("@"): raise Error
  // ... more email validation scattered around

// Better: domain type
class Email:
  constructor(value: string):
    if not value.contains("@"): raise InvalidEmail
    this.value = value

function createUser(email: Email):
  // Email is always valid by construction
```

## Key Refactoring Moves

### Extract

Pull a section of code into its own function or class.

**When:** A method does multiple things, or the same logic appears twice.

**Safety check:** Existing tests still pass without modification.

### Combine

Merge shallow modules that are always used together into a deeper module.

**When:** Multiple functions are always called in sequence, or small classes delegate to each other without adding value.

**Safety check:** Tests on the combined public interface still pass.

### Deepen

Make a module's interface simpler while its implementation handles more.

**When:** Callers need to coordinate multiple method calls to achieve one result.

```
// Shallow: callers must coordinate
parser.setInput(text)
parser.tokenize()
ast = parser.buildTree()
result = parser.evaluate(ast)

// Deep: simple interface, complex internals
result = parser.evaluate(text)
```

**Safety check:** Caller-side tests simplify; internal behavior tests stay green.

### Move

Relocate a method or class to where it belongs — closer to the data it operates on, or into the module it conceptually belongs to.

**When:** Feature envy, or a function that doesn't fit its current location.

**Safety check:** Behavior tests pass; only import paths change.

## Refactoring Workflow

1. **Identify** — Spot the smell or improvement opportunity
2. **Verify** — All tests are green before starting
3. **Apply** — Make one small structural change
4. **Run tests** — Confirm all tests still pass
5. **Repeat** — Continue with the next small change

Keep each step small. If you can't get back to green quickly, revert and try a smaller step.

**Never refactor and add behavior in the same step.** If you need new behavior, write a failing test first (Red), then implement (Green), then refactor.
