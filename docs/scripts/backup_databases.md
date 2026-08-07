# `backup_databases.sh` — Database Backups

**Purpose**: Create Acquia database backups for all databases in the selected applications and environment.

**Scope**: Remote — queues backup jobs on Acquia via acli. No local file changes.

**Requires**: `acli` installed and authenticated, and `ACQUIA_ENV_UUID_*_prod` entries populated in `hal_config.txt`.

## Usage

```bash
# Interactive mode:
$ sh ~/Sites/_hal/drupal/acquia/backup_databases.sh

# CLI mode — confirmation still required:
$ sh ~/Sites/_hal/drupal/acquia/backup_databases.sh [app] [env]
$ sh ~/Sites/_hal/drupal/acquia/backup_databases.sh all prod
$ sh ~/Sites/_hal/drupal/acquia/backup_databases.sh hud8 prod
$ sh ~/Sites/_hal/drupal/acquia/backup_databases.sh all stg
```

## Features

- Single Application or All Applications scope
- Any environment: dev, test, or prod
- Backs up **all** databases for an app (not just the primary one)
- Backup requests are queued asynchronously — verify completion in the Acquia Cloud UI
- Per-application error tracking with a pass/fail summary

## When to Run

- **Before every update cycle** — back up prod before deploying new code
- **Before destructive operations** — any time you're about to run a sync, schema change, or module uninstall on prod
- **Optionally on stg** — to snapshot in-progress client work before it could be affected

## Verify Backups

Acquia Cloud UI → your app → Databases → Backups
