# Themed Icon for PWA on Android

> Enable Progressive Web Apps to display Material You-themed icons that adapt to the device's system colors.

**Category**: Optimization
**Source**: [detail.design](https://detail.design/detail/themed-icon-for-pwa-on-android)

## Why It Matters

PWAs can achieve native app-like integration on Android by supporting adaptive, themed icons. Adding a monochrome icon variant allows Android to apply the device's Material You theme colors, making the web app feel seamlessly integrated into the home screen rather than appearing as a generic bookmark.

## How to Apply

- Create a monochrome (single-color on transparent) version of your app icon.
- Add it to the web app manifest with `purpose: "monochrome"`.
- Android will automatically apply the device's theme colors to the monochrome icon.
- Keep the icon design simple and recognizable at small sizes (196x196px minimum).
- Test on Android devices with Material You theming enabled.

## Code Example

```json
{
  "icons": [
    {
      "src": "/icons/icon-192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "/icons/icon-monochrome.png",
      "sizes": "196x196",
      "type": "image/png",
      "purpose": "monochrome"
    }
  ]
}
```

## Audit Checklist

- [ ] Does the PWA manifest include a monochrome icon for Android theming?
- [ ] Is the monochrome icon recognizable and clean at small sizes?
- [ ] Has the themed icon been tested on Android with Material You?

## Media Reference

- Video: https://file.detail.design/themed-icon-for-pwa.mp4

---
*From [detail.design](https://detail.design) by Rene Wang*
