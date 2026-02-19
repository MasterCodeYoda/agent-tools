# Special Cursor Style While Hovering on People

> Change the cursor to a help style when hovering over author/people sections to signal additional information is available.

**Category**: Design
**Source**: [detail.design](https://detail.design/detail/special-cursor-style-while-hovering-on-people)

## Why It Matters

Cursor changes provide immediate affordance that an element is interactive or contains additional information. Using `cursor: help` on people/author sections signals "there is more to learn here" before the user even clicks. This subtle cue guides attention and sets expectations about the interaction.

## How to Apply

- Apply `cursor: help` to author avatars, bylines, and people mentions that reveal additional info on interaction.
- Use `cursor: pointer` if clicking navigates to a profile page.
- Ensure the cursor style matches the interaction: `help` for tooltips/popovers, `pointer` for navigation.
- Pair cursor changes with hover states (opacity, underline) for redundant signaling.

## Code Example

```css
.author-section {
  cursor: help;
}

.author-section:hover {
  opacity: 0.85;
  text-decoration: underline dotted;
}
```

## Audit Checklist

- [ ] Do people/author sections use an appropriate cursor style to signal interactivity?
- [ ] Is the cursor style consistent with the type of interaction (help = info, pointer = navigate)?
- [ ] Are hover states paired with cursor changes for redundant signaling?

## Media Reference

- Video: https://file.detail.design/special-cursor-style-while-hovering-on-people.mov

---
*From [detail.design](https://detail.design) by Rene Wang. Source: Linear*
