# Anchored Scrolling

> A stable visual anchor and a clear sense of boundary when navigating long lists, keeping input fields fixed.

**Category**: Design
**Source**: [detail.design](https://detail.design/detail/anchored-scrolling)

## Why It Matters

In command palettes and long menus, the highlighted item should guide scrolling behavior. Rather than scrolling the entire list uniformly, anchored scrolling locks the highlight in place at ~70% viewport height and scrolls the list beneath it. This creates a more intentional and controlled navigation feel. The input field should remain independently anchored so its position never shifts.

## How to Apply

- Start with highlight movement only (no scroll) while the selected item is in the visible viewport.
- At approximately 70% down the viewport, lock the highlight position and begin scrolling the list beneath it.
- Keep input fields anchored independently so their position is constant regardless of list length.
- Release the anchor at the end of the list to allow focus on the final item.
- Apply this pattern to any CMDK-style menu or command palette.

## Code Example

```javascript
// Anchor-aware scroll for command palette
function handleNavigation(selectedIndex, items, container) {
  const item = items[selectedIndex];
  const containerRect = container.getBoundingClientRect();
  const itemRect = item.getBoundingClientRect();
  const threshold = containerRect.height * 0.7;

  if (itemRect.top - containerRect.top > threshold) {
    container.scrollTop += itemRect.height;
  }
}
```

## Audit Checklist

- [ ] Do command palettes and long menus use anchored scrolling?
- [ ] Is the input field position fixed regardless of list scroll state?
- [ ] Does the highlight lock at a consistent viewport position during scrolling?

## Media Reference

- Video: https://file.detail.design/media/anchored-scrolling-c7e97f7b.mov

---
*From [detail.design](https://detail.design) by Rene Wang. Source: Raycast*
