# Template: `tests/seed.spec.ts`

Full file body for the seed spec — project-specific fixtures for auth setup and
base URL configuration, plus a seed test. Used by `qa:setup` Phase 6.

```typescript
import { test as base, expect, type Page } from '@playwright/test';

// Extend base test with project-specific fixtures
export const test = base.extend<{
  authenticatedPage: Page;
}>({
  authenticatedPage: async ({ page }, provide) => {
    // Auth setup — adapt to your auth strategy
    // strategy: none — no setup needed
    // strategy: credentials — navigate to login and fill credentials
    // strategy: token — set Authorization header
    // strategy: cookie — set session cookie

    // Example for 'none' strategy:
    await page.goto('/');
    await provide(page);
  },
});

export { expect };

// Seed test — verifies the test setup is working
test('app loads successfully', async ({ page }) => {
  await page.goto('/');
  await expect(page).toHaveTitle(/.+/);
});
```
