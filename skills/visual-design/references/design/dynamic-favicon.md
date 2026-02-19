# Dynamic Favicon

> A browser tab icon that updates dynamically to communicate page state without requiring the user to click into the tab.

**Category**: Design
**Source**: [detail.design](https://detail.design/detail/dynamic-favicon)

## Why It Matters

Users manage dozens of browser tabs. By embedding status information into the favicon -- a green check for success, a red dot for failure, a spinner for pending -- applications extend their UI into the browser chrome. Users can scan tab status at a glance without clicking through each one, reducing cognitive load during multi-tab workflows.

## How to Apply

- Monitor page state changes (pending, success, failure, notification count).
- Update the favicon dynamically using canvas-based icon generation or pre-built icon variants.
- Use distinct visual indicators: color changes, overlay symbols, or badge counts.
- Apply to CI/CD pipelines, support tickets, PR reviews, or any long-running process.
- Consider also updating `document.title` with status indicators.

## Code Example

```javascript
function setFavicon(emoji) {
  const canvas = document.createElement('canvas');
  canvas.width = canvas.height = 32;
  const ctx = canvas.getContext('2d');
  ctx.font = '28px serif';
  ctx.fillText(emoji, 2, 28);

  const link = document.querySelector("link[rel='icon']");
  link.href = canvas.toDataURL();
}

// Usage
setFavicon('⏳'); // Pending
setFavicon('✅'); // Success
setFavicon('❌'); // Failure
```

## Audit Checklist

- [ ] Does the favicon update to reflect page state (loading, success, error)?
- [ ] Can users scan tab status without clicking into each tab?
- [ ] Is the document title also updated with status information?

## Media Reference

- Image: https://file.detail.design/media/dynamic-favicon-bbf13cf7.png
- Image: https://file.detail.design/media/dynamic-favicon-9d34316e-1.png

---
*From [detail.design](https://detail.design) by Rene Wang. Source: GitHub, Vercel, Gmail*
