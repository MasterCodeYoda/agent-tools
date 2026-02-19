# Prevent Layout Shift from Font Weight Change

> Use invisible pseudo-elements to reserve space for bold text, eliminating layout shifts when toggling font weights.

**Category**: Motion
**Source**: [detail.design](https://detail.design/detail/prevent-layout-shift-from-font-weight-change)

## Why It Matters

When navigation items or tabs change font weight on selection (e.g., normal to bold), the text width changes, causing surrounding elements to shift. This layout instability is jarring and makes the interface feel unpolished. Reserving space for the bold state prevents this entirely.

## How to Apply

Add a hidden `::after` pseudo-element with the bold font weight and same text content (via a `data-text` attribute). This reserves the width needed for the bold state without being visible.

## Code Example

```html
<a class="nav-link" data-text="Dashboard">Dashboard</a>
```

```css
.nav-link::after {
  content: attr(data-text);
  display: block;
  font-weight: 600;
  height: 0;
  overflow: hidden;
  visibility: hidden;
  pointer-events: none;
}
```

## Audit Checklist

- [ ] Do nav items or tabs shift layout when switching between active/inactive states?
- [ ] Is a `data-text` or equivalent technique used to reserve space for bold text?

## Media Reference

- Video: https://file.detail.design/prevent-layout-shift-from-font-weight-change.mp4

---
*From [detail.design](https://detail.design) by Rene Wang. Source: flowferry.app*
