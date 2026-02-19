# Pre-Filled Example Content

> Populate forms with realistic example data instead of leaving them empty. People love to copy.

**Category**: Design
**Source**: [detail.design](https://detail.design/detail/pre-filled-with-example-content-not-empty)

## Why It Matters

Empty forms create a blank-page problem: users do not know what is expected, what format to use, or how much detail to provide. Pre-filled example content lowers the activation barrier by providing immediate context, demonstrating expected input formats, and giving users a template to modify. This increases completion rates and reduces onboarding friction.

## How to Apply

- Populate form fields with realistic, contextual sample data.
- Use examples that match actual use cases in your product.
- Provide clear visual indicators distinguishing examples from user input (placeholder styling, "Example:" prefix).
- Include a "clear all" option for users who want to start fresh.
- For templates: pre-fill with common defaults that users can modify.

## Code Example

```html
<input
  type="text"
  placeholder="e.g., Weekly Team Standup"
  value=""
  aria-label="Meeting name"
/>

<!-- Or pre-fill with editable example -->
<textarea aria-label="Description">
This is a weekly sync to discuss progress, blockers, and priorities.
</textarea>
```

## Audit Checklist

- [ ] Do empty forms provide example content or meaningful placeholders?
- [ ] Are examples realistic and contextual (not "Lorem ipsum")?
- [ ] Can users easily clear pre-filled content to start fresh?
- [ ] Are templates pre-populated with common defaults?

## Media Reference

- Image: https://file.detail.design/media/pre-filled-with-example-content-not-empty-41b4eab7.png

---
*From [detail.design](https://detail.design) by Rene Wang. Source: Notion*
