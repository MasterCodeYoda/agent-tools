# Detect Address in PDF

> Intelligently recognize and extract address information from PDF documents for quick mapping or contact saving.

**Category**: Design
**Source**: [detail.design](https://detail.design/detail/detect-address-in-pdf)

## Why It Matters

This pattern exemplifies ambient intelligence: technology that anticipates user needs without explicit commands. Rather than requiring manual copy-paste from a PDF to a maps app, the system recognizes addresses contextually and offers quick actions (map, save to contacts). This eliminates friction in a common workflow that traditionally requires multiple steps and app switches.

## How to Apply

- Parse PDF text content for address-like patterns using regex or ML-based recognition.
- Offer contextual actions on detected addresses: open in Maps, save to Contacts, copy formatted.
- Extend this pattern to other detectable data: phone numbers, dates, email addresses, tracking numbers.
- Highlight detected information subtly (underline, dotted border) to indicate actionability.
- Provide the actions through a contextual menu or tooltip on tap/click.

## Audit Checklist

- [ ] Does the app detect actionable data (addresses, phone numbers, dates) in user content?
- [ ] Are contextual quick actions offered for detected data?
- [ ] Is detection non-intrusive (subtle highlighting, not modal prompts)?

## Media Reference

- Image: https://file.detail.design/detect-address-in-pdf.png

---
*From [detail.design](https://detail.design) by Rene Wang. Source: macOS*
