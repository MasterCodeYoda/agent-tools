# Animated Sidebar Icon

> The sidebar toggle icon animates as if the sidebar is physically opening, creating a cohesive visual experience.

**Category**: Motion
**Source**: [detail.design](https://detail.design/detail/animated-sidebar-icon)

## Why It Matters

A static hamburger-to-arrow icon swap is functional but disconnected from the sidebar's motion. When the icon animation mirrors the sidebar's opening/closing movement, the interface feels like a unified physical system. This kind of intentional animation polish distinguishes premium interfaces from standard ones.

## How to Apply

- Animate the sidebar toggle icon to mirror the sidebar's slide direction and timing.
- Use animated icon libraries like Lucide Animated for pre-built, high-quality icon transitions.
- Synchronize the icon animation duration with the sidebar transition for a cohesive feel.
- The icon should visually suggest the sidebar's current state (open/closed) and the action that will happen on click.

## Code Example

```javascript
// Using Lucide Animated (recommended approach)
import { SidebarIcon } from 'lucide-animated';

// The icon automatically animates between open/closed states
<SidebarIcon isOpen={sidebarOpen} />
```

## Audit Checklist

- [ ] Does the sidebar toggle icon animate in sync with the sidebar transition?
- [ ] Does the icon clearly communicate the sidebar's current state?
- [ ] Is the animation timing synchronized with the panel motion?

## Media Reference

- Video: https://file.detail.design/animated-sidebar-icon.mp4

---
*From [detail.design](https://detail.design) by Rene Wang. Source: Linear. Credit: @pacovitiello*
