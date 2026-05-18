# Dynamic Role of Enter Key

> The Enter key behaves contextually -- sending messages in normal text but creating line breaks inside code blocks.

**Category**: Design
**Source**: [detail.design](https://detail.design/detail/dynamic-role-of-enter-key)

## Why It Matters

Context-aware input behavior allows natural interactions without mode-switching. In Discord, pressing Enter in normal text sends the message, but inside a code block it inserts a newline. This prevents users from accidentally sending incomplete code snippets and matches their expectations based on context.

## How to Apply

- Detect the input context (normal text vs. code block, rich text vs. plain text).
- Map Enter key behavior to the appropriate action for each context.
- In code blocks: Enter = newline. In normal text: Enter = send/submit.
- Provide an escape hatch (e.g., Shift+Enter for newline in normal mode, or Cmd+Enter for send in code mode).
- Communicate the behavior change through UI hints if it might be unexpected.

## Code Example

```javascript
inputElement.addEventListener('keydown', (event) => {
  if (event.key === 'Enter' && !event.shiftKey) {
    const isInCodeBlock = detectCodeBlockContext(inputElement);
    if (isInCodeBlock) {
      // Let default behavior insert newline
      return;
    } else {
      event.preventDefault();
      sendMessage();
    }
  }
});
```

## Audit Checklist

- [ ] Does the Enter key behave contextually based on input type (text vs. code)?
- [ ] Is there an escape hatch (Shift+Enter) for the alternate behavior?
- [ ] Are context-dependent key behaviors documented or hinted in the UI?

## Media Reference

- Video: https://file.detail.design/media/dynamic-role-enter-key.mp4

---
*From [detail.design](https://detail.design) by Rene Wang. Source: Discord*
