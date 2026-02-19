# Check Potential Problem in User Content

> Warn users when required elements are missing before they complete a critical action (poka-yoke).

**Category**: Design
**Source**: [detail.design](https://detail.design/detail/check-potential-problem-in-user-content)

## Why It Matters

Rather than letting users fail and recover, proactive validation blocks actions until requirements are met. This is poka-yoke (mistake-proofing): the system detects potential problems and prevents them. Gmail warns about missing attachments, GitHub prevents merging with failing checks, and Vercel halts broken deployments. Strategic friction at the right moment prevents larger, irreversible problems.

## How to Apply

- Identify critical requirements before users can proceed (e.g., required fields, passing tests, resolved conflicts).
- Scan user input programmatically against these requirements.
- Display clear, non-dismissible warnings that explain what is missing and how to fix it.
- Block the primary action until requirements are satisfied.
- Provide actionable guidance, not just error messages.

## Code Example

```javascript
function validateBeforeSend(emailContent) {
  const warnings = [];

  if (mentionsAttachment(emailContent) && !hasAttachment) {
    warnings.push('You mentioned an attachment but none is attached.');
  }
  if (!hasSubject) {
    warnings.push('Subject line is empty.');
  }

  if (warnings.length > 0) {
    showWarningDialog(warnings);
    return false;
  }
  return true;
}
```

## Audit Checklist

- [ ] Does the app scan for common mistakes before critical actions (send, deploy, merge)?
- [ ] Are warnings clear, actionable, and non-dismissible for truly critical issues?
- [ ] Is friction applied strategically at moments where it prevents irreversible errors?

## Media Reference

- Image: https://file.detail.design/media/check-potential-problem-in-user-content-9fb79201.png

---
*From [detail.design](https://detail.design) by Rene Wang. Source: Gmail, GitHub, Vercel, Resend*
