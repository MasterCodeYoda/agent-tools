// Generated Playwright test for login flow
// VIOLATION QCV-05: Stale test — references old selector

import { test, expect } from "@playwright/test";

test("user can log in", async ({ page }) => {
  await page.goto("/login");

  // STALE: App was refactored — data-testid changed from "login-form" to "auth-form"
  // This selector will fail with "element not found"
  await page.locator('[data-testid="login-form"]').waitFor();

  await page.fill('[name="email"]', "user@example.com");
  await page.fill('[name="password"]', "password123");
  await page.click('button[type="submit"]');

  await expect(page).toHaveURL("/dashboard");
});
