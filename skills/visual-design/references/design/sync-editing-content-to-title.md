# Sync Editing Content to Title

> Update the browser tab title in real-time as users edit content, before they even save.

**Category**: Design
**Source**: [detail.design](https://detail.design/detail/sync-editing-content-to-title)

## Why It Matters

Real-time title updates create anticipatory feedback by reflecting changes immediately. GitHub updates the tab title as you edit a repository name, predicting your intent and closing the cognitive gap between "what I am typing" and "what this will become." The browser tab becomes a live preview, letting users evaluate changes in context before committing.

## How to Apply

- Listen to input/change events on title or name fields.
- Update `document.title` in real-time as the user types.
- After server-side save, update the title again to reflect the final value.
- Avoid this pattern when live updates would be disorienting (e.g., financial amounts, destructive operations).
- Only apply when the field being edited is the primary identifier for the page.

## Code Example

```javascript
const titleInput = document.querySelector('#page-title');
titleInput.addEventListener('input', (e) => {
  document.title = e.target.value || 'Untitled';
});
```

## Audit Checklist

- [ ] Does the browser tab title update in real-time as users edit the page's primary identifier?
- [ ] Is the title synced again after saving to reflect the final server state?
- [ ] Is this behavior limited to primary identifiers (not secondary fields)?

## Media Reference

- Video: https://file.detail.design/media/sync-editing-content-to-title-8620748e.mp4

---
*From [detail.design](https://detail.design) by Rene Wang. Source: GitHub*
