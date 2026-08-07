# `acquia_code_deploy.sh` — Code Deployment

**Purpose**: Create Git tags on master and deploy to Acquia prod. Dev and test environments always stay on master.

**Scope**: Remote — modifies git tags and switches Acquia prod environments via acli.

**Requires**: `acli` installed and authenticated (`acli auth:login`), and `ACQUIA_ENV_UUID_*_prod` entries populated in `hal_config.txt`.

## Usage

```bash
# Interactive mode:
$ sh ~/Sites/_hal/drupal/acquia/acquia_code_deploy.sh

# CLI mode:
$ sh ~/Sites/_hal/drupal/acquia/acquia_code_deploy.sh [app]
$ sh ~/Sites/_hal/drupal/acquia/acquia_code_deploy.sh all
$ sh ~/Sites/_hal/drupal/acquia/acquia_code_deploy.sh hud8
```

## Process (per application)

1. Pulls latest master
2. Creates a date-based Git tag (e.g., `2026-05-08`, or `2026-05-08.1` if the tag already exists)
3. Pushes master and the new tag to the remote
4. Switches the prod environment to that tag via `acli api:environments:code-switch`

## Prerequisites

- Be on the master branch with a clean, up-to-date working tree
- All QC checks (status check, regression tests) must have passed on both dev and stg
- `acli` authenticated: `acli auth:login`
- `ACQUIA_ENV_UUID_*_prod` entries populated in `hal_config.txt`

## Finding Acquia Environment UUIDs

```bash
acli api:applications:environment-list <your-app-uuid>
```

Fill in the `ACQUIA_ENV_UUID_*_prod` entries in `hal_config.txt` with the prod environment ID for each app.

## Notes

- Always targets prod only — dev and stg are never touched by this script
- Dev and stg environments stay on the `master` branch and pick up changes automatically when code is pushed
