# No CMD or Ctrl for Shortcuts

> Single-key shortcuts eliminate modifier key friction, transforming interfaces into high-velocity command centers for power users.

**Category**: Design
**Source**: [detail.design](https://detail.design/detail/no-cmd-or-ctrl-for-shortcuts)

## Why It Matters

Every modifier key press is a micro-decision and a physical hurdle. Removing it shaves off milliseconds that compound into a feeling of effortless flow. Single-key shortcuts work in non-compositional interfaces (dashboards, list views, management canvases) where the interface assumes command intent, not text input. This creates a "pro-user" tier that rewards mastery.

## How to Apply

- Use single-key shortcuts for high-frequency actions: J/K for navigation, C for create, F or / for search.
- Only apply in contexts where text composition is not the primary mode (dashboards, not editors).
- Provide discoverability through a help menu triggered by `?`.
- Reserve single-key shortcuts for the most common actions only.
- Ensure shortcuts do not conflict with browser defaults or accessibility tools.

## Code Example

```javascript
document.addEventListener('keydown', (e) => {
  // Only activate in non-input contexts
  if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') return;

  switch (e.key) {
    case '/': openSearch(); break;
    case 'c': createNewItem(); break;
    case 'j': selectNext(); break;
    case 'k': selectPrevious(); break;
    case '?': showShortcutHelp(); break;
  }
});
```

## Audit Checklist

- [ ] Do dashboard/list views support single-key shortcuts for common actions?
- [ ] Are shortcuts disabled when input fields are focused?
- [ ] Is there a `?` or help menu listing available shortcuts?
- [ ] Do shortcuts avoid conflicts with browser defaults?

## Media Reference

- Source: Vercel dashboard

---
*From [detail.design](https://detail.design) by Rene Wang*
