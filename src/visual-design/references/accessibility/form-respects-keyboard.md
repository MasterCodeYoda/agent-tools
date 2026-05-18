# Form Respects Keyboard

> A form interface must be fully functional and navigable using only keyboard input.

**Category**: Accessibility
**Source**: [detail.design](https://detail.design/detail/form-respects-keyboard)

## Why It Matters

Not all users can operate a mouse due to disabilities, preferences, or assistive technology reliance. Keyboard accessibility is fundamental to inclusive design. A form that requires mouse interaction excludes users and violates WCAG accessibility standards. Every form action -- focus, input, selection, submission -- must work with keyboard alone.

## How to Apply

- Use semantic HTML elements (`<button>`, `<input>`, `<select>`, `<label>`) that are keyboard-focusable by default.
- Maintain logical tab order that matches the visual layout.
- Provide visible focus indicators for all focusable elements.
- Support standard keyboard patterns: Tab to navigate, Enter to submit, Escape to cancel, Space to toggle.
- Never remove focus outlines without providing an alternative visible indicator.
- Test the entire form flow using only the keyboard.

## Code Example

```html
<form>
  <label for="name">Full name</label>
  <input type="text" id="name" required>

  <label for="email">Email address</label>
  <input type="email" id="email" required>

  <button type="submit">Submit</button>
</form>
```

```css
/* Visible focus indicator */
:focus-visible {
  outline: 2px solid var(--accent);
  outline-offset: 2px;
}
```

## Audit Checklist

- [ ] Can the entire form be completed using only the keyboard?
- [ ] Is tab order logical and matches the visual flow?
- [ ] Are focus indicators visible on all interactive elements?
- [ ] Do Enter, Escape, Space, and Tab work as expected?
- [ ] Are custom components (dropdowns, date pickers) keyboard accessible?

## Media Reference

- Video: https://file.detail.design/form-respect-keyboard.mp4

---
*From [detail.design](https://detail.design) by Rene Wang. Credit: @alvishbaldha*
