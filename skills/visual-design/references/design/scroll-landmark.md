# Scroll Landmark

> A cross-platform scroll-to-top shortcut that remembers your previous position so you can return to it.

**Category**: Design
**Source**: [detail.design](https://detail.design/detail/scroll-landmark)

## Why It Matters

iOS's tap-status-bar-to-scroll-top is platform-specific and one-directional -- you can go to the top but cannot return to where you were. A scroll landmark feature stores the previous scroll position before jumping to top, allowing users to navigate back. This transforms a simple shortcut into a powerful two-way navigation tool.

## How to Apply

- Store the current scroll position before executing scroll-to-top.
- Provide a visible UI element (floating button or gesture zone) to trigger the action.
- After scrolling to top, offer an inverse action to restore the previous position.
- Animate the scroll with smooth behavior for spatial continuity.
- Make this work cross-platform, not just on iOS.

## Code Example

```javascript
let savedScrollPosition = 0;

function scrollToTopWithLandmark() {
  savedScrollPosition = window.scrollY;
  window.scrollTo({ top: 0, behavior: 'smooth' });
  showReturnButton();
}

function returnToLandmark() {
  window.scrollTo({ top: savedScrollPosition, behavior: 'smooth' });
  hideReturnButton();
}
```

## Audit Checklist

- [ ] Is there a scroll-to-top shortcut available on all platforms?
- [ ] Does the shortcut remember the previous scroll position for easy return?
- [ ] Is the scroll animated smoothly?

## Media Reference

- Video: https://file.detail.design/scroll-landmark.mp4

---
*From [detail.design](https://detail.design) by Rene Wang. Credit: Rauno Freiberg (@raunofreiberg)*
