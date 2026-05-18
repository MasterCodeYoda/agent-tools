# Outer and Inner Border Radius

> Use distinct outer and inner border-radius values for nested elements to create visually harmonious rounded corners.

**Category**: Design
**Source**: [detail.design](https://detail.design/detail/outer-and-inner-border-radius)

## Why It Matters

When a rounded container holds a rounded child element, using the same border-radius on both creates an uneven visual gap between the curves. The correct approach is to reduce the inner element's radius by the padding amount: `inner-radius = outer-radius - padding`. This creates concentric curves that feel visually harmonious and intentional.

## How to Apply

- Calculate inner border-radius as: `outer-radius - gap/padding`.
- If the outer container has `border-radius: 16px` and `padding: 8px`, the inner element should use `border-radius: 8px`.
- Apply this rule to cards within cards, buttons within containers, and any nested rounded elements.
- Use CSS custom properties to maintain the relationship programmatically.

## Code Example

```css
:root {
  --outer-radius: 16px;
  --padding: 8px;
  --inner-radius: calc(var(--outer-radius) - var(--padding));
}

.card {
  border-radius: var(--outer-radius);
  padding: var(--padding);
}

.card-inner {
  border-radius: var(--inner-radius);
}
```

## Audit Checklist

- [ ] Do nested rounded elements use concentric radius values (outer - padding = inner)?
- [ ] Is the relationship maintained via CSS custom properties for consistency?
- [ ] Do cards-within-cards avoid using identical border-radius values?

## Media Reference

- Image: https://file.detail.design/outer-and-inner-border-radius.jpeg

---
*From [detail.design](https://detail.design) by Rene Wang. Credit: @evilrabbit_*
