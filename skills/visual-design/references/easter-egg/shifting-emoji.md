# Shifting Emoji

> A hover interaction that cycles through random emoji icons on a button, delighting users with unexpected visual changes.

**Category**: Easter Egg
**Source**: [detail.design](https://detail.design/detail/shifting-emoji)

## Why It Matters

"This is a low-cost detail that delights the user." Small, whimsical interactions create memorable experiences without significant implementation overhead. A button that shows a different emoji on each hover builds curiosity and emotional connection, making the interface feel alive and playful.

## How to Apply

- Attach a hover event listener to an emoji element.
- On each hover, select a random emoji from a curated array.
- Update the element's content with the new emoji.
- Optionally add a brief transition (opacity or scale) between changes.
- Choose an emoji set that fits the product's personality.

## Code Example

```javascript
const emojis = ['😀', '🎉', '🚀', '✨', '🎨', '💡', '🔥', '🌈'];
const button = document.querySelector('[data-emoji-button]');

button.addEventListener('mouseenter', () => {
  const random = Math.floor(Math.random() * emojis.length);
  button.textContent = emojis[random];
});
```

```css
[data-emoji-button] {
  transition: transform 150ms ease;
  cursor: default;
}

[data-emoji-button]:hover {
  transform: scale(1.1);
}
```

## Audit Checklist

- [ ] Are there low-cost delightful interactions in the UI (emoji cycling, hover surprises)?
- [ ] Do playful elements feel intentional and consistent with the brand?
- [ ] Is the implementation lightweight enough to avoid performance impact?

## Media Reference

- Video: https://file.detail.design/media/shifting-emoji-23f74fcf.mp4

---
*From [detail.design](https://detail.design) by Rene Wang. Source: Discord*
