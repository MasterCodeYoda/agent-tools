# Special Icon Based on Folder Name

> Automatically assign distinctive folder icons based on standardized folder names like "Developer" and "Documents."

**Category**: Design
**Source**: [detail.design](https://detail.design/detail/special-icon-based-on-folder-name)

## Why It Matters

Generic folder icons force users to read every label to find what they need. Distinctive, automatically-assigned icons based on folder names (Developer, Documents, Downloads) provide instant visual recognition, improving navigation speed and reducing errors. This leverages pattern recognition, which is faster than reading.

## How to Apply

- Maintain a mapping of common folder/category names to distinctive icons.
- Apply icons automatically based on name matching (case-insensitive).
- Support common conventions: src, docs, tests, config, assets, components.
- Fall back to a generic icon for unrecognized names.
- In file trees and navigation, display the specialized icon alongside the name.

## Code Example

```javascript
const FOLDER_ICONS = {
  'src': 'code',
  'docs': 'book',
  'tests': 'flask',
  'config': 'gear',
  'assets': 'image',
  'components': 'puzzle',
  'pages': 'file-text',
  'api': 'server',
};

function getFolderIcon(name) {
  return FOLDER_ICONS[name.toLowerCase()] || 'folder';
}
```

## Audit Checklist

- [ ] Do common folder/category names receive distinctive icons?
- [ ] Is the icon assignment automatic based on name conventions?
- [ ] Are icons consistent with the product's icon system?

## Media Reference

- Image: https://file.detail.design/special-icon-based-on-folder-name.png

---
*From [detail.design](https://detail.design) by Rene Wang. Source: macOS*
