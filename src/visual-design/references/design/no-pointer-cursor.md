# No Pointer Cursor

> Use pointer cursor only for elements that navigate to a new page. Use default cursor for non-navigational actions.

**Category**: Design
**Source**: [detail.design](https://detail.design/detail/no-pointer-cursor)

## Why It Matters

The pointer (hand) cursor historically indicates a hyperlink that navigates somewhere. Using it for every interactive element -- buttons, toggles, checkboxes -- dilutes its meaning. Linear's approach reserves `cursor: pointer` for navigation links and uses `cursor: default` for actions, creating a clearer semantic distinction between "this takes you somewhere" and "this does something here."

## How to Apply

- Apply `cursor: pointer` only to elements that navigate to a new page or URL.
- Use `cursor: default` for buttons, toggles, form inputs, and other in-page interactive elements.
- Be consistent across the entire application.
- Ensure sufficient visual affordance (color, shape, hover states) so interactivity is clear without relying on the cursor.

## Code Example

```css
a[href] { cursor: pointer; }       /* Navigation links */
button { cursor: default; }         /* In-page actions */
input, select { cursor: default; }  /* Form controls */
.toggle { cursor: default; }        /* Toggles */
```

## Audit Checklist

- [ ] Is `cursor: pointer` reserved for navigation links only?
- [ ] Do non-navigational interactive elements use `cursor: default`?
- [ ] Is interactivity communicated through visual affordance (hover states, colors) rather than cursor alone?

## Media Reference

- Image: https://file.detail.design/media/use-pointer-cursor.png

---
*From [detail.design](https://detail.design) by Rene Wang. Source: Linear*
