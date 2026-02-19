# File Path Truncating

> Truncate long file paths by preserving the root folder and filename while collapsing middle directories with an ellipsis.

**Category**: Accessibility
**Source**: [detail.design](https://detail.design/detail/file-path-truncating)

## Why It Matters

Long file paths in fixed-width containers cause layout issues and force users to scroll or resize to see the full path. Users primarily need two pieces of information: where the file lives (root) and what it is called (filename). Truncating the middle directories with an ellipsis preserves the most critical information in minimal space.

## How to Apply

- Extract the root folder and filename from the full path.
- Replace intermediate directories with an ellipsis character.
- Display as: `Root / ... / filename.ext`.
- Use CSS `text-overflow: ellipsis` with `overflow: hidden` for width-constrained containers.
- Provide the full path on hover via a tooltip for users who need it.

## Code Example

```javascript
function truncatePath(fullPath, maxLength = 40) {
  if (fullPath.length <= maxLength) return fullPath;

  const parts = fullPath.split('/');
  if (parts.length <= 2) return fullPath;

  const root = parts[0] || parts[1]; // Handle leading slash
  const filename = parts[parts.length - 1];
  return `${root} / \u2026 / ${filename}`;
}
```

```css
.file-path {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  max-width: 300px;
}
```

## Audit Checklist

- [ ] Are long file paths truncated to show root and filename with ellipsis in between?
- [ ] Is the full path available on hover via a tooltip?
- [ ] Does truncation work correctly in fixed-width containers?

## Media Reference

- Video: https://file.detail.design/media/file-path.mp4

---
*From [detail.design](https://detail.design) by Rene Wang. Credit: @JohnPhamous*
