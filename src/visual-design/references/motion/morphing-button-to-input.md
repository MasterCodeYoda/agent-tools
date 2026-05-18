# Morphing Button to Input

> A button smoothly transforms into an input field through animated morphing, guiding users from action to data entry.

**Category**: Motion
**Source**: [detail.design](https://detail.design/detail/morphing-button-to-input)

## Why It Matters

Abruptly swapping a button for an input field creates a jarring visual break. Morphing the button shape into an input field creates a cohesive narrative where the interface evolves based on user intent. This guides attention, preserves spatial context, and makes the state transition feel intentional rather than accidental.

## How to Apply

- Use CSS transitions on `width`, `border-radius`, `padding`, and `background` to smoothly transform the button shape into an input container.
- Manage component state (button vs. input) in JavaScript/framework state, triggering the morph animation on state change.
- Auto-focus the input field after the morph animation completes.
- Ensure the reverse transition (input back to button) is equally smooth, for example on blur or Escape key.

## Code Example

```css
.morphable {
  transition: width 300ms ease, border-radius 300ms ease, padding 300ms ease;
  overflow: hidden;
}

.morphable.is-button {
  width: 120px;
  border-radius: 8px;
  cursor: pointer;
}

.morphable.is-input {
  width: 280px;
  border-radius: 4px;
  padding: 8px 12px;
}
```

## Audit Checklist

- [ ] Do button-to-input transitions use smooth morphing rather than abrupt replacement?
- [ ] Is the input auto-focused after the morph completes?
- [ ] Can the user reverse the morph (e.g., Escape key or blur)?

## Media Reference

- Video: https://file.detail.design/morphing-button-to-input.mp4

---
*From [detail.design](https://detail.design) by Rene Wang. Credit: @nitishkmrk*
