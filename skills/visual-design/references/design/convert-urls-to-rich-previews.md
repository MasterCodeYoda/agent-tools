# Convert Internal URLs to Rich Previews

> Transform internal links into visually rich preview cards instead of plain text links.

**Category**: Design
**Source**: [detail.design](https://detail.design/detail/convert-internal-urls-to-rich-previews)

## Why It Matters

A glance is better than a click. Visual previews provide instant context about linked content, improving navigation efficiency and reducing cognitive load. Treating internal links specially -- with title, icon, and metadata previews -- signals intentional design and crafts a cohesive in-app experience.

## How to Apply

- Detect internal links in user-generated content (comments, documents, chat).
- Extract metadata (title, icon, description, status) from the target page.
- Render a compact rich preview card inline or on hover.
- Style previews consistently with your design system.
- Fall back gracefully to plain links for external or unresolvable URLs.

## Code Example

```javascript
// Detect and transform internal links
function transformInternalLinks(content) {
  const internalUrlPattern = /https:\/\/app\.example\.com\/[\w/-]+/g;
  return content.replace(internalUrlPattern, async (url) => {
    const metadata = await fetchPageMetadata(url);
    return `<a href="${url}" class="rich-preview">
      <span class="preview-icon">${metadata.icon}</span>
      <span class="preview-title">${metadata.title}</span>
      <span class="preview-status">${metadata.status}</span>
    </a>`;
  });
}
```

## Audit Checklist

- [ ] Are internal links rendered as rich previews with title, icon, and metadata?
- [ ] Is the preview styling consistent with the design system?
- [ ] Do external links fall back to standard link rendering?
- [ ] Are previews updated when the target page's metadata changes?

## Media Reference

- Image: https://file.detail.design/preview-for-internal-links.png

---
*From [detail.design](https://detail.design) by Rene Wang*
