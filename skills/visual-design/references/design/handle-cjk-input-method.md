# Handle CJK Input Method Differently

> CJK input methods require special handling due to candidate selection composition, which differs significantly from Latin text input.

**Category**: Design
**Source**: [detail.design](https://detail.design/detail/handle-cjk-input-method-differently)

## Why It Matters

Applications that listen for single keystrokes (command menus) or use Enter for submission can malfunction with CJK (Chinese, Japanese, Korean) input. CJK input methods pre-fill characters into the field while awaiting candidate selection. Pressing Enter during composition selects a candidate, not submitting the form. Ignoring this breaks the experience for hundreds of millions of CJK users.

## How to Apply

- Detect IME (Input Method Editor) composition state using `compositionstart` and `compositionend` events.
- Ignore intermediate keystrokes during candidate selection.
- Only trigger actions (search, submit, command execution) when composition ends.
- For command palettes: wait for composition completion before matching.
- For submit actions: distinguish between "Enter to select candidate" and "Enter to submit."

## Code Example

```javascript
let isComposing = false;

input.addEventListener('compositionstart', () => {
  isComposing = true;
});

input.addEventListener('compositionend', () => {
  isComposing = false;
});

input.addEventListener('keydown', (e) => {
  if (e.key === 'Enter' && !isComposing) {
    submitForm();
  }
  // Do nothing if composing -- user is selecting a CJK candidate
});
```

## Audit Checklist

- [ ] Do input fields handle `compositionstart`/`compositionend` events for CJK input?
- [ ] Does Enter only trigger submit/send when composition is not active?
- [ ] Do command palettes wait for composition completion before executing?
- [ ] Has the application been tested with CJK input methods?

## Media Reference

- Image: https://file.detail.design/Screenshot%202025-11-30%20at%2014.44.01.png

---
*From [detail.design](https://detail.design) by Rene Wang. Source: Linear*
