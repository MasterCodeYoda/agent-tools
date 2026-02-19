# Themed Favicon

> Make your favicon match your theme by serving different icon files based on the user's color scheme preference.

**Category**: Design
**Source**: [detail.design](https://detail.design/detail/themed-favicon)

## Why It Matters

Favicons are often the first visual element users see in browser tabs. A dark favicon on a dark browser tab bar (or vice versa) can disappear or clash. Adapting favicons to light and dark color schemes creates visual consistency and shows attention to detail that extends beyond the page itself.

## How to Apply

- Provide separate light and dark favicon SVG files.
- Use the `media` attribute on `<link>` tags with `prefers-color-scheme` to serve the appropriate icon.
- In Next.js, use the `metadata.icons` configuration with media queries.
- SVG favicons can use CSS media queries internally for a single-file solution.

## Code Example

```html
<!-- HTML approach -->
<link rel="icon" href="/icon-light.svg" media="(prefers-color-scheme: light)">
<link rel="icon" href="/icon-dark.svg" media="(prefers-color-scheme: dark)">
```

```javascript
// Next.js approach
export const metadata = {
  icons: {
    icon: [
      { url: '/icon-light.svg', media: '(prefers-color-scheme: light)' },
      { url: '/icon-dark.svg', media: '(prefers-color-scheme: dark)' },
    ],
  },
};
```

## Audit Checklist

- [ ] Does the favicon adapt to the user's light/dark mode preference?
- [ ] Are separate icon variants provided for both color schemes?
- [ ] Is the favicon visible and legible against both light and dark tab bar backgrounds?

## Media Reference

- Image: https://file.detail.design/themed-favicon.png

---
*From [detail.design](https://detail.design) by Rene Wang*
