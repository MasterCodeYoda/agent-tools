# Overscroll Effect in Nested Scrollers

> Smooth edge effects for nested scrollable areas, now supported across all major browsers.

**Category**: Optimization
**Source**: [detail.design](https://detail.design/detail/overscroll-nested-scrollers)

## Why It Matters

Overscroll effects provide visual feedback when users reach scroll boundaries, creating a polished feel that communicates the limits of scrollable content. Without proper handling, nested scrollers can "chain" -- scrolling past the end of an inner container unexpectedly scrolls the outer container, creating a disorienting experience.

## How to Apply

- Apply `overscroll-behavior: contain` to nested scroll containers to prevent scroll chaining.
- This CSS property is now supported across Chrome (145+), WebKit, and Firefox.
- No JavaScript workarounds needed -- pure CSS solution.
- Apply to modal overlays, sidebars, dropdown menus, and any nested scrollable area.

## Code Example

```css
.nested-scroll-container {
  overflow-y: auto;
  overscroll-behavior: contain;
  /* Prevents scroll chaining to parent */
}

.modal-overlay {
  overflow-y: auto;
  overscroll-behavior: contain;
  /* Scrolling inside the modal won't scroll the page behind it */
}
```

## Audit Checklist

- [ ] Do nested scroll containers use `overscroll-behavior: contain`?
- [ ] Does scrolling inside modals, dropdowns, and sidebars avoid affecting the parent scroll?
- [ ] Are overscroll effects tested across Chrome, Firefox, and Safari?

## Media Reference

- Video: https://file.detail.design/overscroll-nested-scrollers.mp4

---
*From [detail.design](https://detail.design) by Rene Wang. Source: nerdy.dev*
