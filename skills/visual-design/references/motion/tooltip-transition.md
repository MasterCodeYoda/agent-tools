# Tooltip Transition in a Group

> Animate the transition between two open tooltips for a smooth, continuous experience.

**Category**: Motion
**Source**: [detail.design](https://detail.design/detail/tooltip-in-a-group)

## Why It Matters

When users hover across grouped interactive elements, having each tooltip pop in and out independently creates visual noise. Smoothly transitioning the tooltip position and content between elements maintains interface continuity and makes the interaction feel polished rather than fragmented.

## How to Apply

- When a tooltip is already visible and the user moves to an adjacent element, animate the tooltip's position to the new target instead of hiding and re-showing.
- Use a shared tooltip container that repositions, rather than individual tooltip instances per element.
- Implement a brief hover delay (50-100ms) before switching targets to prevent flickering during fast mouse movement.
- Animate both position and content opacity for smooth handoffs.

## Code Example

```css
.tooltip {
  position: absolute;
  transition: left 200ms ease, top 200ms ease, opacity 150ms ease;
  pointer-events: none;
}
```

```javascript
// Shared tooltip that moves between targets
groupElements.forEach(el => {
  el.addEventListener('mouseenter', () => {
    tooltip.textContent = el.dataset.tooltip;
    const rect = el.getBoundingClientRect();
    tooltip.style.left = `${rect.left + rect.width / 2}px`;
    tooltip.style.top = `${rect.top - 8}px`;
    tooltip.style.opacity = '1';
  });
});
```

## Audit Checklist

- [ ] Do grouped tooltips transition smoothly between elements instead of popping in/out?
- [ ] Is there a hover delay to prevent tooltip flickering?

## Media Reference

- Video: https://file.detail.design/media/tooltip-in-a-group-9d36264d.mp4
- Video (alternate): https://file.detail.design/tooltip-in-a-group-2.mp4

---
*From [detail.design](https://detail.design) by Rene Wang. Seen at: Notion, Rauno.me*
