# Active State Also Works in Footer

> Apply active state styling to footer navigation links, not just the primary nav, for consistent spatial awareness.

**Category**: Design
**Source**: [detail.design](https://detail.design/detail/active-state-also-works-in-footer)

## Why It Matters

Footer navigation often receives less attention than primary navigation, yet users reference it to reorient themselves. Consistent active state styling in the footer reinforces where users currently are in the site hierarchy, maintaining visual consistency across the entire interface and reducing cognitive load.

## How to Apply

- Apply the same active state logic used in primary navigation to footer links.
- Use consistent visual indicators: color change, underline, font weight, background highlight.
- Compare the current URL against link `href` to determine active state.
- Ensure sufficient contrast for accessibility compliance.
- Keep the styling treatment consistent between header and footer nav.

## Code Example

```html
<footer>
  <nav>
    <a href="/details" class="active" aria-current="page">Details</a>
    <a href="/resources">Resources</a>
    <a href="/about">About</a>
  </nav>
</footer>
```

```css
footer a.active,
footer a[aria-current="page"] {
  color: var(--text-primary);
  font-weight: 500;
  border-bottom: 2px solid currentColor;
}
```

## Audit Checklist

- [ ] Does the footer navigation show active state styling for the current page?
- [ ] Is the active state treatment consistent between header and footer nav?
- [ ] Is `aria-current="page"` used for accessibility?

## Media Reference

- Image: https://file.detail.design/media/active-state-also-works-in-footer-57095df0.png

---
*From [detail.design](https://detail.design) by Rene Wang*
