# `pull_config_from_env.sh` — Pull Config from Acquia to Local

**Purpose**: Export active Drupal configuration from any Acquia environment and rsync it to the matching local `config/` directory. Uses `--delete` so each pull is a clean mirror of the remote state.

**Scope**: Local + Remote — modifies local config files. No changes are made to Acquia environments.

## Usage

```bash
# Interactive mode:
$ sh ~/Sites/_hal/drupal/acquia/pull_config_from_env.sh

# CLI mode — skip all prompts:
$ sh ~/Sites/_hal/drupal/acquia/pull_config_from_env.sh [app] [env]
$ sh ~/Sites/_hal/drupal/acquia/pull_config_from_env.sh all prod
$ sh ~/Sites/_hal/drupal/acquia/pull_config_from_env.sh hud8 stg
$ sh ~/Sites/_hal/drupal/acquia/pull_config_from_env.sh uxws dev
```

## Features

- All four targeting options available
- Discovers live `AH_SITE_NAME` dynamically — works correctly for non-standard paths (uxws, centers)
- Exports via direct SSH (not drush ssh) to handle multiline bash safely on read-only Acquia filesystems
- Temp exports to `/tmp/hal_config_export_{app}/` (writable on Acquia), cleaned up after sync
- `--delete` rsync — stale local `.yml` files not present in the remote export are removed; `.htaccess` and `README.txt` are preserved
- Per-app error tracking with a pass/fail summary

## Recommended Follow-up

```bash
# Review what changed before committing
git diff config/

# Commit the updated config
git add config/ && git commit -m 'Sync config from prod'

# Import config into a local site if needed
drush config:import --partial -y
```

## Notes

> ⚠️ Sites that fail `drush cex` (e.g., `cms-training.howard.edu` when the DB can't be bootstrapped) are skipped. Check the error summary at the end of the run and investigate those sites separately.
