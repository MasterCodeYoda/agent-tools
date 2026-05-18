# Describe Link Action

> Announce link destinations to assistive technology users, providing clearer context than generic link text.

**Category**: Accessibility
**Source**: [detail.design](https://detail.design/detail/describe-link-action)

## Why It Matters

Screen reader users often navigate by tabbing through links. Generic text like "click here" or "read more" provides no context about the destination. Descriptive link text and `aria-label` attributes enable assistive technology to announce the purpose of each link, making navigation faster and more predictable for users who cannot visually scan the page.

## How to Apply

- Write link text that describes the destination or action: "View pricing plans" instead of "Click here."
- Use `aria-label` when the visible text is insufficient for screen readers.
- Use `aria-describedby` for additional context beyond the link text.
- Test with Safari's VoiceOver, which provides enhanced link destination announcements.
- Avoid "Learn more" and "Click here" as standalone link text.

## Code Example

```html
<!-- Descriptive link text -->
<a href="/pricing">View pricing plans</a>

<!-- When visual design requires short text, use aria-label -->
<a href="/docs" aria-label="Read the API documentation">Docs</a>

<!-- Additional context via aria-describedby -->
<a href="/submit" aria-describedby="submit-desc">Submit</a>
<span id="submit-desc" class="sr-only">
  Submit your design detail for review
</span>
```

## Audit Checklist

- [ ] Do all links have descriptive text that makes sense out of context?
- [ ] Are generic labels ("click here", "read more") replaced with descriptive alternatives?
- [ ] Is `aria-label` used when visible text is insufficient for screen readers?
- [ ] Has the link navigation been tested with a screen reader?

## Media Reference

- Video: https://file.detail.design/describe-link-action.mp4

---
*From [detail.design](https://detail.design) by Rene Wang*
