# Animated Action Button

> An action button with purposeful animation that reinforces the interaction and guides user attention.

**Category**: Motion
**Source**: [detail.design](https://detail.design/detail/animated-action-button)

## Why It Matters

Static buttons communicate function but not feedback. An animated action button provides immediate visual confirmation that the user's intent was received, creating a more engaging and responsive feel. The animation should reinforce the action's meaning -- for example, a send button that animates upward, or a delete button that shrinks away.

## How to Apply

- Add micro-animations to primary action buttons that visually echo the action being performed.
- Keep animations under 400ms to maintain a snappy feel.
- Use spring or ease-out curves for natural motion.
- Ensure the animation does not block the next user action (see: interruptible animation).
- Provide a disabled or loading state animation for async actions.

## Code Example

```css
.action-button {
  transition: transform 200ms ease-out, box-shadow 200ms ease-out;
}

.action-button:active {
  transform: scale(0.95);
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.2);
}

.action-button.success {
  animation: pulse 400ms ease-out;
}

@keyframes pulse {
  0% { transform: scale(1); }
  50% { transform: scale(1.05); }
  100% { transform: scale(1); }
}
```

## Audit Checklist

- [ ] Do primary action buttons provide animated feedback on click?
- [ ] Are button animations short enough (<400ms) to feel responsive?
- [ ] Does the animation reinforce the semantic meaning of the action?

## Media Reference

- Video: https://file.detail.design/animated-action-button.mp4

---
*From [detail.design](https://detail.design) by Rene Wang. Credit: @rndr_realm*
