# Howard Automation Library (HAL)

The Howard Automation Library (HAL) is a comprehensive collection of bash scripts and automation tools designed to streamline the management of Howard University's Drupal applications across multiple Acquia Cloud environments.

## Overview

HAL provides standardized, interactive scripts for managing five Howard University Drupal applications:
- **@hud8** - Main Howard University site
- **@academicdepartments** - Academic department sites  
- **@howardenterprise** - Enterprise sites
- **@centers** - Center and institute sites
- **@uxws** - UX/Web Services sites

All scripts feature a consistent, user-friendly interface with flexible targeting options and built-in safety confirmations. HAL includes enhanced support for Drupal 11 with specialized scripts for managing deprecated modules and database compatibility issues.

## Quick Reference

### Monthly Update Steps

1. **Sync prod databases and files to dev** — copies every multisite database and the files directory from prod → dev on Acquia. Requests are queued asynchronously (~2–5 min per app), so fire this first and let it run in the background while you complete the next steps. Syncing files ensures dev images and assets match prod, which is important for accurate regression test results:
   `$ sh ~/Sites/_hal/drupal/acquia/sync_prod_to_env.sh all databases`
   `$ sh ~/Sites/_hal/drupal/acquia/sync_prod_to_env.sh all files`

2. **Backup all prod databases** — creates a snapshot of every prod database before any code or schema changes land. Runs async; verify completion in Acquia Cloud UI if needed. Optionally also run against stg to capture any in-progress work on ongoing stg sites:
   `$ sh ~/Sites/_hal/drupal/acquia/backup_databases.sh all prod`
   `$ sh ~/Sites/_hal/drupal/acquia/backup_databases.sh all stg` *(optional)*

3. **Pull latest code for all local apps** — ensures your local repos are on the latest master before running composer updates:
   `$ sh ~/Sites/_hal/drupal/acquia/pull_all.sh`

4. **Update all core, contrib, and Howard packages** — runs composer update for Drupal core, all contrib modules/themes, and all Howard packages across every local app. When prompted, say **YES** to commit and push to master. This pushes the updated composer.json/lock to git and Acquia automatically deploys it to dev:
   `$ sh ~/Sites/_hal/drupal/acquia/update_all.sh`

5. **Run database updates + cache rebuild on dev** — by now the DB copies from step 1 should be complete. `updb` applies any pending schema/data updates introduced by the new code; `cr` clears all caches so Drupal picks up the updated configuration and code:
   `$ sh ~/Sites/_hal/drupal/acquia/update_via_drush.sh all dev updb`
   `$ sh ~/Sites/_hal/drupal/acquia/update_via_drush.sh all dev cr`

6. **QC — Status check on dev** — performs an HTTP health check against every dev site URL across all apps. Review the output carefully. **Any errors (5xx, 000, maintenance mode, Drupal error pages) must be investigated and resolved before proceeding.** Do not move to stg until all issues are accounted for:
   `$ sh ~/Sites/_hal/drupal/acquia/site_status_check.sh all dev`

7. **QC — Visual regression tests on dev** *(experimental)* — captures full-page screenshots of every prod site as baselines, then pixel-diffs dev against them. Requires that the files sync from step 1 has completed so dev images match prod. Run one app at a time; the `both` action handles baseline capture + comparison in one step. Review `comparison.html` for any unexpected layout changes before deploying:
   `$ sh ~/Sites/_hal/drupal/acquia/regression_test.sh hud8 dev prod both`
   `$ sh ~/Sites/_hal/drupal/acquia/regression_test.sh academicdepartments dev prod both`
   `$ sh ~/Sites/_hal/drupal/acquia/regression_test.sh howardenterprise dev prod both`
   `$ sh ~/Sites/_hal/drupal/acquia/regression_test.sh centers dev prod both`
   `$ sh ~/Sites/_hal/drupal/acquia/regression_test.sh uxws dev prod both`

8. **Run database updates + cache rebuild on stg** — stg does not have 1:1 prod databases (it may have in-progress work from clients), but running updb/cr here ensures stg code is in sync with any schema changes introduced by the update:
   `$ sh ~/Sites/_hal/drupal/acquia/update_via_drush.sh all stg updb`
   `$ sh ~/Sites/_hal/drupal/acquia/update_via_drush.sh all stg cr`

9. **QC — Status check on stg** — same health check as step 6 but against stg URLs. Stg sites may legitimately be in maintenance mode or have in-progress work, so use judgment. **Any unexpected errors or Drupal fatal errors must be resolved before deploying to prod:**
   `$ sh ~/Sites/_hal/drupal/acquia/site_status_check.sh all stg`

10. **Deploy to prod** — creates a date-based git tag on master and switches every prod environment to that tag via acli. Only run this when both dev and stg QC have passed:
    `$ sh ~/Sites/_hal/drupal/acquia/acquia_code_deploy.sh all`

11. **Run database updates + cache rebuild on prod** — same as step 5 but targeting prod. Applies any pending schema updates and clears caches so live traffic is served by the new code immediately:
    `$ sh ~/Sites/_hal/drupal/acquia/update_via_drush.sh all prod updb`
    `$ sh ~/Sites/_hal/drupal/acquia/update_via_drush.sh all prod cr`

12. **QC — Status check on prod** — final health check against all live prod URLs. **Every error must be investigated and resolved before closing the ticket.** A 5xx, connection failure, or Drupal error page on prod is a live site outage:
    `$ sh ~/Sites/_hal/drupal/acquia/site_status_check.sh all prod`

13. **Post status report** — paste the prod status check output (or a summary) into the ticket, along with other notes and mark complete.

### Most Common Commands

```bash
# Universal drush command runner (cache rebuild, module enable, db updates, etc.)
$ sh ~/Sites/_hal/drupal/acquia/update_via_drush.sh

# Update configuration values (site settings, etc.)
$ sh ~/Sites/_hal/drupal/acquia/acquia_config_set.sh

# Remove lingering module database references
$ sh ~/Sites/_hal/drupal/acquia/remove_deprecated_modules.sh

# List users, webforms, webform email handlers, news feeds, or magazine feeds across sites
$ sh ~/Sites/_hal/drupal/acquia/list.sh

# Check HTTP status of all sites (prod, stg, dev) for selected apps/environments
$ sh ~/Sites/_hal/drupal/acquia/site_status_check.sh

# Sync prod databases and/or files to dev for selected apps (DESTRUCTIVE)
$ sh ~/Sites/_hal/drupal/acquia/sync_prod_to_env.sh

# Backup all databases for selected apps/environment
$ sh ~/Sites/_hal/drupal/acquia/backup_databases.sh

# Search for a node or menu link title across all apps/environments
$ sh ~/Sites/_hal/drupal/acquia/node_search.sh

# Pull current config from any Acquia environment to local codebases (clean mirror)
$ sh ~/Sites/_hal/drupal/acquia/pull_config_from_env.sh

# Deploy code to production environments
$ sh ~/Sites/_hal/drupal/acquia/acquia_code_deploy.sh

# Visual regression tests — compare dev vs prod screenshots  [EXPERIMENTAL]
$ sh ~/Sites/_hal/drupal/acquia/regression_test.sh

# Pull latest code for all local Howard D8 applications
$ sh ~/Sites/_hal/drupal/acquia/pull_all.sh

# Full update (core + contrib + Howard packages) across all local Howard D8 applications
$ sh ~/Sites/_hal/drupal/acquia/update_all.sh

# Update Drupal core across all local Howard D8 applications
$ sh ~/Sites/_hal/drupal/acquia/update_drupal_core.sh

# Update all Drupal contrib modules/themes across all local Howard D8 applications
$ sh ~/Sites/_hal/drupal/acquia/update_drupal_contrib.sh

# Update all Howard packagist repos across all local Howard D8 applications
$ sh ~/Sites/_hal/drupal/acquia/update_howard_packages.sh
```

### Targeting Options (Available in drush-based scripts)

Most scripts support optional CLI arguments to skip interactive prompts entirely — useful for pasting commands directly. See each script's doc section for accepted args.

The following scripts use an interactive targeting system when run without args (`update_via_drush.sh`, `acquia_config_set.sh`, `remove_deprecated_modules.sh`, `list.sh`, `acquia_code_deploy.sh`, `site_status_check.sh`, `sync_prod_to_env.sh`, `backup_databases.sh`):

1. **Single App + Single Env** → Precise targeting (e.g., @hud8 dev only)
2. **Single App + All Envs** → App-wide (e.g., @hud8 across dev/test/prod)  
3. **All Apps + Single Env** → Environment-wide (e.g., all apps on test)
4. **All Apps + All Envs** → System-wide (use with extreme caution)

The composer-based scripts (`update_drupal_core.sh`, `update_howard_packages.sh`) operate on all local folders defined in `hal_config.txt` and prompt only about git commit/push — they do not use the targeting system above.

## Installation

### 1. Clone Repository

Clone this repo into your ~/Sites folder as "_hal":

```bash
cd ~/Sites
git clone https://github.com/howard-university-web-services/Howard-Automation-Library.git _hal
```


### 2. Configure Local Settings

Create and customize your local configuration:

```bash
cd ~/Sites/_hal
cp hal_config.default.txt hal_config.txt
```

Edit `hal_config.txt` to configure:

- **Local Drush Installation** - Path to your Drush executable
- **Howard D8 Folder Paths** - Absolute paths to your local Howard application folders
- **Drush Aliases** - Your local Acquia Cloud drush aliases
- **Acquia Prod Environment IDs** - Required for `acquia_code_deploy.sh` (see below)

### 3. Configuration Details

#### Acquia Environment UUIDs

Required for `acquia_code_deploy.sh`. After installing and authenticating acli, find your environment UUIDs:

```bash
acli api:applications:environment-list <your-app-uuid>
```

Fill in the `ACQUIA_ENV_UUID_*_prod` entries in `hal_config.txt` with the prod environment ID for each app.

#### Setting a local drush

- Set `LOCAL_DRUSH` to the path of the Drush executable installed as a Composer dependency in your local `hud8` folder.
- Example: `LOCAL_DRUSH="/path/to/hud8/vendor/bin/drush"`

#### Finding your local Howard D8 folders

- Set each `LOCAL_HOWARD_D8_FOLDERS[n]` to the absolute path of the corresponding local application root.
- Run `pwd` inside the folder to get the exact path.
- Example: `LOCAL_HOWARD_D8_FOLDERS[0]="/path/to/hud8"`

#### Finding your local drush aliases

- Run `drush sa` for a list of current drush aliases.
- You should see `@cl.prod_academicdepartments.dev.dev` or `academicdepartments.dev` and `@cl.prod_hud8.dev.dev` or `hud8.dev`, with others for stg and prod installs of each. These would be added as `@cl.prod_academicdepartments`, leaving off the env connotation, as we set that in a choice per script, so that you may choose in the script which env to run them on.
- LOCAL_HOWARD_D8_DRUSH_ALIAS[0] = Your local hud8 alias.
- LOCAL_HOWARD_D8_DRUSH_ALIAS[1] = Your local academicdepartments alias.
- LOCAL_HOWARD_D8_DRUSH_ALIAS[2] = Your local howardenterprise alias.
- LOCAL_HOWARD_D8_DRUSH_ALIAS[3] = Your local centers alias.
- LOCAL_HOWARD_D8_DRUSH_ALIAS[4] = Your local uxws alias.

### Requirements

Be sure the following are up and running correctly on your local machine:

- [Drush](https://docs.drush.org/en/master/install/)
- [Acquia CLI (acli)](https://docs.acquia.com/acquia-cli/) — required for `acquia_code_deploy.sh`
  - Install: `brew install acquia/acquia-cli/acli`
  - Authenticate: `acli auth:login`

## Updating HAL

Use git to keep this library up date on your local machine.

- `cd ~/Sites/_hal`
- `git pull`

## Usage

### Basic Script Execution

```bash
# Navigate to HAL directory (recommended)
cd ~/Sites/_hal

# Run any HAL script
sh ./drupal/acquia/script_name.sh

# Or run from anywhere with full path
sh ~/Sites/_hal/drupal/acquia/script_name.sh
```

### Best Practices

- ✅ **Always test first** - Use dev environment before test/prod
- ✅ **Review targeting** - Double-check your scope selection before confirming
- ✅ **Single operations** - Prefer precise targeting over system-wide updates  
- ✅ **Keep HAL updated** - Run `git pull` regularly to get latest improvements
- ✅ **Monitor output** - Watch for errors or unexpected behavior
- ❌ **Never use sudo** - Scripts should run with your user permissions

### Safety Features

All HAL scripts include built-in safety measures:

- **Interactive Confirmation** - Scripts show what they will do and ask for confirmation
- **Clear Targeting Display** - See exactly which apps/environments will be affected
- **Input Validation** - Invalid selections are caught and rejected
- **Progress Feedback** - Real-time status updates during execution

### Troubleshooting

**Script fails to select application:**
- Check that `LOCAL_HOWARD_D8_FOLDERS` paths exist in `hal_config.txt`
- Verify folders are accessible and contain valid Drupal installations

**Drush commands fail:**
- Verify `LOCAL_DRUSH` path is correct in `hal_config.txt`
- Check that drush aliases are properly configured with `drush sa`

**Git operations fail:**
- Ensure you're on the master branch and it's up to date
- Check that you have proper permissions to push to the repository

**Acquia deployments fail:**
- Verify `acli` is installed (`brew install acquia/acquia-cli/acli`) and authenticated (`acli auth:login`)
- Check that `ACQUIA_ENV_UUID_*_prod` entries are populated in `hal_config.txt`
- Confirm you have deployment permissions for the target application

## Script Reference

Full documentation for each script is in [docs/scripts/](docs/scripts/).

| Script | Type | Description |
|--------|------|-------------|
| [`update_via_drush.sh`](docs/scripts/update_via_drush.md) | Remote | Run any drush command across apps/environments |
| [`site_status_check.sh`](docs/scripts/site_status_check.md) | Remote | HTTP health check against all sites |
| [`sync_prod_to_env.sh`](docs/scripts/sync_prod_to_env.md) | Remote | Copy prod databases and/or files to dev ⚠️ destructive |
| [`backup_databases.sh`](docs/scripts/backup_databases.md) | Remote | Create Acquia database backups |
| [`acquia_code_deploy.sh`](docs/scripts/acquia_code_deploy.md) | Remote | Tag master and deploy to prod |
| [`pull_config_from_env.sh`](docs/scripts/pull_config_from_env.md) | Local+Remote | Export config from Acquia and rsync to local |
| [`acquia_config_set.sh`](docs/scripts/acquia_config_set.md) | Remote | Update a specific config value via drush config:set |
| [`remove_deprecated_modules.sh`](docs/scripts/remove_deprecated_modules.md) | Remote | Clean up lingering database entries for removed modules |
| [`list.sh`](docs/scripts/list.md) | Remote | List users, webforms, feeds across sites |
| [`node_search.sh`](docs/scripts/node_search.md) | Remote | Search node/menu link titles across all apps |
| [`regression_test.sh`](docs/scripts/regression_test.md) | Local | Visual regression tests (Playwright) ⚠️ experimental |
| [`update_all.sh`](docs/scripts/update_all.md) | Local | Full composer update: core + contrib + Howard packages |
| [`pull_all.sh`](docs/scripts/update_all.md) | Local | Pull latest master for all local app folders |
| [`create_new_multisite.sh`](docs/scripts/create_new_multisite.md) | Local+Remote | Scaffold a new multisite install |

### Architecture Notes

HAL uses a shared selection component (`partials/select_app_and_env.sh`) for consistent targeting across all scripts. Each Howard application maps to a local folder index and an Acquia drush alias configured in `hal_config.txt`:

| Application | `hal_config.txt` index | Environments |
|-------------|------------------------|--------------|
| @hud8 | `LOCAL_HOWARD_D8_FOLDERS[0]` | dev / test / prod |
| @academicdepartments | `LOCAL_HOWARD_D8_FOLDERS[1]` | dev / test / prod |
| @howardenterprise | `LOCAL_HOWARD_D8_FOLDERS[2]` | dev / test / prod |
| @centers | `LOCAL_HOWARD_D8_FOLDERS[3]` | dev / test / prod |
| @uxws | `LOCAL_HOWARD_D8_FOLDERS[4]` | dev / test / prod |

### How HAL Interacts with Acquia

Since Drush 9 removed the `@sites` alias, HAL uses a server-side script (`scripts/hal_sites.sh` in each codebase) that loops through all `*.howard.edu` site directories and runs the given drush command on each. This script is also used by Acquia cron jobs. See [Acquia cron documentation](https://docs.acquia.com/cloud-platform/manage/cron/#cloud-execute-shell-script) for scheduled task setup.

## User maintenance

The following is a quick guide to disabling uses across all howard ecosystems, if required.

- Run `sh ~/Sites/_hal/drupal/acquia/update_via_drush.sh`, choose environments, and enter drush command when prompted: `user:cancel first.last`.

This will block the user account and reassign all content to the anonymous user.

## Roadmap

### All Howard D8 acquia codebases

- Run composer add on all local codebases. "add the seckit module on all local D8 codebases" **In Progress**
- Commit and push to DEV for all local codebases
- Deploy to prod for all codebases
- You may choose either hud8 or academicdepartments Prod Environment.
