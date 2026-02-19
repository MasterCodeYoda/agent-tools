# Search by Context Instead of Name

> Your intent matters more than your exact words. Search should understand context, not just match keywords.

**Category**: Design
**Source**: [detail.design](https://detail.design/detail/search-by-context-instead-of-name)

## Why It Matters

Users rarely remember exact names, menu labels, or technical terms. Contextual search reduces cognitive load by eliminating the need to learn specific terminology. When search understands that "dark mode" and "change my password" are both settings-related queries, it surfaces the right results regardless of exact phrasing.

## How to Apply

- Design search to map user intent, not just keywords. "Change my password" should surface the password settings page.
- Consider the user's current location in the app: "John" means different things in email vs. contacts vs. calendar.
- Include synonyms, aliases, and natural language descriptions in the search index alongside formal names.
- Surface contextually relevant results first, then broader matches.

## Code Example

```javascript
// Add intent-based search aliases to your index
const searchIndex = [
  {
    page: '/settings/appearance',
    terms: ['dark mode', 'light mode', 'theme', 'change appearance', 'color scheme']
  },
  {
    page: '/settings/security',
    terms: ['password', 'change my password', 'login', 'two factor', '2fa']
  }
];
```

## Audit Checklist

- [ ] Does search return relevant results for natural language queries, not just exact keyword matches?
- [ ] Are search results contextually weighted based on the user's current location in the app?
- [ ] Are synonyms and intent-based aliases indexed alongside formal names?

## Media Reference

- Image: https://file.detail.design/media/search-by-context-instead-of-name-de8ff449.png

---
*From [detail.design](https://detail.design) by Rene Wang. Source: Linear*
