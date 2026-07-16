# Mode 1: Sitemap Scan

Load when `/qa:discover --scan`.

## Mode 1: Sitemap Scan (`--scan`)

Systematically explore the running application to build a feature map organized by priority tier.

### Step 1: Launch Browser and Navigate

Use the browser tooling from @use-browser (Chrome DevTools MCP, or the agent-browser CLI) to open the app:

1. Navigate to `base_url` from config using `navigate_page` (it awaits page load)
2. If the config has a `bridge` section with a `shim_path`, inject the bridge shim now using `evaluate_script` — note it applies to the current page only, so re-inject after any full navigation
3. Take a snapshot with `take_snapshot` to capture initial navigation structure

### Step 2: Authenticate (if needed)

If `auth.strategy` is `credentials`:

1. Navigate to `auth.login_url` using `navigate_page`
2. Use `fill_form` to fill credentials from config (resolve password from env var)
3. Click the submit button using `click` with the button's `uid` from the snapshot
4. Verify authentication succeeded with `take_snapshot`, then checking for redirect or user indicator

### Step 3: Explore Navigation

Systematically discover the app's structure:

1. Take a snapshot of the main page using `take_snapshot`
2. Identify all navigation elements (nav bars, sidebars, menus, tabs) from their snapshot `uid`s
3. For each top-level navigation link:
   - Click it using `click` with its `uid`
   - Run `take_snapshot`
   - Record the URL path, page title, and key interactive elements (forms, buttons, tables, modals)
   - Identify sub-navigation if present and follow one level deep
4. Look for common patterns:
   - Auth pages (login, register, forgot password)
   - Dashboard / home
   - CRUD resource pages (list, detail, create, edit)
   - Settings / profile / account pages
   - Search functionality
   - Admin sections

### Step 4: Build Feature Map by Priority Tier

Organize discoveries into functional areas, grouped by priority:

```markdown
# Sitemap: [App Name]

Scanned: [timestamp]
Base URL: [base_url]

## P0 — Data Loss Prevention

Features where failure could cause permanent data loss or corruption.

- [Feature] (`/path`) — [why data-loss risk]

## P1 — Core Flows

Features that must work for the app to be usable.

### [area-name]
- [Page] (`/path`) — [key elements]

## P2 — Advanced Features

Important features that power users rely on.

### [area-name]
- [Page] (`/path`) — [key elements]

## P3 — Edge Cases

Boundary conditions and unusual but valid scenarios.

- [Feature] — [edge case description]
```

### Step 5: Save Sitemap

Write the feature map to `specs/_sitemap.md`.

### Step 6: Present Results

Show the user the discovered areas and suggest next steps:

```
Discovered [N] functional areas with [M] total pages.

Priority breakdown:
  P0 (data-loss): [n] features
  P1 (core):      [n] features
  P2 (advanced):  [n] features
  P3 (edge):      [n] features

Next steps:
  Run interactive discovery for each area to create NL specs:
    /qa:discover auth
    /qa:discover dashboard
    ...

  Start with P0 and P1 features for maximum coverage impact.
```

---

