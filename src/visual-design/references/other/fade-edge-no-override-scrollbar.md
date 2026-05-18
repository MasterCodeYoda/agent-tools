# Fade Edge Does Not Override Scrollbar

> When adding fade-out gradients to scrollable containers, ensure they do not visually obstruct the scrollbar.

**Category**: Scroll
**Source**: [detail.design](https://detail.design/detail/fade-edge-doesnt-override-scrollbar)

## Why It Matters

Fade edges create a polished visual effect by gradually obscuring content at container boundaries. But when applied carelessly, the gradient overlay renders scrollbars invisible or inaccessible. Users lose the visual cue that content is scrollable, and on some platforms they cannot interact with the scrollbar at all.

## How to Apply

- Calculate the scrollbar width for the target platform (varies by OS and browser).
- Set the fade gradient's ending position to stop before the scrollbar area.
- Account for custom scrollbar widths if using `::-webkit-scrollbar` styling.
- Test across platforms: macOS overlays scrollbars (may not matter), Windows shows persistent scrollbars (must account for).
- Use `scrollbar-gutter: stable` to reserve space for the scrollbar consistently.

## Code Example

```css
.scrollable {
  position: relative;
  overflow-y: auto;
  scrollbar-gutter: stable;
}

.scrollable::after {
  content: '';
  position: sticky;
  bottom: 0;
  display: block;
  height: 40px;
  /* Stop gradient before scrollbar */
  width: calc(100% - 16px); /* 16px = typical scrollbar width */
  background: linear-gradient(transparent, var(--bg-color));
  pointer-events: none;
}
```

## Audit Checklist

- [ ] Do fade-edge gradients on scrollable containers avoid overlapping the scrollbar?
- [ ] Has the scrollbar width been accounted for across target platforms?
- [ ] Is `scrollbar-gutter: stable` used to prevent layout shift?

## Media Reference

- Video: https://file.detail.design/fade-edge-doesnt-override-scrollbar.mp4

---
*From [detail.design](https://detail.design) by Rene Wang*
