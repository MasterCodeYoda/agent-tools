# Interruptible Animation

> You should be able to immediately trigger close events without waiting for the animation to complete.

**Category**: Motion
**Source**: [detail.design](https://detail.design/detail/interruptible-animation)

## Why It Matters

Animations that block user input make interfaces feel sluggish and unresponsive. When users can interrupt ongoing animations -- for example, closing a modal mid-transition or canceling a drawer that is still opening -- the interface feels durable, snappy, and well considered. Responsiveness to user intent should always take priority over animation completion.

## How to Apply

- Never gate user actions behind animation completion. If a user clicks "close" while an open animation is running, immediately begin the close transition.
- Use interruptible animation APIs (e.g., Web Animations API with `animation.cancel()`, or CSS transitions that can be overridden mid-flight).
- In frameworks like React, track animation state and allow state changes to interrupt running animations rather than queuing them.

## Code Example

```css
/* Use CSS transitions that can be interrupted naturally */
.panel {
  transition: transform 300ms ease-out;
}

.panel.open {
  transform: translateX(0);
}

.panel.closed {
  transform: translateX(-100%);
}
```

```javascript
// Cancel running animations before starting new ones
const panel = document.querySelector('.panel');
panel.getAnimations().forEach(a => a.cancel());
panel.classList.toggle('open');
```

## Audit Checklist

- [ ] Can modals, drawers, and panels be closed mid-animation without waiting?
- [ ] Do hover/focus animations cancel cleanly when the user moves away?
- [ ] Are animation states managed so interruptions do not cause visual glitches?

## Media Reference

- Video: https://file.detail.design/interruptible-animation.mp4

---
*From [detail.design](https://detail.design) by Rene Wang*
