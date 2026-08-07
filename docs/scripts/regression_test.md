# `regression_test.sh` — Visual Regression Testing

> ⚠️ **EXPERIMENTAL**: This script and its underlying Playwright infrastructure are under active development. Behavior, output format, and CLI arguments may change between HAL versions.

**Purpose**: Run Playwright-powered visual regression tests against Howard multisite applications. Captures full-page screenshots of each site in a reference environment (typically prod) as baselines, then pixel-diffs a target environment (typically dev) against those baselines to surface visual regressions — layout shifts, broken styles, missing content, unexpected changes.

**Scope**: Local — Playwright runs entirely on your machine and hits live Acquia URLs. No changes are made to any remote environment.

## Usage

```bash
# Interactive mode:
$ sh ~/Sites/_hal/drupal/acquia/regression_test.sh

# CLI mode — skip all prompts:
$ sh ~/Sites/_hal/drupal/acquia/regression_test.sh [app] [test_env] [baseline_env] [action]
$ sh ~/Sites/_hal/drupal/acquia/regression_test.sh hud8 dev prod both <<< "y"
$ sh ~/Sites/_hal/drupal/acquia/regression_test.sh centers dev prod compare <<< "y"
$ sh ~/Sites/_hal/drupal/acquia/regression_test.sh howardenterprise dev prod baseline <<< "y"
```

## Actions

| Action | What it does |
|--------|-------------|
| `baseline` | Captures screenshots of `baseline_env` and stores them as the reference |
| `compare` | Screenshots `test_env` and pixel-diffs against stored baselines |
| `both` | Runs baseline capture then comparison in one step |

## Workflow

```
# Step 1 — capture prod as the golden reference:
sh regression_test.sh hud8 dev prod baseline

# Step 2 — compare dev against baseline:
sh regression_test.sh hud8 dev prod compare

# Or do both in one step:
sh regression_test.sh hud8 dev prod both
```

## Environment → URL Mapping

| HAL env | URL prefix |
|---------|------------|
| `dev`   | `https://dev.<domain>` |
| `test`  | `https://stg.<domain>` |
| `prod`  | `https://<domain>` |

Shield (`huweb:huweb`) is applied automatically for `dev` and `test`.

## Report

After each comparison run, `playwright/playwright-report/comparison.html` opens automatically. It shows:

- Pass/fail status and duration per site
- Side-by-side **Baseline** vs **Actual** screenshot panes
- **Pixel diff** image (highlighted differences) for failing sites
- Error details (failure reason, stack trace) on expand for failing sites

All accordions start collapsed. Click a row to expand and view screenshots.

## Snapshot Storage

- Baselines: `playwright/snapshots/<app>/` (gitignored, persist between runs)
- Actual screenshots: `playwright/screenshots/<app>/`
- Diff images: `playwright/test-results/`

Delete `playwright/snapshots/<app>/` to force a full baseline recapture.

## Diff Tolerance

Default: 2% of pixels may differ (`maxDiffPixelRatio: 0.02`). Sites with dynamic content (rotating banners, live timestamps) may need a higher value. Edit `playwright/tests/regression.spec.js` to adjust per-site or globally.

## Authenticated Page Testing (optional)

After `sites.json` is first generated, add a `login` block to any site entry:

```json
{
  "domain": "admission.howard.edu",
  "prod_url": "https://admission.howard.edu",
  "dev_url":  "https://dev.admission.howard.edu",
  "test_url": "https://stg.admission.howard.edu",
  "login": {
    "path": "/user/login",
    "username_selector": "#edit-name",
    "password_selector": "#edit-pass",
    "submit_selector":   "#edit-submit",
    "username": "your.user@howard.edu",
    "password": "yourpassword"
  }
}
```

`login` blocks are preserved when `sites.json` is regenerated on subsequent runs.

## Dependencies

- Node.js ≥ 20 — install via `brew install node` or `nvm install 22`
- Playwright and Chromium are installed automatically on first run

## Tips

- **Sync files before running** — run `sync_prod_to_env.sh all files` first so dev images match prod. Missing files on dev are a common cause of false positives.
- **Run one app at a time** — running all apps simultaneously would be very slow.
- **After a legitimate deploy** — re-run `baseline` to update the golden reference so the next comparison reflects the new prod state.
