# Stagger for Event Order

> When multiple elements move at once, attention splits. A stagger creates a clear order of events so the eye knows where to look next.

**Category**: Motion
**Source**: [detail.design](https://detail.design/detail/stagger-for-the-event-order)

## Why It Matters

Simultaneous animations on multiple elements compete for attention and create visual chaos. Staggering introduces temporal hierarchy -- each element enters in sequence, guiding the user's eye through a deliberate order. This reduces cognitive load and makes the interface feel more intentional and polished.

## How to Apply

- Apply incrementally increasing animation delays to grouped elements.
- Use consistent delay intervals, typically 50-150ms between elements.
- Maintain consistent animation duration across all staggered items.
- Apply to entrance animations, list item reveals, notification stacks, or any multi-element transition.

## Code Example

```css
.item {
  animation: slideIn 0.4s ease-out forwards;
  opacity: 0;
}

.item:nth-child(1) { animation-delay: 0ms; }
.item:nth-child(2) { animation-delay: 100ms; }
.item:nth-child(3) { animation-delay: 200ms; }
.item:nth-child(4) { animation-delay: 300ms; }

@keyframes slideIn {
  from { opacity: 0; transform: translateY(20px); }
  to { opacity: 1; transform: translateY(0); }
}
```

## Audit Checklist

- [ ] Do lists, grids, or grouped elements animate with staggered delays rather than all at once?
- [ ] Is the stagger interval consistent (50-150ms) and the total duration reasonable?
- [ ] Does the stagger order match the intended reading/scanning direction?

## Media Reference

- Video: https://file.detail.design/stagger-for-the-order.mp4

---
*From [detail.design](https://detail.design) by Rene Wang. Credit: @bartek_marzec*
