# Auto Naming for Screenshot Based on Context

> Name screenshot files based on the app context where they were captured, enabling natural language search later.

**Category**: Design
**Source**: [detail.design](https://detail.design/detail/auto-naming-for-screenshot-based-on-context)

## Why It Matters

Generic file names like `IMG_20250101_120530.png` are useless when searching later. Contextual naming -- using the page title, app name, or visible content -- transforms screenshots into searchable artifacts. When a user later searches for "Stripe Dashboard," the contextually-named screenshot surfaces instantly, solving the real problem: finding what was captured, not just capturing it.

## How to Apply

- At capture time, detect the active context: browser page title, app name, note content.
- Generate a meaningful filename from the context without timestamps or metadata prefixes.
- Apply restraint: name files simply and clearly, letting the content speak.
- Extend this principle to any auto-generated file: exports, downloads, recordings.
- For web apps: use `download` attribute with a meaningful filename on export links.

## Code Example

```javascript
// Auto-name downloaded files based on content
function downloadScreenshot(canvas, context) {
  const link = document.createElement('a');
  link.download = `${sanitizeFilename(context.pageTitle)}.png`;
  link.href = canvas.toDataURL('image/png');
  link.click();
}

// Instead of: screenshot-2025-01-19.png
// Generate:  Stripe Dashboard.png
```

## Audit Checklist

- [ ] Are auto-generated files (screenshots, exports) named based on content context?
- [ ] Can users find files later using natural language search terms?
- [ ] Do download links use meaningful filenames via the `download` attribute?

## Media Reference

- Image: https://file.detail.design/auto-naming-screenshot-based-context.png

---
*From [detail.design](https://detail.design) by Rene Wang. Source: iOS*
