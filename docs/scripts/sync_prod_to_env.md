# `sync_prod_to_env.sh` — Prod → Dev Data Sync

**Purpose**: Copy all databases and/or files from Acquia prod to dev for selected applications.

**Scope**: Remote — operates on Acquia environments via acli. No local file changes.

> ⚠️ **DESTRUCTIVE**: All dev databases (and optionally files) are fully overwritten with production data. Requires typing `yes` (not just `y`) to confirm. Stg is intentionally excluded as a destination.

**Requires**: `acli` installed and authenticated, and `ACQUIA_ENV_UUID_*_prod` entries populated in `hal_config.txt`.

## Usage

```bash
# Interactive mode:
$ sh ~/Sites/_hal/drupal/acquia/sync_prod_to_env.sh

# CLI mode — confirmation still required:
$ sh ~/Sites/_hal/drupal/acquia/sync_prod_to_env.sh [app] [type]
$ sh ~/Sites/_hal/drupal/acquia/sync_prod_to_env.sh all databases <<< "yes"
$ sh ~/Sites/_hal/drupal/acquia/sync_prod_to_env.sh all files <<< "yes"
$ sh ~/Sites/_hal/drupal/acquia/sync_prod_to_env.sh hud8 both <<< "yes"
```

## Sync Types

| Type | What it does |
|------|-------------|
| `databases` | Copies all multisite DBs via `acli api:environments:database-copy` |
| `files` | Mirrors the files directory via `acli env:mirror --no-databases --no-code --no-config` |
| `both` | Runs databases then files |

## Features

- Copies **all** databases for an app (e.g., all multisite DBs), not just the primary one
- Database copies are queued asynchronously — allow 2–5 min per app before running follow-up commands
- Dev codebase is never touched; Acquia platform config (crons, env vars) is never overwritten
- Per-application error tracking with a pass/fail summary
- Post-run reminder to run `updb` and `cr`

## Recommended Follow-up

After databases sync completes:

```bash
$ sh ~/Sites/_hal/drupal/acquia/update_via_drush.sh all dev updb
$ sh ~/Sites/_hal/drupal/acquia/update_via_drush.sh all dev cr
```

## Notes

- Verify backup completion in the Acquia Cloud UI if needed
- Files sync is important before running visual regression tests — dev images must match prod for accurate baseline comparisons
