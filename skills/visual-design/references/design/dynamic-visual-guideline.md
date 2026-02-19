# Dynamic Visual Guideline

> Fade visual guidelines when users hover over table elements, reducing clutter while maintaining readability.

**Category**: Design
**Source**: [detail.design](https://detail.design/detail/dynamic-visual-guideline)

## Why It Matters

Tables with permanent visual guides (grid lines, zebra stripes) can feel cluttered, especially in dense data views. Fading guidelines on hover lets users focus on the specific row or cell they are interacting with while keeping the structural aids available when scanning. This balances usability with aesthetic clarity.

## How to Apply

- Create subtle visual guidelines (horizontal/vertical lines, background stripes) visible at low opacity by default.
- On row or cell hover, fade out nearby guidelines to reduce visual noise around the focus area.
- Use CSS transitions for smooth opacity changes (200ms is a good default).
- Restore guidelines when hover ends so the table remains scannable.

## Code Example

```css
.table-guideline {
  opacity: 0.3;
  transition: opacity 0.2s ease;
}

.table-row:hover .table-guideline {
  opacity: 0;
}

.table-row:hover {
  background: var(--hover-bg);
}
```

## Audit Checklist

- [ ] Do data tables reduce visual clutter on hover without removing structural aids entirely?
- [ ] Are guideline opacity transitions smooth and non-distracting?
- [ ] Is the hover row clearly highlighted against surrounding rows?

## Media Reference

- Video: https://file.detail.design/dynamic-visual-guideline.mp4
- Video (alternate): https://file.detail.design/dynamic-visual-guideline-2.mp4

---
*From [detail.design](https://detail.design) by Rene Wang. Source: Vercel, LobeHub*
