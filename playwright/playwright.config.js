const { defineConfig, devices } = require('@playwright/test');
const path = require('path');

// HAL_APP_NAME is set by regression_test.sh to scope snapshots per app,
// so baselines for hud8 don't bleed into baselines for centers, etc.
const appName = process.env.HAL_APP_NAME || 'default';

module.exports = defineConfig({
  testDir: './tests',

  // Sequential — avoids hammering Acquia servers in parallel.
  // Increase workers carefully; Acquia rate-limits aggressively.
  fullyParallel: false,
  workers: 2,
  retries: 0,

  reporter: [
    ['html', { outputFolder: 'playwright-report', open: 'never' }],
    ['json', { outputFile: 'playwright-report/results.json' }],
    ['list'],
  ],

  // Baseline screenshots stored per app in playwright/snapshots/<app>/.
  // These are gitignored and persist between runs.
  snapshotDir: path.join(__dirname, 'snapshots', appName),

  use: {
    // Consistent viewport for repeatable screenshots across runs.
    viewport: { width: 1280, height: 900 },

    // Save a screenshot on failure for debugging.
    screenshot: 'only-on-failure',

    // Ignore HTTPS errors — Acquia dev/test certs are commonly self-signed.
    ignoreHTTPSErrors: true,

    // Stop animations so screenshots are deterministic.
    // Playwright sets prefers-reduced-motion: reduce automatically when
    // animations: 'disabled' is set on toHaveScreenshot calls.
    actionTimeout: 30000,

    navigationTimeout: 30000,
  },

  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
});
