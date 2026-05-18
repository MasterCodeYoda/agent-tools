# Photo Response to Theme Mode

> Almost anything on your page can respond to theme mode -- including photos and images.

**Category**: Design
**Source**: [detail.design](https://detail.design/detail/photo-response-to-theme-mode)

## Why It Matters

When switching to dark mode, a bright white photograph creates glaring contrast that undermines the purpose of the dark theme. Adapting image brightness, opacity, or even swapping image sources based on the active theme creates visual consistency and respects the user's preference for reduced eye strain.

## How to Apply

- Use `prefers-color-scheme` CSS media query to adjust image filters in dark mode.
- Consider reducing brightness slightly (e.g., `brightness(0.85)`) and lowering opacity (e.g., `0.9`) for images in dark mode.
- For critical hero images, provide separate light/dark variants and swap via `<picture>` or CSS.
- Use the HTML `<picture>` element with `media` attributes for art-directed responsive images.

## Code Example

```css
@media (prefers-color-scheme: dark) {
  img.theme-responsive {
    filter: brightness(0.85);
    opacity: 0.9;
  }
}
```

```html
<picture>
  <source srcset="hero-dark.jpg" media="(prefers-color-scheme: dark)">
  <img src="hero-light.jpg" alt="Hero image">
</picture>
```

## Audit Checklist

- [ ] Do images adapt their brightness or source for dark mode?
- [ ] Are hero/key images provided in both light and dark variants?
- [ ] Does the overall page feel visually cohesive in both theme modes?

## Media Reference

- Video: https://file.detail.design/photo-response-theme-mode.mp4

---
*From [detail.design](https://detail.design) by Rene Wang. Credit: @jh3yy*
