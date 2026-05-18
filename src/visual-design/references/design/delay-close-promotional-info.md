# Delay Close Action for Promotional Info

> Add a slight delay before enabling the close button on promotional banners, capturing a split-second of attention.

**Category**: Design
**Source**: [detail.design](https://detail.design/detail/delay-close-action-for-promotional-info)

## Why It Matters

Users reflexively dismiss promotional banners before reading them. A brief delay (1-3 seconds) before the close button becomes active ensures users pause long enough to glance at the headline. This captures "just enough attention to absorb the message" without feeling manipulative, as long as the delay is short and the content is genuinely relevant.

## How to Apply

- Disable the close button for 1-3 seconds after the banner appears.
- Use a subtle visual indicator (progress ring, fade-in) to show when close will become available.
- Keep the delay short enough to avoid frustration.
- Only apply to genuinely important or useful announcements (What's New, feature updates), not ads.
- Ensure the content is valuable enough to justify the brief wait.

## Code Example

```javascript
const closeBtn = document.querySelector('.banner-close');
closeBtn.disabled = true;
closeBtn.style.opacity = '0.3';

setTimeout(() => {
  closeBtn.disabled = false;
  closeBtn.style.opacity = '1';
  closeBtn.style.transition = 'opacity 200ms ease';
}, 2000);
```

## Audit Checklist

- [ ] Do important announcements briefly delay the close action to ensure visibility?
- [ ] Is the delay short (1-3 seconds) and applied only to valuable content?
- [ ] Is there a visual indicator showing when close will become available?

## Media Reference

- Video: https://file.detail.design/media/delay-close-action-for-promotional-info-d615e8bf.mov

---
*From [detail.design](https://detail.design) by Rene Wang. Source: Vercel*
