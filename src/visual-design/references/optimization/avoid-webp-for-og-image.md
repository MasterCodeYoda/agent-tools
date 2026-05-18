# Avoid Using WebP for OG Image

> Social platforms have inconsistent WebP support for Open Graph images. Use PNG or JPG instead.

**Category**: Optimization
**Source**: [detail.design](https://detail.design/detail/avoid-using-webp-for-og)

## Why It Matters

When sharing links on Facebook, Twitter/X, LinkedIn, and other platforms, the preview image comes from OG meta tags. Using WebP format risks broken or missing preview images because these platforms have inconsistent WebP support. A missing preview image significantly reduces engagement with shared links.

## How to Apply

- Use PNG or JPG format for all `og:image` meta tags, never WebP.
- Keep important content (text, logos) centered in a safe zone of approximately 1000x500px to prevent cropping.
- Set explicit width and height in OG meta tags.
- Test previews on all target platforms using their debugger tools (Facebook Sharing Debugger, Twitter Card Validator).
- Consider generating OG images dynamically with a service that outputs PNG/JPG.

## Code Example

```html
<meta property="og:image" content="https://example.com/og-image.png">
<meta property="og:image:type" content="image/png">
<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="630">
```

## Audit Checklist

- [ ] Are all OG images in PNG or JPG format (not WebP)?
- [ ] Is important content within the safe zone to avoid platform cropping?
- [ ] Have link previews been tested on Facebook, Twitter/X, and LinkedIn?
- [ ] Are OG image dimensions explicitly declared?

## Media Reference

- Image: https://file.detail.design/avoid-using-webp-for-og.png

---
*From [detail.design](https://detail.design) by Rene Wang*
