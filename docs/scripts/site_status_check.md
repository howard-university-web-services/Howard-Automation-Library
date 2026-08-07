# `site_status_check.sh` — HTTP Site Status Check

**Purpose**: Perform a comprehensive HTTP health check against every Howard multisite URL for the selected applications and environments.

**Scope**: Remote — all checks hit live Acquia URLs. No local file changes.

## Usage

```bash
# Interactive mode:
$ sh ~/Sites/_hal/drupal/acquia/site_status_check.sh

# CLI mode — skip all prompts:
$ sh ~/Sites/_hal/drupal/acquia/site_status_check.sh [app] [env] [nav]
$ sh ~/Sites/_hal/drupal/acquia/site_status_check.sh all prod
$ sh ~/Sites/_hal/drupal/acquia/site_status_check.sh hud8 prod y
$ sh ~/Sites/_hal/drupal/acquia/site_status_check.sh all dev
```

## Features

- All four targeting options available
- Site discovery from local `docroot/sites/*.howard.edu` folders (not `sites.php`)
- HTTP Basic Auth (`huweb:huweb`) applied automatically on every request
- SSL certificate verification skipped for dev/test (Acquia dev/stg certs are commonly expired/self-signed)
- Follows redirects — 2xx/3xx = UP (green ✓), all others flagged (red ✗)
- Per-homepage checks: HTTP status, response time, page `<title>`, Shield status, maintenance mode, Drupal error page detection
- Optional nav page sampling: up to 3 level-1 + 3 level-2 internal pages per site
- Dual end-of-run summary: content warnings list + flagged URL list

## Environment → URL Mapping

| HAL env | URL prefix |
|---------|------------|
| `dev`   | `https://dev.<domain>` |
| `test`  | `https://stg.<domain>` |
| `prod`  | `https://<domain>` |

## Shield Status

Shield is the Drupal HTTP Basic Auth module used to gate non-production environments. The script evaluates Shield state differently by environment:

| Environment | Expected State | Actual: Shield UP | Actual: Shield DOWN |
|-------------|---------------|-------------------|---------------------|
| `dev` / `test` | UP (401 no-auth) | ✓ green | ⚠ warning — publicly accessible |
| `prod` | DOWN (public) | ⚠ warning — may be accidentally gated | ✓ green |

Detection: a HEAD request is made *without* credentials before each main GET. A `401` response means Shield is active.

## Nav Page Sampling (optional)

When enabled, after each successful homepage check the script:

1. Parses all `href` attributes from the fetched homepage body
2. Filters to internal relative paths, excluding system paths (`/admin`, `/user`, `/node/`, etc.) and static assets
3. Groups by URL depth — level 1 (`/segment`) and level 2 (`/segment/segment`)
4. Randomly selects up to 3 paths from each group
5. Checks each for: HTTP status, response time, page title, maintenance mode, and Drupal errors

> **Performance note**: nav sampling adds up to 6 additional curl requests per site per environment. For a full sweep across 100+ sites this significantly increases runtime. Scope to a single app or prod-only when using nav sampling.

## Output Format

```
=== admission.howard.edu ===
  ✓ [200] https://admission.howard.edu (0.84s)
    ↳ Title: Undergraduate Admissions | Howard University
    ↳ Shield: DOWN
    ↳ Nav sample (level 1):
      ✓ [200] https://admission.howard.edu/apply (0.71s)
      ✓ [200] https://admission.howard.edu/visit (0.66s)
    ↳ Nav sample (level 2):
      ✓ [200] https://admission.howard.edu/tuition/scholarships (0.79s)
      ⚠ MAINTENANCE MODE
```

## Status Code Reference

| Code | Meaning |
|------|---------|
| `000` | Connection failure, DNS error, or request timeout |
| `401` | Authenticated request rejected (Shield credential mismatch) |
| `4xx` | Client error (404 Not Found, 403 Forbidden, etc.) |
| `5xx` | Server error (Drupal crash, PHP fatal, database issue) |
