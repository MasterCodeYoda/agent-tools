# Poll Item Word Counter

> A checkbox morphs into a circular word counter as users type poll item text, providing real-time feedback.

**Category**: Design
**Source**: [detail.design](https://detail.design/detail/poll-item-word-counter)

## Why It Matters

This micro-interaction provides real-time visual feedback while maintaining interface simplicity. Instead of adding a separate character count element, the existing checkbox transforms into a progress ring -- communicating character limits without additional UI clutter. It is a clever reuse of existing space that adds functionality without complexity.

## How to Apply

- Detect input changes in text fields with character limits.
- Transform an adjacent UI element (checkbox, icon) into a circular progress indicator.
- Display the remaining character count within the ring.
- Update the ring fill proportionally as the count approaches the limit.
- Change the ring color to warn when approaching or exceeding the limit.

## Code Example

```css
.counter-ring {
  width: 24px;
  height: 24px;
  border-radius: 50%;
  background: conic-gradient(
    var(--accent) calc(var(--progress) * 360deg),
    transparent 0
  );
  display: grid;
  place-items: center;
  font-size: 10px;
}
```

```javascript
input.addEventListener('input', (e) => {
  const progress = e.target.value.length / MAX_LENGTH;
  ring.style.setProperty('--progress', progress);
  ring.textContent = MAX_LENGTH - e.target.value.length;
});
```

## Audit Checklist

- [ ] Do text inputs with character limits provide real-time visual feedback?
- [ ] Is the character count indicator integrated into existing UI rather than added as separate clutter?
- [ ] Does the indicator warn when approaching or exceeding the limit?

## Media Reference

- Video: https://file.detail.design/poll-item-word-count.mp4

---
*From [detail.design](https://detail.design) by Rene Wang. Credit: @ridd_design*
