# Dynamic Theme Color

> Match the browser's meta theme-color with your page background and update it dynamically as users scroll or navigate.

**Category**: Design
**Source**: [detail.design](https://detail.design/detail/dynamic-theme-color)

## Why It Matters

The browser address bar should not be a stark white strip disconnected from your interface. Updating `<meta name="theme-color">` dynamically merges the browser UI with your app, creating a native-like immersive experience. This elevates perceived quality and creates visual cohesion between the page content and the browser chrome.

## How to Apply

- Set an initial `<meta name="theme-color">` in the HTML head matching your page background.
- Update the meta tag dynamically when users scroll to sections with different backgrounds.
- Update on page navigation in single-page applications.
- Match the theme color to the current page section's dominant color.

## Code Example

```javascript
function updateThemeColor(color) {
  const meta = document.querySelector('meta[name="theme-color"]');
  if (meta) {
    meta.setAttribute('content', color);
  }
}

// Update on scroll to different sections
const observer = new IntersectionObserver((entries) => {
  entries.forEach((entry) => {
    if (entry.isIntersecting) {
      updateThemeColor(entry.target.dataset.themeColor);
    }
  });
}, { threshold: 0.5 });

document.querySelectorAll('[data-theme-color]').forEach((el) => {
  observer.observe(el);
});
```

## Audit Checklist

- [ ] Is `<meta name="theme-color">` set to match the page background?
- [ ] Does the theme color update dynamically on navigation or section scrolling?
- [ ] Is the browser chrome visually cohesive with the page content?

## Media Reference

- Video: https://file.detail.design/media/dynamic-theme-color.mov

---
*From [detail.design](https://detail.design) by Rene Wang*
