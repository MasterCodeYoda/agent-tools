# Closing Modal Respects Physics

> When closing an expanded item from a grid, the element returns to its original position while respecting scroll momentum, tracking smoothly like a magnet.

**Category**: Motion
**Source**: [detail.design](https://detail.design/detail/closing-modal-respect-physics)

## Why It Matters

When a user scrolls the page while a modal is closing, naive implementations ignore the new scroll position and animate the element to a stale location. This breaks the spatial relationship between the modal and its origin. By continuously tracking the original element's position during the close animation, the transition feels physical and natural -- like the element is magnetically returning home.

## How to Apply

- Track the original grid item's viewport position before expansion.
- Monitor scroll events during the closing animation and continuously update the animation target.
- Use physics-based animation (spring/momentum) rather than linear timing for the return transition.
- Calculate the final position in real-time as the user scrolls so the element always lands on its origin.

## Code Example

```javascript
// Pseudo-code for physics-respecting modal close
function closeModal(modalEl, originEl) {
  const animate = () => {
    const originRect = originEl.getBoundingClientRect();
    // Update target position each frame to track scroll changes
    modalEl.style.transform = `translate(${originRect.x}px, ${originRect.y}px)`;
    if (!animationComplete) requestAnimationFrame(animate);
  };
  requestAnimationFrame(animate);
}
```

## Audit Checklist

- [ ] Does the close animation track the origin element's position if the page scrolls during transition?
- [ ] Are physics-based (spring) animations used instead of linear easing?

## Media Reference

- Video: https://file.detail.design/closing-modal-follow-physics.mp4

---
*From [detail.design](https://detail.design) by Rene Wang. Source: Apple Music*
