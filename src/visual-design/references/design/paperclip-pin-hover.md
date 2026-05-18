# Paperclip Pin Hover

> A paperclip icon represents a pinned tab; it opens on hover to signal the unpinning action.

**Category**: Design
**Source**: [detail.design](https://detail.design/detail/paperclip-pin-hover)

## Why It Matters

Thoughtful iconography communicates both state and action simultaneously. A closed paperclip naturally represents something held in place (pinned), while an opening animation on hover provides immediate visual feedback about what clicking will do (unpin). This replaces the traditional pushpin metaphor with something more intuitive -- paperclips naturally hold items temporarily, mirroring how pinned tabs function.

## How to Apply

- Use an SVG paperclip icon with two states: closed (pinned) and open (hover/unpin).
- Animate the transition between states on hover using CSS or JavaScript.
- Ensure the animation timing is smooth and provides clear cause-and-effect feedback.
- Apply this principle broadly: icons should communicate both current state and available action.

## Code Example

```css
.paperclip-icon {
  transition: transform 200ms ease;
}

.paperclip-icon .clip-arm {
  transform-origin: top center;
  transition: transform 200ms ease;
}

.pin-button:hover .clip-arm {
  transform: rotate(-30deg); /* Opens the paperclip */
}
```

## Audit Checklist

- [ ] Do pin/unpin icons communicate both state and action?
- [ ] Does the icon animate on hover to preview the action?
- [ ] Is the metaphor intuitive (paperclip = temporary hold)?

## Media Reference

- Video: https://file.detail.design/pin-and-unpin-icon.mp4

---
*From [detail.design](https://detail.design) by Rene Wang. Source: Obsidian Velocity theme*
