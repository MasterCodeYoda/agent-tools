# Keep Entry of Active View Visible

> The currently active list item should always remain visible, providing spatial awareness and orientation.

**Category**: Design
**Source**: [detail.design](https://detail.design/detail/keep-entry-of-active-view-visible)

## Why It Matters

When users navigate through list views, losing sight of the active item causes disorientation. Users need to maintain context about where they are in the list. Automatically scrolling the active entry into view preserves spatial awareness and reduces the cognitive load of re-finding their place.

## How to Apply

- Track which entry is currently active or selected.
- When the active entry moves off-screen (due to scrolling or navigation), use `scrollIntoView` to bring it back.
- Apply visual distinction (highlight, background color, border) to the active entry.
- Use `block: 'nearest'` to minimize unnecessary scroll displacement.

## Code Example

```javascript
// Keep active entry visible when selection changes
const activeEntry = document.querySelector('.list-item.active');
activeEntry.scrollIntoView({
  behavior: 'smooth',
  block: 'nearest'
});
```

```css
.list-item.active {
  background: var(--active-bg);
  border-left: 3px solid var(--accent);
}
```

## Audit Checklist

- [ ] Does the active list item remain visible when navigating with keyboard or programmatic selection?
- [ ] Is `scrollIntoView` with `block: 'nearest'` used to minimize unnecessary scrolling?
- [ ] Is the active item visually distinct from inactive items?

## Media Reference

- Video: https://file.detail.design/keep-entry-of-active-view-visiable.mov

---
*From [detail.design](https://detail.design) by Rene Wang. Source: Linear*
