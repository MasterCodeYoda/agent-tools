# Smart Time Decide

> Interpret time requests based on human mental models, not strict chronological boundaries.

**Category**: Design
**Source**: [detail.design](https://detail.design/detail/smart-time-decide)

## Why It Matters

When someone says "wake me at 9 AM tomorrow" at 1 AM, they mean 8 hours from now, not 32 hours away. Siri and other smart assistants that interpret "tomorrow" based on sleep cycles rather than midnight boundaries prevent frustrating mistakes and make technology feel intuitive. This human-centered approach applies broadly to any time-related feature.

## How to Apply

- Detect the current time when interpreting relative time references ("tomorrow", "next week").
- Between midnight and typical wake hours (~6 AM), treat "tomorrow" as "later today after sleep."
- Ask for clarification when the intent is genuinely ambiguous.
- Apply similar logic to scheduling features: a 2 AM user scheduling a "morning meeting" likely means the upcoming morning.
- Consider user timezone and typical patterns when available.

## Audit Checklist

- [ ] Do time-related features interpret "tomorrow" sensibly when used late at night?
- [ ] Does the app ask for clarification when time intent is ambiguous?
- [ ] Are relative time references resolved based on human mental models, not midnight boundaries?

## Media Reference

- Image: https://file.detail.design/media/smart-time-decide-fd1ef9bd.webp

---
*From [detail.design](https://detail.design) by Rene Wang. Source: Apple (Siri)*
