# Shake Disabled Button While Clicking

> A disabled button shakes when clicked, providing tactile feedback that the action is not available.

**Category**: Motion
**Source**: [detail.design](https://detail.design/detail/shake-disabled-button-while-clicking)

## Why It Matters

Disabled buttons that do nothing on click leave users confused -- did the click register? Is the page broken? A subtle shake animation acknowledges the click attempt while reinforcing the disabled state. It communicates "I heard you, but this is not available right now" without words.

## How to Apply

Apply a horizontal shake animation via CSS keyframes when a disabled button receives a click event. Keep the displacement small (2-4px) and the duration short (200-300ms) so it feels like a gentle refusal rather than an error.

## Code Example

```css
@keyframes shake {
  0%, 100% { transform: translateX(0); }
  25% { transform: translateX(-4px); }
  75% { transform: translateX(4px); }
}

button:disabled:active {
  animation: shake 0.3s ease-in-out;
}
```

## Audit Checklist

- [ ] Do disabled buttons provide any visual feedback when clicked?
- [ ] Is the shake subtle enough to feel like a gentle indication rather than an error?

## Media Reference

- Video: https://file.detail.design/shake-disabled-button-while-clicking.mp4

---
*From [detail.design](https://detail.design) by Rene Wang. Credit: Aiden Y. Bai (@aidenybai)*
