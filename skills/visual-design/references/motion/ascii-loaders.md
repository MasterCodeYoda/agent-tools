# ASCII Loaders

> Text-based animated loading spinners using ASCII characters for lightweight, accessible loading indicators.

**Category**: Motion
**Source**: [detail.design](https://detail.design/detail/ascii-loaders)

## Why It Matters

ASCII loaders provide visual feedback without requiring image assets, making them ideal for CLIs, terminal-based tools, and developer-focused applications. They are lightweight, universally renderable, and add character to text-based interfaces. A well-chosen spinner conveys activity and personality simultaneously.

## How to Apply

- Use the `cli-spinners` library by Sindre Sorhus for a comprehensive collection of ASCII loader patterns.
- Choose a spinner style that matches the product's personality (minimal dots for serious tools, playful characters for creative tools).
- Ensure the animation speed is fast enough to convey activity (typically 80-120ms frame intervals).
- Pair with a status message describing what is loading.

## Code Example

```javascript
import cliSpinners from 'cli-spinners';

const spinner = cliSpinners.dots;
let i = 0;

const interval = setInterval(() => {
  process.stdout.write(`\r${spinner.frames[i]} Loading...`);
  i = (i + 1) % spinner.frames.length;
}, spinner.interval);
```

## Audit Checklist

- [ ] Do CLI/terminal tools provide loading indicators for async operations?
- [ ] Is the spinner style consistent with the product's personality?
- [ ] Is a descriptive status message displayed alongside the spinner?

## Media Reference

- Video: https://file.detail.design/ascii-loaders.mp4

---
*From [detail.design](https://detail.design) by Rene Wang. Credit: @willking. Library: [cli-spinners](https://github.com/sindresorhus/cli-spinners)*
