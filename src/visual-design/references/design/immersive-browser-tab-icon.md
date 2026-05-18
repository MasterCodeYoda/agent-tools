# Immersive Browser Tab Icon

> The active pinned tab's border dynamically colors to match the favicon's dominant colors, creating visual coherence.

**Category**: Design
**Source**: [detail.design](https://detail.design/detail/immersive-browser-tab-icon)

## Why It Matters

Browser tab indicators are a key part of the user's workspace. When the active tab border matches the site's favicon colors, it creates seamless brand recognition and makes it easier to identify active tabs at a glance. This extends your brand's visual system into the browser chrome itself.

## How to Apply

- Extract the dominant color from your favicon using canvas-based color analysis.
- Set the extracted color as a CSS custom property for tab-like elements in your app.
- For web apps: use `<meta name="theme-color">` to influence browser chrome coloring.
- For browser extensions: read favicon pixel data to determine primary colors.

## Code Example

```javascript
// Extract dominant color from favicon
async function getFaviconColor(faviconUrl) {
  const img = new Image();
  img.crossOrigin = 'anonymous';
  img.src = faviconUrl;
  await img.decode();

  const canvas = document.createElement('canvas');
  canvas.width = canvas.height = 1;
  const ctx = canvas.getContext('2d');
  ctx.drawImage(img, 0, 0, 1, 1);
  const [r, g, b] = ctx.getImageData(0, 0, 1, 1).data;
  return `rgb(${r}, ${g}, ${b})`;
}
```

## Audit Checklist

- [ ] Does the app set a `<meta name="theme-color">` that matches its brand?
- [ ] Is the theme color updated dynamically to reflect the current page context?

## Media Reference

- Image: https://file.detail.design/immersive-browser-tab-icon.png

---
*From [detail.design](https://detail.design) by Rene Wang. Credit: @brian_lovin*
