# Template: `playwright.config.ts`

Full file body for the project-root `playwright.config.ts` with bridge shim support
and reporter configuration, plus the partitioned-bridge projects variant. Used by
`qa:setup` Phase 5.

## Base config

```typescript
import { defineConfig, devices } from '@playwright/test';
import * as fs from 'fs';

// Bridge shim injection (for Tauri apps tested via HTTP bridge)
// Set SENTINEL_BRIDGE_SHIM to the path of the bridge inject script
const bridgeShimPath = process.env.SENTINEL_BRIDGE_SHIM;
const bridgeShim = bridgeShimPath && fs.existsSync(bridgeShimPath)
  ? fs.readFileSync(bridgeShimPath, 'utf-8')
  : undefined;

export default defineConfig({
  testDir: './tests',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: [
    ['html'],
    ['list'],
  ],
  use: {
    baseURL: process.env.SENTINEL_BASE_URL || '{base_url}',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    ...(bridgeShim ? { initScripts: [bridgeShim] } : {}),
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
});
```

## Partitioned bridge execution — per-partition project entries

```typescript
projects: [
  {
    name: 'workspace-pages',
    use: {
      ...devices['Desktop Chrome'],
      baseURL: 'http://localhost:9990',
    },
    testMatch: '**/workspace-*.spec.ts',
  },
  {
    name: 'editor-content',
    use: {
      ...devices['Desktop Chrome'],
      baseURL: 'http://localhost:9991',
    },
    testMatch: '**/editor-*.spec.ts',
  },
],
```
