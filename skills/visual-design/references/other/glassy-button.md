# Glassy Button

> A frosted glass effect created through layered CSS: backdrop blur, transparency, thin border, and soft shadow.

**Category**: Visual Effect
**Source**: [detail.design](https://detail.design/detail/liquid-glass-button)

## Why It Matters

The glassmorphism aesthetic creates visual depth and modern polish. A glassy button feels premium because it interacts with the content behind it, creating a sense of layered physicality. The technique requires just four CSS properties working together, making it accessible to implement while producing a high-quality visual result.

## How to Apply

- Layer four CSS properties: `backdrop-filter: blur()`, semi-transparent `background`, thin semi-transparent `border`, and soft `box-shadow`.
- Ensure there is interesting content behind the button for the blur effect to be visible.
- Test performance: `backdrop-filter` can be expensive on lower-end devices.
- Provide a solid fallback for browsers that do not support `backdrop-filter`.

## Code Example

```css
.glassy-button {
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
  background: rgba(255, 255, 255, 0.1);
  border: 1px solid rgba(255, 255, 255, 0.3);
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
  border-radius: 12px;
  padding: 12px 24px;
  color: white;
}

/* Fallback for unsupported browsers */
@supports not (backdrop-filter: blur(20px)) {
  .glassy-button {
    background: rgba(50, 50, 50, 0.9);
  }
}
```

## Audit Checklist

- [ ] Does the glassy effect use all four layers (blur, transparency, border, shadow)?
- [ ] Is a solid fallback provided for browsers without `backdrop-filter` support?
- [ ] Has performance been tested on lower-end devices?
- [ ] Is there sufficient contrast for text readability over the blurred background?

## Media Reference

- Video: https://file.detail.design/media/liquid-glass-button-7f1ebb5f.mov

---
*From [detail.design](https://detail.design) by Rene Wang. Source: wabi.ai*
