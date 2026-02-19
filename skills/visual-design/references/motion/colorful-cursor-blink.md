# Colorful Cursor Blink

> Each blink cycles through theme colors, reinforcing brand identity in an AI search input.

**Category**: Motion
**Source**: [detail.design](https://detail.design/detail/colorful-cursor-blink)

## Why It Matters

A cursor is the most frequently seen element in an input field. By cycling through brand colors on each blink, Google's AI search input signals that this is a special, AI-powered mode distinct from regular search. This small detail reinforces brand identity while adding delight without overwhelming the interface.

## How to Apply

- Target the cursor/caret element with a CSS animation that cycles through brand colors.
- Synchronize the color transition with the natural cursor blink rate.
- Use this technique sparingly -- it works best to signal a special mode or premium feature.
- Ensure the colors have sufficient contrast against the input background.

## Code Example

```css
@keyframes colorCycle {
  0%   { caret-color: #4285F4; } /* Blue */
  25%  { caret-color: #EA4335; } /* Red */
  50%  { caret-color: #FBBC05; } /* Yellow */
  75%  { caret-color: #34A853; } /* Green */
  100% { caret-color: #4285F4; } /* Blue */
}

.ai-input {
  animation: colorCycle 2s step-start infinite;
}
```

## Audit Checklist

- [ ] Does the application use visual cues to differentiate special input modes (e.g., AI-powered)?
- [ ] Are brand colors leveraged in micro-interactions where appropriate?
- [ ] Is the effect subtle enough to avoid distraction during typing?

## Media Reference

- Video: https://file.detail.design/colorful-cursor-blinking.webm

---
*From [detail.design](https://detail.design) by Rene Wang. Source: Google AI Search*
