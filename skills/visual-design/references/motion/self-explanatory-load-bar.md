# Self-Explanatory Load Bar

> A restrained animation using a load bar to trigger a switch, making the interaction's intent immediately clear without decorative flourishes.

**Category**: Motion
**Source**: [detail.design](https://detail.design/detail/self-explanatory-load-bar)

## Why It Matters

Animation should serve communication, not decoration. A load bar that visually connects to the action it triggers -- such as filling up to activate a toggle -- makes the interaction self-explanatory. Users understand both what is happening and why, without needing labels or instructions. This is restraint in service of clarity.

## How to Apply

- Pair progress indicators with the interactive elements they control (e.g., a load bar that fills along a toggle track).
- Use animation to create spatial context and tactile feel rather than purely visual flair.
- Keep the motion restrained -- the bar filling is the message; no bouncing or overshooting needed.
- Connect the completion of the progress bar to the state change so timing feels synchronized.

## Code Example

```css
.load-bar {
  width: 0%;
  height: 4px;
  background: var(--accent);
  transition: width 1.5s linear;
}

.load-bar.filling {
  width: 100%;
}

.toggle.activated {
  transition: background 200ms ease;
  background: var(--accent);
}
```

## Audit Checklist

- [ ] Do loading animations communicate the purpose of the wait?
- [ ] Are progress indicators visually connected to the element they affect?
- [ ] Is animation restrained and functional rather than decorative?

## Media Reference

- Video: https://file.detail.design/self-explanatory-load-bar.mp4

---
*From [detail.design](https://detail.design) by Rene Wang. Credit: @bartek_marzec*
