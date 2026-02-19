---
name: visual-design
description: Visual design micro-patterns from detail.design for evaluating and improving UI polish — motion, accessibility, typography, and interaction details that make big differences.
---

## When to Use

- **Evaluating app design** — Auditing an existing application for visual polish and micro-interaction quality.
- **Implementing UI features** — Building new components and wanting to apply best-practice design details.
- **Pre-launch audit** — Final quality pass before releasing to users, checking for unfinished edges and missing micro-interactions.
- **Code review** — Reviewing frontend PRs with an eye toward design quality, not just functionality.

## Philosophy

Micro-details are the difference between software that works and software that feels right. Users cannot always articulate why one product feels premium and another feels cheap, but the answer is almost always in the details: the way a modal closes, the way a button responds to a disabled click, the way a favicon updates to reflect state.

These patterns matter because they compound. Each individual detail is small, but together they build:

- **Trust** — Polished interfaces signal competence. If the team cared about this pixel, they probably cared about your data too.
- **Perceived quality** — Users judge quality by feel, not feature lists. Smooth animations, thoughtful transitions, and contextual intelligence make software feel expensive.
- **Competitive differentiation** — Features are easy to copy. Craft is not. The last 1% of polish is what separates a good product from a great one.

## Quick Audit Checklist

Use this checklist as a rapid diagnostic when evaluating any application's visual design quality.

### Motion
- [ ] Are animations interruptible (not blocking user input)?
- [ ] Do layout shifts animate smoothly instead of jumping?
- [ ] Are staggered animations used for multi-element transitions?
- [ ] Do loading indicators communicate purpose, not just activity?
- [ ] Are modal close animations physics-aware (tracking scroll)?

### Accessibility
- [ ] Do all touch targets meet the 44px minimum on mobile?
- [ ] Is `prefers-reduced-motion` respected?
- [ ] Are all forms fully keyboard-navigable?
- [ ] Do links have descriptive text (not "click here")?
- [ ] Are file paths truncated meaningfully (root + filename)?

### Design
- [ ] Does the favicon adapt to light/dark mode?
- [ ] Is `<meta name="theme-color">` set and updated dynamically?
- [ ] Are brand names capitalized correctly (GitHub, macOS, iOS)?
- [ ] Does search understand context and intent, not just keywords?
- [ ] Is application state persisted in the URL for sharing?
- [ ] Does the Enter key behave contextually (send vs. newline)?
- [ ] Are CJK input methods handled correctly?

### Typography & Visual
- [ ] Is `text-box-trim` used for precise text alignment?
- [ ] Is text truncation handled elegantly (gradient fade + ellipsis)?
- [ ] Do nested rounded elements use concentric border-radius values?
- [ ] Do fade edges avoid overlapping scrollbars?

### Easter Eggs & Delight
- [ ] Are error pages (404, 500) designed as experiences, not dead ends?
- [ ] Are there hidden details that reward user curiosity?
- [ ] Do small interactions (emoji, hover states) add personality?

## Category Index

### Motion (14 references)

| Pattern | Description | Reference |
|---------|-------------|-----------|
| Interruptible Animation | Close events fire immediately without waiting for animation | [File](references/motion/interruptible-animation.md) |
| Prevent Layout Shift | Invisible pseudo-elements reserve space for bold text | [File](references/motion/prevent-layout-shift.md) |
| Shake Disabled Button | Disabled button shakes on click to acknowledge the attempt | [File](references/motion/shake-disabled-button.md) |
| Morphing Button to Input | Button smoothly transforms into an input field | [File](references/motion/morphing-button-to-input.md) |
| Closing Modal Respects Physics | Modal return animation tracks scroll position like a magnet | [File](references/motion/closing-modal-respects-physics.md) |
| Animated Color Change | Icon color shifts sequentially in color picker | [File](references/motion/animated-color-change-icon-picker.md) |
| Tooltip Transition | Smooth position transition between grouped tooltips | [File](references/motion/tooltip-transition.md) |
| Animated Action Button | Action button with purposeful feedback animation | [File](references/motion/animated-action-button.md) |
| Self-Explanatory Load Bar | Load bar animation clarifies the interaction's intent | [File](references/motion/self-explanatory-load-bar.md) |
| Stagger for Event Order | Sequential delays guide attention through multi-element animations | [File](references/motion/stagger-for-event-order.md) |
| Animated Sidebar Icon | Toggle icon mirrors the sidebar's physical motion | [File](references/motion/animated-sidebar-icon.md) |
| Music Player Layout Shift | Controls slide smoothly when album art expands | [File](references/motion/music-player-layout-shift.md) |
| ASCII Loaders | Text-based animated spinners for CLI and terminal tools | [File](references/motion/ascii-loaders.md) |
| Colorful Cursor Blink | Cursor cycles through brand colors to signal special modes | [File](references/motion/colorful-cursor-blink.md) |

### Design (36 references)

| Pattern | Description | Reference |
|---------|-------------|-----------|
| Photo Response to Theme Mode | Images adapt brightness/source for dark mode | [File](references/design/photo-response-to-theme-mode.md) |
| Search by Context | Search understands intent, not just keyword matches | [File](references/design/search-by-context.md) |
| Outer and Inner Border Radius | Nested elements use concentric radius (outer - padding) | [File](references/design/outer-and-inner-border-radius.md) |
| Dynamic Visual Guideline | Table guidelines fade on hover to reduce clutter | [File](references/design/dynamic-visual-guideline.md) |
| Keep Entry of Active View | Active list item always remains visible | [File](references/design/keep-entry-of-active-view.md) |
| Respect Brand Name | Correct capitalization: GitHub, macOS, iOS | [File](references/design/respect-brand-name.md) |
| Bring Life to AI Features | Personality and animation for AI interactions | [File](references/design/bring-life-to-ai-features.md) |
| Searchable Collapsed Content | `hidden="until-found"` makes collapsed content searchable | [File](references/design/searchable-collapsed-content.md) |
| Themed Favicon | Favicon adapts to light/dark color scheme | [File](references/design/themed-favicon.md) |
| Scroll Landmark | Scroll-to-top with position memory for return | [File](references/design/scroll-landmark.md) |
| Immersive Browser Tab Icon | Tab border matches favicon's dominant color | [File](references/design/immersive-browser-tab-icon.md) |
| Collapse Instead of Close | Hide content rather than destroy it | [File](references/design/collapse-instead-of-close.md) |
| Paperclip Pin Hover | Paperclip icon opens on hover to signal unpin action | [File](references/design/paperclip-pin-hover.md) |
| Dynamic Role of Enter Key | Enter behaves contextually (send vs. newline) | [File](references/design/dynamic-role-of-enter-key.md) |
| No Pointer Cursor | Pointer cursor only for navigation, default for actions | [File](references/design/no-pointer-cursor.md) |
| Paste with Intent | Pasting a URL creates a rich embed, not plain text | [File](references/design/paste-with-intent.md) |
| Dynamic Favicon | Favicon updates to reflect page state (loading, success) | [File](references/design/dynamic-favicon.md) |
| Anchored Scrolling | Command palette locks highlight and scrolls list beneath | [File](references/design/anchored-scrolling.md) |
| Sync Editing Content to Title | Browser tab title updates in real-time during editing | [File](references/design/sync-editing-content-to-title.md) |
| Check Potential Problem | Proactive validation blocks actions until requirements met | [File](references/design/check-potential-problem.md) |
| Pre-Filled Example Content | Forms populated with realistic examples, not empty | [File](references/design/pre-filled-example-content.md) |
| Dynamic Theme Color | `<meta theme-color>` updates on scroll and navigation | [File](references/design/dynamic-theme-color.md) |
| Keep State in URL | Filters, sort, and view mode persisted in URL | [File](references/design/keep-state-in-url.md) |
| Smart Time Decide | Time interpretation based on human mental models | [File](references/design/smart-time-decide.md) |
| Convert URLs to Rich Previews | Internal links rendered as preview cards | [File](references/design/convert-urls-to-rich-previews.md) |
| Detect Address in PDF | Recognize addresses in documents for quick actions | [File](references/design/detect-address-in-pdf.md) |
| Special Icon Based on Folder Name | Auto-assign distinctive icons by folder name | [File](references/design/special-icon-based-on-folder-name.md) |
| Follow Us Text Trick | Social handles replace generic "Follow us" text | [File](references/design/follow-us-text-trick.md) |
| No CMD/Ctrl for Shortcuts | Single-key shortcuts for power user flows | [File](references/design/no-cmd-ctrl-for-shortcuts.md) |
| Delay Close Promotional Info | Brief delay before enabling close on announcements | [File](references/design/delay-close-promotional-info.md) |
| Poll Item Word Counter | Checkbox morphs into circular character counter | [File](references/design/poll-item-word-counter.md) |
| Auto Naming Screenshot | Context-based filenames for screenshots and exports | [File](references/design/auto-naming-screenshot.md) |
| Active State in Footer | Footer nav shows active state like header nav | [File](references/design/active-state-in-footer.md) |
| Handle CJK Input Method | Special handling for Chinese/Japanese/Korean input | [File](references/design/handle-cjk-input-method.md) |
| Special Cursor on People | Help cursor on author sections signals more info | [File](references/design/special-cursor-on-people.md) |
| Currency Detection in Photos | Tap amounts in photos for instant conversion | [File](references/design/currency-detection-in-photos.md) |

### Accessibility (5 references)

| Pattern | Description | Reference |
|---------|-------------|-----------|
| Larger Hit Area | Invisible padding extends touch targets beyond visual boundary | [File](references/accessibility/larger-hit-area.md) |
| Describe Link Action | Descriptive link text for screen readers | [File](references/accessibility/describe-link-action.md) |
| Form Respects Keyboard | Full keyboard navigability for all forms | [File](references/accessibility/form-respects-keyboard.md) |
| File Path Truncating | Root + filename preserved, middle truncated | [File](references/accessibility/file-path-truncating.md) |
| Reduced Animation for Frequent Features | Minimize animation for productivity interactions | [File](references/accessibility/reduced-animation-frequent-feature.md) |

### Easter Egg (7 references)

| Pattern | Description | Reference |
|---------|-------------|-----------|
| Cast Ending | Final polish details that reach 100% perfection | [File](references/easter-egg/cast-ending.md) |
| Show Visited Workspace Map | Hidden map visualization of visited workspaces | [File](references/easter-egg/show-visited-workspace-map.md) |
| Inspect Tool Golden Thumb | Hidden easter egg in developer inspect tools | [File](references/easter-egg/inspect-tool-golden-thumb.md) |
| Address on Mail App Icon | Hidden meaningful text in app icon details | [File](references/easter-egg/address-on-mail-app-icon.md) |
| Interactive Error Page | Engaging interaction on error pages | [File](references/easter-egg/interactive-error-page.md) |
| Interactive 404 Page | 404 as a hidden world, not a dead end | [File](references/easter-egg/interactive-404-page.md) |
| Shifting Emoji | Random emoji cycling on hover for playfulness | [File](references/easter-egg/shifting-emoji.md) |

### Interactivity (3 references)

| Pattern | Description | Reference |
|---------|-------------|-----------|
| Auto Segment Video | Automatic chapter detection for long videos | [File](references/interactivity/auto-segment-video.md) |
| Auto Snap Screenshot | Crop handles snap to UI component edges | [File](references/interactivity/auto-snap-screenshot.md) |
| Chat Minimap | Floating minimap for long conversation navigation | [File](references/interactivity/chat-minimap.md) |

### Optimization (3 references)

| Pattern | Description | Reference |
|---------|-------------|-----------|
| Avoid WebP for OG Image | Use PNG/JPG for Open Graph images, not WebP | [File](references/optimization/avoid-webp-for-og-image.md) |
| Overscroll Nested Scrollers | `overscroll-behavior: contain` prevents scroll chaining | [File](references/optimization/overscroll-nested-scrollers.md) |
| Themed Icon for PWA on Android | Monochrome icon for Material You theming | [File](references/optimization/themed-icon-pwa-android.md) |

### Other (5 references)

| Pattern | Description | Reference |
|---------|-------------|-----------|
| CSS Text-Box Trim | Remove extra text spacing for pixel-perfect alignment | [File](references/other/css-text-box-trim.md) |
| Text Overflow Cutoff | Gradient fade + ellipsis for elegant truncation | [File](references/other/text-overflow-cutoff.md) |
| Fade Edge No Override Scrollbar | Gradient edges stop before the scrollbar area | [File](references/other/fade-edge-no-override-scrollbar.md) |
| Glassy Button | Frosted glass effect with four layered CSS properties | [File](references/other/glassy-button.md) |
| Easy to Reference ID | Prefix-number ID schema for human-friendly references | [File](references/other/easy-to-reference-id.md) |

## How to Apply

When auditing or building UI, follow this workflow:

### 1. Run the Quick Audit Checklist
Start with the checklist above to identify gaps by category. Score each area (Motion, Accessibility, Design, Typography, Easter Egg) as pass/partial/fail.

### 2. Identify Gaps and Prioritize
Prioritize findings by impact:

- **P1 (Critical) -- Accessibility**: Keyboard navigation, touch targets, reduced motion, link descriptions. These affect usability for all users and may have legal compliance implications.
- **P2 (High) -- Design and Motion**: Layout shifts, animation quality, URL state, theme support, CJK handling. These define perceived quality and affect daily user experience.
- **P3 (Enhancement) -- Easter Eggs and Delight**: 404 pages, hidden features, playful interactions. These differentiate but should only be pursued after P1 and P2 are solid.

### 3. Read Relevant Reference Files
For each identified gap, read the corresponding reference file for:
- Why the pattern matters (motivation)
- How to implement it (actionable guidance and code)
- What to check (audit checklist items)

### 4. Implement and Verify
Apply patterns starting with P1, verify each against its audit checklist, and move to the next priority level.

## Attribution

All patterns curated from [detail.design](https://detail.design) by **Rene Wang** (@renedotwang). Individual reference files include source credits for the original designers, developers, and products that inspired each pattern.

Resources referenced include patterns from: Linear, Vercel, Apple, Notion, GitHub, Discord, Obsidian, Figma, Raycast, Google, and LobeHub.
