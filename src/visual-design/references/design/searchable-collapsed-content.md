# Searchable Collapsed Content

> Browser find-in-page reveals collapsed sections automatically using `hidden="until-found"`.

**Category**: Design
**Source**: [detail.design](https://detail.design/detail/searchable-collapsed-content)

## Why It Matters

Traditional collapsed content using `display: none` or `hidden` is invisible to the browser's find-in-page feature. Users must manually expand every section to search for text, defeating the purpose of both collapsing and searching. The `hidden="until-found"` attribute keeps content visually concealed yet searchable, automatically revealing matching sections when found.

## How to Apply

- Use `hidden="until-found"` instead of `display: none` for collapsible content that should be searchable.
- Listen for the `beforematch` event to update your component's open/closed state when the browser reveals content.
- Browser support: Chromium-based browsers (Chrome, Edge, Arc) from v102+. Degrades gracefully in unsupported browsers.
- Combine with `<details>` elements for native collapsible sections.

## Code Example

```html
<details>
  <summary>FAQ: How do I reset my password?</summary>
  <div hidden="until-found">
    You can reset your password from Settings > Security > Change Password.
  </div>
</details>
```

```javascript
// Update component state when browser reveals content
element.addEventListener('beforematch', () => {
  // Update your framework's open/closed state
  setIsExpanded(true);
});
```

## Audit Checklist

- [ ] Is collapsed content searchable via browser find-in-page (Cmd+F)?
- [ ] Is `hidden="until-found"` used instead of `display: none` for collapsible sections?
- [ ] Does the component update its visual state when content is auto-revealed?

## Media Reference

- Video: https://file.detail.design/find-content-in-collapsed-section.mp4

---
*From [detail.design](https://detail.design) by Rene Wang. Credit: @burcs*
