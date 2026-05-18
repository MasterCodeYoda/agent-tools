# CSS Text-Box Trim

> Remove extra space above and below text for predictable, pixel-perfect spacing using the CSS `text-box-trim` property.

**Category**: Typography
**Source**: [detail.design](https://detail.design/detail/css-text-box-trim)

## Why It Matters

Designers have long struggled with the invisible browser spacing above capital letters and below baselines. This extra space makes vertical alignment with adjacent elements inconsistent and forces workarounds with negative margins. `text-box-trim` enables developers to trim this space for predictable, design-tool-matching layouts.

## How to Apply

- Apply `text-box-trim: trim-both` to remove extra space from both top and bottom of the text box.
- Use `cap alphabetic` to define trim edges based on capital letter height and alphabetic baseline.
- Apply to buttons, badges, headings, and any element where precise vertical alignment matters.
- Check browser support: Chrome 133+, Safari 18.2+, Firefox (behind flag).

## Code Example

```css
/* Trim both top and bottom */
.trimmed-text {
  text-box: trim-both cap alphabetic;
}

/* Useful for buttons with precise vertical centering */
.button-label {
  text-box: trim-both cap alphabetic;
  line-height: 1;
}

/* Headings with tight spacing */
h1 {
  text-box: trim-both cap alphabetic;
  margin-bottom: 8px; /* Now predictable */
}
```

## Audit Checklist

- [ ] Are buttons and badges using `text-box-trim` for precise vertical centering?
- [ ] Is extra text spacing causing alignment issues with adjacent elements?
- [ ] Has browser support been verified for the target audience?

## Media Reference

- Video: https://file.detail.design/text-trim-in-css.mp4

---
*From [detail.design](https://detail.design) by Rene Wang. Credit: @Ibelick*
