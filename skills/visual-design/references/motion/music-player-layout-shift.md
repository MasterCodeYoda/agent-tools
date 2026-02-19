# Music Player Layout Shift

> When the album art expands, the controls slide down smoothly to make room, maintaining spatial relationships.

**Category**: Motion
**Source**: [detail.design](https://detail.design/detail/music-player-layout-shift)

## Why It Matters

Layout shifts should be choreographed, not instant. When UI elements need to reposition because a sibling expands or contracts, animating the movement preserves the user's spatial awareness. Instant jumps break the mental model of where things are, while smooth transitions help users follow the change and maintain orientation.

## How to Apply

- Animate control elements when they need to reposition due to expanding/contracting siblings.
- Use smooth CSS transitions on `transform` or layout properties rather than instant repositioning.
- Maintain the visual hierarchy during the transition so users can track which elements moved where.
- Choreograph the timing: the expanding element and the displaced elements should move in coordination.

## Code Example

```css
.controls {
  transition: transform 300ms ease-out;
}

.album-art {
  transition: height 300ms ease-out;
}

.album-art.expanded ~ .controls {
  transform: translateY(var(--expansion-height));
}
```

## Audit Checklist

- [ ] Are layout shifts caused by expanding/collapsing elements animated smoothly?
- [ ] Do displaced elements maintain their spatial relationships during transitions?
- [ ] Is the choreography coordinated between the trigger element and affected siblings?

## Media Reference

- Video: https://file.detail.design/media/music-player-layout-shift.mp4

---
*From [detail.design](https://detail.design) by Rene Wang. Source: Apple macOS Tahoe. Credit: @MarkBuildin*
