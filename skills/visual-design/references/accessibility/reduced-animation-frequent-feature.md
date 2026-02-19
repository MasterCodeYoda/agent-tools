# Reduced Animation for Frequently Used Features

> Minimize animation delays for frequently-used interactions to prioritize productivity over delight.

**Category**: Accessibility
**Source**: [detail.design](https://detail.design/detail/reduced-animation-for-frequently-used-feature)

## Why It Matters

When someone opens a productivity tool, they have a specific goal. Excessive animations feel gratuitous and slow down workflows in utility-first applications. Respecting `prefers-reduced-motion` is not just accessibility compliance -- it is a design philosophy: animation should serve the user, not the designer. For frequent interactions, snappier is always better.

## How to Apply

- Use `prefers-reduced-motion` media query to respect user accessibility preferences.
- Apply minimal transition durations (50-150ms) for frequently-used interactions.
- Reserve longer, more expressive animations for onboarding, first-run experiences, or exploratory features.
- Consider the context: productivity tools need snappier feedback than marketing sites.
- Test with `prefers-reduced-motion: reduce` enabled to ensure the app remains fully functional.

## Code Example

```css
/* Full animation for users who want it */
@media (prefers-reduced-motion: no-preference) {
  .quick-action {
    transition: all 200ms ease-out;
  }
}

/* Reduced or no animation for accessibility */
@media (prefers-reduced-motion: reduce) {
  .quick-action {
    transition: none;
  }

  /* Or minimal transition */
  .subtle-action {
    transition: opacity 50ms ease;
  }
}
```

## Audit Checklist

- [ ] Is `prefers-reduced-motion` respected for all animations?
- [ ] Are frequently-used interaction animations kept under 150ms?
- [ ] Does the app remain fully functional with animations disabled?
- [ ] Are longer animations reserved for non-critical, exploratory interactions?

## Media Reference

- Source: Raycast

---
*From [detail.design](https://detail.design) by Rene Wang*
