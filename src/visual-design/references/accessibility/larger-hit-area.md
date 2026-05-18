# Larger Hit Area Than It Appears

> Design interactive elements with invisible padding that extends the clickable area beyond the visual boundary.

**Category**: Accessibility
**Source**: [detail.design](https://detail.design/detail/larger-hit-area-than-it-appears)

## Why It Matters

Based on Fitts's Law, interaction speed depends on target distance and size. Larger hit areas enable faster, more confident interactions -- especially critical for mobile accessibility and users with motor control challenges. The craft is making buttons feel generous and forgiving while looking small and refined.

## How to Apply

- For mobile: expand invisible hit areas for any element visually smaller than 44px (Apple HIG minimum).
- For desktop: apply at least 24px minimum padding around interactive targets.
- Use CSS padding, `::before`/`::after` pseudo-elements, or invisible borders to extend clickable zones.
- Maintain visual refinement by constraining the visible element's size while expanding the touch/click target.
- Test with touch devices to verify target areas feel comfortable.

## Code Example

```css
.icon-button {
  /* Visual size: 24x24 */
  width: 24px;
  height: 24px;
  position: relative;
}

.icon-button::before {
  /* Hit area: 44x44 */
  content: '';
  position: absolute;
  top: -10px;
  left: -10px;
  right: -10px;
  bottom: -10px;
}
```

## Audit Checklist

- [ ] Do all interactive elements meet the 44px minimum touch target on mobile?
- [ ] Are small visual elements (icons, close buttons) extended with invisible hit areas?
- [ ] Has the interface been tested with touch devices for comfortable targeting?

## Media Reference

- Video: https://file.detail.design/larger-hot-area-than-it-appears.mp4

---
*From [detail.design](https://detail.design) by Rene Wang. Credit: @sorenblank*
