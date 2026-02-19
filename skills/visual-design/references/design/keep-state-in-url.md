# Keep State in URL

> Store application state in URLs to enable sharing, browser back navigation, and state restoration via bookmarks.

**Category**: Design
**Source**: [detail.design](https://detail.design/detail/keep-state-in-url)

## Why It Matters

A URL can hold roughly 2,000 characters of state information. When filters, sort orders, view modes, and selected items are encoded in the URL, every link becomes a shareable snapshot of a specific view. Users can bookmark configurations, share exact views with teammates, and use browser back/forward to undo navigation -- all without database overhead.

## How to Apply

- Encode filters, sort order, view mode, and selected items as URL query parameters.
- Use `history.pushState` or `history.replaceState` to update the URL without page reload.
- On page load, read URL parameters and restore the corresponding state.
- Keep parameter names short but meaningful (e.g., `?q=design&sort=recent&view=grid`).
- Consider using URL fragments (#) for client-side state that should not trigger server requests.

## Code Example

```javascript
// Encode state into URL
function syncStateToUrl(state) {
  const params = new URLSearchParams(state).toString();
  window.history.replaceState(null, '', `?${params}`);
}

// Restore state from URL on load
function restoreStateFromUrl() {
  const params = new URLSearchParams(window.location.search);
  return {
    filter: params.get('filter') || 'all',
    sort: params.get('sort') || 'recent',
    view: params.get('view') || 'grid',
  };
}
```

## Audit Checklist

- [ ] Are filters, sort, and view mode persisted in the URL?
- [ ] Can users share a URL that restores the exact view they see?
- [ ] Does browser back/forward navigate through state changes?
- [ ] Is state restored correctly on page load from a bookmarked URL?

## Media Reference

- Image: https://file.detail.design/media/keep-state-in-url-e7fc3609.png

---
*From [detail.design](https://detail.design) by Rene Wang. Source: Google Maps, YouTube, GitHub, mono.cards*
