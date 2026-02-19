# Text Overflow Cutoff

> Use gradient fading and ellipsis for elegant text truncation in fixed-width elements like tabs.

**Category**: Typography
**Source**: [detail.design](https://detail.design/detail/text-overflow-cutoff)

## Why It Matters

Fixed-width containers (tabs, sidebars, breadcrumbs) frequently encounter text that exceeds available space. Abrupt clipping looks broken; an ellipsis alone feels utilitarian. Combining a gradient fade with an ellipsis creates an elegant truncation that signals "there is more" while maintaining visual polish.

## How to Apply

- Apply `text-overflow: ellipsis` with `overflow: hidden` and `white-space: nowrap` for basic truncation.
- For enhanced polish, add a gradient text mask that fades the text from opaque to transparent near the edge.
- Align the gradient endpoint with the ellipsis position.
- Provide the full text on hover via a tooltip.
- Use `title` attribute or custom tooltip for accessibility.

## Code Example

```css
/* Basic ellipsis truncation */
.tab-label {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  max-width: 150px;
}

/* Enhanced gradient fade */
.tab-label-gradient {
  position: relative;
  overflow: hidden;
  white-space: nowrap;
  max-width: 150px;
}

.tab-label-gradient::after {
  content: '';
  position: absolute;
  right: 0;
  top: 0;
  bottom: 0;
  width: 40px;
  background: linear-gradient(to right, transparent, var(--bg-color));
}
```

## Audit Checklist

- [ ] Is text truncation handled gracefully in fixed-width containers?
- [ ] Is the full text accessible on hover (tooltip or `title` attribute)?
- [ ] Is the truncation style (ellipsis, gradient, or both) consistent across the app?

## Media Reference

- Video: https://file.detail.design/text-cutoff.mp4

---
*From [detail.design](https://detail.design) by Rene Wang. Credit: @define_app*
