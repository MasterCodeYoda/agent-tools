# Chat Minimap

> A floating minimap keeps long conversations grounded by highlighting the active context as you scroll.

**Category**: Interactivity
**Source**: [detail.design](https://detail.design/detail/chat-minimap)

## Why It Matters

Long chat transcripts make it difficult to maintain context awareness. A minimap solves this by pinning a subtle navigation aid to the viewport that always shows which region of the conversation you are reading. This pattern, borrowed from code editors, works beautifully for any long-form scrollable content.

## How to Apply

- Monitor scroll position in real-time to determine the active conversation region.
- Display a compact minimap showing the overall conversation structure.
- Animate the position indicator with smooth easing (~240ms) for calm, natural motion.
- Brighten section labels on hover to signal interactivity.
- Provide click-to-jump functionality for direct navigation to any section.
- Add brief focus ring animation on click to confirm context shifts.

## Code Example

```javascript
// Track scroll position and update minimap
const observer = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      updateMinimapIndicator(entry.target.dataset.section);
    }
  });
}, { threshold: 0.5 });

document.querySelectorAll('[data-section]').forEach(el => {
  observer.observe(el);
});
```

```css
.minimap-indicator {
  transition: top 240ms ease-out;
  background: var(--accent);
  border-radius: 2px;
}

.minimap-label:hover {
  opacity: 1;
  color: var(--text-primary);
}
```

## Audit Checklist

- [ ] Do long scrollable views (chats, documents, timelines) provide navigation aids?
- [ ] Does the minimap update smoothly with scroll position?
- [ ] Can users click minimap sections to jump directly to content?

## Media Reference

- Image: https://file.detail.design/media/chat-minimap-3526bf2d.png
- Video: https://file.detail.design/media/chat-minimap-8d1849c2-1.mov

---
*From [detail.design](https://detail.design) by Rene Wang. Source: LobeHub (lobechat.com)*
