# Currency Detection in Photos

> Tap monetary amounts in photos to instantly convert them to local currency -- ambient intelligence with zero friction.

**Category**: Design
**Source**: [detail.design](https://detail.design/detail/ios-currency-detection-in-photos)

## Why It Matters

This "tap to transform" pattern exemplifies ambient intelligence -- technology that anticipates user needs without explicit commands. Instead of manually copying an amount, opening a calculator, and looking up exchange rates, the system recognizes currency in a photo and delivers immediate conversion with a single tap. This eliminates multi-step workflows and makes the device feel genuinely smart.

## How to Apply

- Use on-device intelligence (OCR, ML models) to detect currency amounts in images and documents.
- Provide single-tap conversion to the user's local currency via a popover or inline display.
- Extend the "tap to transform" pattern to other data types: unit conversions, time zones, measurements.
- No app switching should be required -- the action happens in context.
- Keep the interaction reversible (tap to dismiss) and non-destructive.

## Audit Checklist

- [ ] Does the app detect actionable data (currency, measurements, dates) in visual content?
- [ ] Are contextual actions (convert, map, schedule) available via a single tap?
- [ ] Does the conversion happen in-place without app switching?

## Media Reference

- Video: https://file.detail.design/detect-cash-in-photo.mov

---
*From [detail.design](https://detail.design) by Rene Wang. Source: Apple iOS*
