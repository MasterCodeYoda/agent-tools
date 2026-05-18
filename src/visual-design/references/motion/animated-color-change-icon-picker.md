# Animated Color Change in Icon Picker

> When you change the color, the icon color shifts sequentially from one to the next instead of all at once.

**Category**: Motion
**Source**: [detail.design](https://detail.design/detail/animated-color-change-in-icon-picker)

## Why It Matters

Instantaneous color changes feel mechanical and abrupt. By staggering the transition so colors shift sequentially across the icon, the interaction feels organic and intentional. This kind of polish signals that every detail has been considered, elevating perceived product quality.

## How to Apply

- Instead of updating all color stops simultaneously, stagger them with sequential animation delays.
- Use CSS transitions or JavaScript animation libraries to cascade the color change from one element to the next.
- Keep transition durations short (150-300ms per element) so the effect feels lively, not slow.
- View at 0.5x speed during development to fine-tune the cascade timing.

## Code Example

```css
.icon-part {
  transition: fill 200ms ease;
}

.icon-part:nth-child(1) { transition-delay: 0ms; }
.icon-part:nth-child(2) { transition-delay: 50ms; }
.icon-part:nth-child(3) { transition-delay: 100ms; }
.icon-part:nth-child(4) { transition-delay: 150ms; }
```

## Audit Checklist

- [ ] Do color picker changes animate smoothly rather than snapping instantly?
- [ ] Is the color transition staggered across icon elements for a sequential effect?

## Media Reference

- Video: https://file.detail.design/color-transition-in-icon-picker.mp4

---
*From [detail.design](https://detail.design) by Rene Wang. Source: Linear*
