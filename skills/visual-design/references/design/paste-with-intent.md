# Paste with Intent

> Pasting a URL onto a canvas instantly creates a web embed card, recognizing user intent rather than treating paste as literal text.

**Category**: Design
**Source**: [detail.design](https://detail.design/detail/paste-with-intent)

## Why It Matters

When context makes user intent unambiguous, the system should act on that intent. Pasting a URL onto a visual canvas clearly means "embed this resource," not "display this text string." By transforming the paste into a rich embed automatically, the interface eliminates confirmation dialogs and menu navigation, achieving anticipatory design with zero-friction interaction.

## How to Apply

- Detect clipboard content type on paste (URL, image, formatted text, etc.).
- When context makes intent clear (e.g., URL on canvas = embed), transform automatically.
- Ensure the transformation is easily reversible (undo, or convert back to plain text).
- Apply this pattern when the richer format provides immediate value over plain text.
- Avoid in contexts where literal text is expected (code editors, terminal inputs).

## Code Example

```javascript
canvas.addEventListener('paste', (e) => {
  const text = e.clipboardData.getData('text/plain');
  if (isValidUrl(text)) {
    e.preventDefault();
    createRichEmbed(text, cursorPosition);
  }
  // Otherwise, let default paste behavior handle it
});
```

## Audit Checklist

- [ ] Does pasting a URL create a rich preview/embed where context is clear?
- [ ] Is the transformation easily reversible (Cmd+Z or convert option)?
- [ ] Is paste-with-intent disabled in contexts where literal text is expected?

## Media Reference

- Video: https://file.detail.design/media/paste-with-intent-d3f634a9.mov

---
*From [detail.design](https://detail.design) by Rene Wang. Source: Obsidian*
