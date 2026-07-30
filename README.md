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

1. **Sync prod databases to dev** — copies every multisite database from prod → dev on Acquia. Requests are queued asynchronously (~2–5 min per app), so fire this first and let it run in the background while you complete the next steps:
   `$ sh ~/Sites/_hal/drupal/acquia/sync_prod_to_env.sh all databases`

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

7. **Run database updates + cache rebuild on stg** — stg does not have 1:1 prod databases (it may have in-progress work from clients), but running updb/cr here ensures stg code is in sync with any schema changes introduced by the update:
   `$ sh ~/Sites/_hal/drupal/acquia/update_via_drush.sh all stg updb`
   `$ sh ~/Sites/_hal/drupal/acquia/update_via_drush.sh all stg cr`

8. **QC — Status check on stg** — same health check as step 6 but against stg URLs. Stg sites may legitimately be in maintenance mode or have in-progress work, so use judgment. **Any unexpected errors or Drupal fatal errors must be resolved before deploying to prod:**
   `$ sh ~/Sites/_hal/drupal/acquia/site_status_check.sh all stg`

9. **Deploy to prod** — creates a date-based git tag on master and switches every prod environment to that tag via acli. Only run this when both dev and stg QC have passed:
   `$ sh ~/Sites/_hal/drupal/acquia/acquia_code_deploy.sh all`

10. **Run database updates + cache rebuild on prod** — same as step 5 but targeting prod. Applies any pending schema updates and clears caches so live traffic is served by the new code immediately:
    `$ sh ~/Sites/_hal/drupal/acquia/update_via_drush.sh all prod updb`
    `$ sh ~/Sites/_hal/drupal/acquia/update_via_drush.sh all prod cr`

11. **QC — Status check on prod** — final health check against all live prod URLs. **Every error must be investigated and resolved before closing the ticket.** A 5xx, connection failure, or Drupal error page on prod is a live site outage:
    `$ sh ~/Sites/_hal/drupal/acquia/site_status_check.sh all prod`

12. **Post status report** — paste the prod status check output (or a summary) into the ticket, along with other notes and mark complete.

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

## Architecture

### Standardized Selection System

HAL uses a modular architecture with a shared selection component (`partials/select_app_and_env.sh`) that provides consistent targeting across all scripts. This ensures:

- **Unified Interface** - All scripts use the same selection menus and terminology
- **Flexible Targeting** - Four targeting patterns cover all operational needs
- **Code Reusability** - Selection logic is centralized and maintained in one place
- **Consistent Safety** - All scripts inherit the same confirmation and validation patterns

### Application Mapping

HAL automatically maps application selections to local folders and Acquia aliases:

| Application | Local Folder Index | Typical Use Case |
|-------------|-------------------|------------------|
| @hud8 | LOCAL_HOWARD_D8_FOLDERS[0] | Main university site |
| @academicdepartments | LOCAL_HOWARD_D8_FOLDERS[1] | Department sites |
| @howardenterprise | LOCAL_HOWARD_D8_FOLDERS[2] | Enterprise/business sites |
| @centers | LOCAL_HOWARD_D8_FOLDERS[3] | Centers and institutes |
| @uxws | LOCAL_HOWARD_D8_FOLDERS[4] | UX/Web Services sites |

### Environment Structure

Each Howard application has three environments:
- **dev** - Development environment for testing
- **test** - Staging environment for client review
- **prod** - Production environment serving live traffic

### Script Categories

**Remote** (connects to Acquia environments via drush/acli — no local file changes):
- `update_via_drush.sh` — Universal drush command runner
- `acquia_config_set.sh` — Configuration value updates via drush config:set
- `remove_deprecated_modules.sh` — Module database cleanup
- `list.sh` — Data listing across sites
- `site_status_check.sh` — HTTP status check for all sites across environments
- `sync_prod_to_env.sh` — Sync prod databases and/or files to dev (destructive)
- `backup_databases.sh` — Create backups of all databases for selected apps/env
- `acquia_code_deploy.sh` — Code deployment to prod via acli

**Local** (operates on your local machine — modifies files and git branches via composer):
- `pull_all.sh` — Pull latest code for all local app folders
- `update_all.sh` — Full update: core + contrib + Howard packages
- `update_drupal_core.sh` — Drupal core updates
- `update_drupal_contrib.sh` — Drupal contrib module and theme updates
- `update_howard_packages.sh` — Howard packagist updates

**Local + Remote** (creates local files, then connects to Acquia):
- `create_new_multisite.sh` — New multisite scaffolding
- `pull_config_from_env.sh` — Export config from any Acquia env and rsync to local codebases

## How this interacts with the acquia server

Since drush 9 and above does away with the @sites alias, we needed to create a script on the server that essentially loops through all sites on an install, and runs drush commands/etc. This script is located in each codebase, under `scripts/hal_sites.sh`. It is interacted with, both through this library, and via CRON scheduled jobs on acquia. For scheduled jobs, see the [acquia documentation](https://docs.acquia.com/cloud-platform/manage/cron/#cloud-execute-shell-script). At its essence, it provides a way to run the same drush command on all multi-sites within an environment.

### Example script on server, scripts/hal_sites.sh

```sh
  #!/bin/bash

  # Provide the absolute path to the sites directory.
  SITES="/var/www/html/${AH_SITE_NAME}/docroot/sites"

  # Validate and hint if no argument provided.
  if [ "${#}" -eq 0 ]; then
    echo "drush: missing argument(s). Please add the drush command you wish to run on all sites."
    echo "The 'drush' will be added automatically, please only add the actual command desired. EXAMPLE: cex -y"
  else
    cd "${SITES}"
    # Loop:
    for SITE in $(ls -d */ | cut -f1 -d'/'); do
      # Skip default sites, only run for howard url's.
      if [[ "${SITE}" == *".howard.edu"* ]]; then
        echo "======================================"
        echo "Running command: drush -l ${SITE} ${@} -y"
        echo "======================================"
        drush -l "${SITE}" "${@}" -y | awk '{print "["strftime("\%Y-\%m-\%d \%H:\%M:\%S \%Z")"] "$0}' &>> /var/log/sites/${AH_SITE_NAME}/logs/$(hostname -s)/drush-cron.log
      fi
    done
  fi
```

### Usage of server hal_sites.sh

When running this script, 'drush' and the '-y' flag, are automatically added to the drush command you wish to run. It is quite important to "not use command aliases" with this script. e.g. use "pm:enable" not "en". Related too [this issue](https://github.com/drush-ops/drush/issues/3025) if curious as to why.

- From root folder on acquia server, check status: `bash scripts/hal_sites.sh status`. In this instance, 'status' is the drush command to run.
- From root folder on acquia server, clear cache: `bash scripts/hal_sites.sh cr`. In this instance, 'cr' is the drush command to run.
- From scheduled task runner on acquia: `bash /var/www/html/${AH_SITE_NAME}/scripts/hal_sites.sh cr`. Clears caches on all sites in install, to run hourly or whatever desired.

## Core HAL Scripts

### Standardized Targeting System

All HAL scripts now use a consistent, standardized interface for targeting Howard applications and environments. Every script offers four flexible targeting options:

1. **Single Application + Single Environment** - Precise targeting for specific tasks
2. **Single Application + All Environments** - Application-wide updates (dev, test, prod)  
3. **All Applications + Single Environment** - Environment-wide updates across all apps
4. **All Applications + All Environments** - System-wide updates (use with caution)

Each script includes:
- ✅ **Interactive Selection** - Clear menus for choosing scope
- ✅ **Confirmation Prompts** - Safety checks before execution
- ✅ **Clear Feedback** - Shows exactly what will be targeted
- ✅ **Error Handling** - Validates selections and provides helpful messages

### Main Automation Scripts

#### `update_via_drush.sh` - Universal Drush Command Runner

**Purpose**: Execute any drush command with flexible targeting across Howard applications and environments.

**Features**:
- All four targeting options available
- Safety confirmation before execution  
- Supports any valid drush command
- Clear feedback on what will be targeted

**Usage**:
```bash
# Interactive mode:
$ sh ~/Sites/_hal/drupal/acquia/update_via_drush.sh
# Choose targeting scope (1-4)
# Select application(s) and environment(s)
# Enter drush command (e.g., "cr" for cache rebuild)
# Confirm execution

# CLI mode — skip all prompts:
$ sh ~/Sites/_hal/drupal/acquia/update_via_drush.sh [app] [env] [command]
$ sh ~/Sites/_hal/drupal/acquia/update_via_drush.sh all dev cr
$ sh ~/Sites/_hal/drupal/acquia/update_via_drush.sh hud8 prod "pm:enable page_cache"
```

**Examples**:
- Cache rebuild on single site: `sh update_via_drush.sh hud8 dev cr`
- Enable module system-wide: `sh update_via_drush.sh all prod "pm:enable page_cache"`
- Update database on one app: `sh update_via_drush.sh academicdepartments dev updb`

#### `acquia_config_set.sh` - Precise Configuration Updates

**Purpose**: Update specific configuration values on targeted Howard sites using `drush config:set`.

**Features**:
- All four targeting options available
- Interactive prompts for config name, key, and value
- Confirmation before applying changes
- Supports any valid Drupal configuration

**Usage**:
```bash
$ sh ~/Sites/_hal/drupal/acquia/acquia_config_set.sh  
# Choose targeting scope
# Select application(s) and environment(s)
# Enter config name (e.g., "system.site")
# Enter config key (e.g., "page.front") 
# Enter new value (e.g., "/node/123")
# Confirm execution
```

**Examples**:
- Set front page on single site: Choose option 1, target specific app+env
- Update site name across all environments: Choose option 2, single app + all envs
- Change maintenance mode system-wide: Choose option 4, all apps + all envs

#### `acquia_code_deploy.sh` - Code Deployment

**Purpose**: Create Git tags on master and deploy to Acquia prod. Dev and test environments always stay on master.

**Features**:
- Deploy a single application or all applications in one run
- Automatic date-based tag creation with collision handling
- Git operations (pull, push, tag push) per repo
- Deployment via `acli api:environments:code-switch`
- Always targets prod — other envs are not touched

**Requires**: `acli` installed and authenticated, and `ACQUIA_ENV_UUID_*_prod` entries populated in `hal_config.txt`.

**Usage**:
```bash
# Interactive mode:
$ sh ~/Sites/_hal/drupal/acquia/acquia_code_deploy.sh
# Choose: Single Application or All Applications
# If single: select which app
# Script tags, pushes, and deploys each repo to prod

# CLI mode — skip all prompts:
$ sh ~/Sites/_hal/drupal/acquia/acquia_code_deploy.sh [app]
$ sh ~/Sites/_hal/drupal/acquia/acquia_code_deploy.sh all
$ sh ~/Sites/_hal/drupal/acquia/acquia_code_deploy.sh hud8
```

**Process** (per application):
1. Creates date-based Git tag (e.g., `2026-05-08` or `2026-05-08.1` if tag exists)
2. Pulls latest master, pushes master and tags to remote
3. Deploys tag to prod via acli

#### `remove_deprecated_modules.sh` - Module Database Cleanup

**Purpose**: Remove lingering database entries for one or more modules across Howard sites. Useful after uninstalling or removing modules that leave behind `system.schema` or config table entries.

**Features**:
- Prompts for one or more module machine names (space-separated)
- All four targeting options available
- Removes entries from `key_value` (system.schema) and `config` tables per module
- Cache clear after each environment

**Usage**:
```bash
$ sh ~/Sites/_hal/drupal/acquia/remove_deprecated_modules.sh
# Enter module machine name(s), space-separated, e.g: ckeditor tour seven
# Choose targeting scope
# Select application(s) and environment(s)
# Confirm execution
```

#### `list.sh` - Data Listing Across Sites

**Purpose**: Retrieve and display lists of users, webforms, webform email handlers, news feeds, or magazine feeds across all Howard D8 sites. Relies on remote `hal_*_list.sh` scripts on the app servers.

**Features**:
- Interactive list type selection
- Environment selection (dev, test, prod)
- Runs across all Howard applications for the chosen environment

**List types**:
- `users` — All user accounts per site
- `webforms` — All webforms with submission counts and embed pages
- `webform_emails` — All webform email handler configurations (to, from, reply-to) — useful for auditing where form submissions are being sent
- `newsfeeds` — News feed content
- `magazinefeeds` — Magazine feed content

**Usage**:
```bash
$ sh ~/Sites/_hal/drupal/acquia/list.sh
# Choose list type: users, webforms, webform_emails, newsfeeds, or magazinefeeds
# Choose environment: dev, test, or prod
```

#### `site_status_check.sh` - HTTP Site Status Check

**Purpose**: Perform a comprehensive HTTP health check against every Howard multisite URL for the selected applications and environments. Site discovery is driven by the presence of local `docroot/sites/*.howard.edu` folders, so results always reflect what is actually deployed rather than what is listed in `sites.php`.

**Scope**: Remote — all checks hit live Acquia URLs. No local file changes are made.

**Features**:
- All four targeting options available
- Discovers sites from local `docroot/sites/*.howard.edu` folders (not from `sites.php`)
- Environment → URL prefix mapping: `dev` → `dev.*`, `test` → `stg.*`, `prod` → bare domain
- HTTP Basic Auth (`huweb:huweb`) passed automatically on every request
- SSL certificate verification skipped for dev/test (Acquia dev/stg certs are commonly expired/self-signed)
- Follows redirects — 2xx/3xx = UP (green ✓), all others flagged (red ✗)
- Per-homepage checks: HTTP status code, response time, page `<title>`, Shield status, maintenance mode, Drupal error page
- Optional nav page sampling: up to 3 level-1 + 3 level-2 internal pages checked per site/env
- Dual end-of-run summary: content warnings list + flagged URL list

**Shield Status Expectations**:

Shield is a Drupal HTTP Basic Auth module used to gate non-production environments from public access. The script evaluates Shield state differently by environment:

| Environment | Expected State | Actual: Shield UP | Actual: Shield DOWN |
|-------------|---------------|-------------------|---------------------|
| `dev` / `test` | UP (401 no-auth) | ✓ green | ⚠ warning — publicly accessible |
| `prod` | DOWN (public) | ⚠ warning — may be accidentally gated | ✓ green |

Detection method: a HEAD request is made *without* credentials before each main GET. A `401` response indicates Shield is active; any other code means Shield is inactive.

**Nav Page Sampling** (optional, prompted at runtime):

When enabled, after each successful homepage check the script:

1. Parses all `href` attributes from the already-fetched homepage body
2. Filters to internal relative paths, excluding Drupal system paths (`/admin`, `/user`, `/node/`, `/sites/`, `/modules/`, `/themes/`, `/core/`) and static asset extensions (`.pdf`, `.jpg`, `.css`, `.js`, etc.)
3. Groups remaining paths by URL depth:
   - **Level 1**: `/segment` — top-level nav items (e.g. `/about`, `/academics`)
   - **Level 2**: `/segment/segment` — sub-nav / dropdown items (e.g. `/about/leadership`)
4. Randomly selects up to 3 paths from each group using a Fisher-Yates shuffle seeded with `$RANDOM`
5. Checks each selected URL for: HTTP status, response time, page title, maintenance mode, and Drupal errors (Shield is not re-checked per-page)

> **Performance note**: nav sampling adds up to 6 additional curl requests per site per environment. For a full sweep (All Apps + All Envs) across 100+ sites this significantly increases runtime. Scope to a single app or prod-only when using nav sampling for the first time.

**Output Format**:

```
=== admission.howard.edu ===
  ✓ [200] https://admission.howard.edu (0.84s)
    ↳ Title: Undergraduate Admissions | Howard University
    ↳ Shield: DOWN
    ↳ Nav sample (level 1):
      ✓ [200] https://admission.howard.edu/apply (0.71s)
        Title: Apply Now | Howard University
      ✓ [200] https://admission.howard.edu/visit (0.66s)
        Title: Visit Campus | Howard University
    ↳ Nav sample (level 2):
      ✓ [200] https://admission.howard.edu/tuition/scholarships (0.79s)
        Title: Scholarships | Howard University
      ⚠ MAINTENANCE MODE
```

**Status Code Reference**:
- `000` — Connection failure, DNS error, or request timeout (server unreachable)
- `401` — Authenticated request rejected (Shield credential mismatch)
- `4xx` — Client error (404 Not Found, 403 Forbidden, etc.)
- `5xx` — Server error (Drupal crash, PHP fatal error, or database issue)

**Usage**:
```bash
# Interactive mode:
$ sh ~/Sites/_hal/drupal/acquia/site_status_check.sh
# 1. Choose targeting scope (1-4)
# 2. Select application(s) and/or environment(s) as prompted
# 3. Answer the nav sampling prompt [y/N]
# Script runs all checks inline, then prints a warnings + flagged URL summary

# CLI mode — skip all prompts:
$ sh ~/Sites/_hal/drupal/acquia/site_status_check.sh [app] [env] [nav]
$ sh ~/Sites/_hal/drupal/acquia/site_status_check.sh all prod
$ sh ~/Sites/_hal/drupal/acquia/site_status_check.sh hud8 prod y
```

**Examples**:
- Quick prod check for one app: `sh site_status_check.sh hud8 prod`
- Verify Shield everywhere: `sh site_status_check.sh all prod` — watch for Shield UP warnings
- Full health sweep (slow): `sh site_status_check.sh all all`

#### `sync_prod_to_env.sh` - Prod → Dev Data Sync

**Purpose**: Copy all databases and/or files from Acquia prod to dev for selected applications. Databases are copied individually per DB using `acli api:environments:database-copy`, ensuring all multisite databases are synced. Files use `acli env:mirror --no-databases`.

**Scope**: Remote — operates on Acquia environments via acli. No local file changes.

> ⚠️ **DESTRUCTIVE**: All dev databases (and optionally files) are fully overwritten with production data. Requires typing `yes` (not just `y`) to confirm. Test/stg is intentionally excluded as a destination.

**Features**:
- Single Application or All Applications scope
- Destination is always `dev` (stg excluded by design)
- Choice of what to sync: Databases + Files, Databases only, or Files only
- Copies **all** databases for an app (e.g. all 4 multisite DBs for uxws), not just the primary one
- Database copies are queued asynchronously — allow 2–5 minutes per app before running follow-up commands
- Dev codebase is never touched; Acquia platform config (crons, env vars) is never overwritten
- Per-application error tracking with a pass/fail summary
- Post-run reminder to run `updb` and `cr` via `update_via_drush.sh`

**Requires**: `acli` installed and authenticated (`acli auth:login`), and `ACQUIA_ENV_UUID_*_prod` entries populated in `hal_config.txt`.

**Usage**:
```bash
# Interactive mode:
$ sh ~/Sites/_hal/drupal/acquia/sync_prod_to_env.sh
# 1. Choose: Single Application or All Applications
# 2. Choose what to sync: Databases + Files / Databases only / Files only
# 3. Review the confirmation summary
# 4. Type 'yes' to proceed

# CLI mode — skip selection prompts (confirmation still required):
$ sh ~/Sites/_hal/drupal/acquia/sync_prod_to_env.sh [app] [type]
$ sh ~/Sites/_hal/drupal/acquia/sync_prod_to_env.sh all databases
$ sh ~/Sites/_hal/drupal/acquia/sync_prod_to_env.sh hud8 both
```

**Examples**:
- Refresh a single app's dev data: `sh sync_prod_to_env.sh hud8 databases`
- Full prod → dev refresh for all apps: `sh sync_prod_to_env.sh all both`

**Recommended follow-up** (via `update_via_drush.sh`):
- `updb` — run pending database updates on dev
- `cr` — rebuild caches on dev

#### `backup_databases.sh` - Database Backups

**Purpose**: Create Acquia database backups for all databases in the selected applications and environment. Recommended to run against prod at the start of every update cycle, before deploying code.

**Scope**: Remote — queues backup jobs on Acquia via acli. No local file changes.

**Features**:
- Single Application or All Applications scope
- Any environment: dev, test, or prod
- Backs up **all** databases for an app (not just the primary one)
- Backup requests are queued asynchronously — verify completion in the Acquia Cloud UI
- Per-application error tracking with a pass/fail summary

**Usage**:
```bash
# Interactive mode:
$ sh ~/Sites/_hal/drupal/acquia/backup_databases.sh
# 1. Choose: Single Application or All Applications
# 2. Choose environment: dev, test, or prod
# 3. Confirm — type y to proceed

# CLI mode — skip selection prompts (confirmation still required):
$ sh ~/Sites/_hal/drupal/acquia/backup_databases.sh [app] [env]
$ sh ~/Sites/_hal/drupal/acquia/backup_databases.sh all prod
$ sh ~/Sites/_hal/drupal/acquia/backup_databases.sh hud8 prod
```

**Examples**:
- Back up all prod databases before an update cycle: `sh backup_databases.sh all prod`
- Back up a single app before targeted changes: `sh backup_databases.sh hud8 prod`

**Verify backups**: Acquia Cloud UI → your app → Databases → Backups

#### `pull_config_from_env.sh` - Pull Config from Acquia to Local

**Purpose**: Export active Drupal configuration from any Acquia environment (dev/test/prod) to your local codebases. Runs `drush cex` on every site in the selected app(s), exports to a temp directory on the server, then rsyncs the result back to the matching local `config/` directory. Uses `--delete` so each pull is a clean mirror of the remote state.

**Scope**: Local + Remote — modifies local config files. No changes are made to Acquia environments.

**Features**:
- All four targeting options available (single app, all apps, any env)
- Discovers live `AH_SITE_NAME` dynamically — works correctly for non-standard paths (uxws, centers)
- Exports via direct SSH (not drush ssh) to handle multiline bash safely on read-only Acquia filesystems
- Temp exports to `/tmp/hal_config_export_{app}/` (writable), cleaned up after sync
- `--delete` rsync — stale local `.yml` files not present in the remote export are removed; `.htaccess` and `README.txt` are protected
- Per-app error tracking with a pass/fail summary
- Review changes with `git diff config/` before committing

**Usage**:
```bash
# Interactive mode:
$ sh ~/Sites/_hal/drupal/acquia/pull_config_from_env.sh
# Choose targeting scope (1-4)
# Select application(s) and environment(s)
# Confirm execution

# CLI mode — skip all prompts:
$ sh ~/Sites/_hal/drupal/acquia/pull_config_from_env.sh [app] [env]
$ sh ~/Sites/_hal/drupal/acquia/pull_config_from_env.sh all prod
$ sh ~/Sites/_hal/drupal/acquia/pull_config_from_env.sh hud8 stg
```

**Examples**:
- Sync all apps from prod: `sh pull_config_from_env.sh all prod`
- Sync a single app from stg: `sh pull_config_from_env.sh hud8 stg`
- Sync uxws from dev: `sh pull_config_from_env.sh uxws dev`

**Recommended follow-up**:
- `git diff config/` — review what changed before committing
- `git add config/ && git commit -m 'Sync config from prod'` — commit the updated config
- `drush config:import --partial -y` — import config into a local site if needed

> ⚠️ **Note**: Sites that fail `drush cex` (e.g. cms-training.howard.edu when the DB can't be bootstrapped) are skipped. Check the error summary at the end of the run and investigate those sites separately.

#### `node_search.sh` - Search Node and Menu Link Titles

**Purpose**: Search for a node title or menu link title (partial match) across all Howard D8 apps and environments. Useful for locating where specific content lives across the multisite ecosystem.

**Features**:
- Case-insensitive partial match against both `node_field_data` and `menu_link_content_data`
- Only outputs sites with matches (clean output)
- Suppresses Drupal bootstrap errors

**Usage**:
```bash
$ sh ~/Sites/_hal/drupal/acquia/node_search.sh
# Enter search term (partial match)
# Choose environment: dev, test, or prod
```

### Legacy and Utility Scripts

#### Initial spin-up of a multi-site site, and clone dev.coasdept

- This script creates a new multi-site install locally (copies the _starter_ folder), adjusts settings.php and sites.php with needed parameters, adds connection data to a multi-site DB on acquia, Commits to master, and pushes to Acquia. The script then clones the stg.coasdept.howard.edu DB and Files into it, directly on acquia STG. A video overview can be seen on [vimeo](https://vimeo.com/400050607/0f830ca20d).

##### Manual Steps (to be completed first)

- Create database in desired environment (hud8 or academicdepartments), and note machine name.
- Add URLs for new site into dev/stg/live URL fields in acquia.
- BOTH of these steps must be completed, as the drush scripts depend on both URL, and database being set up for the environment.

##### Automated Steps (done by script after manual steps complete)

You will also be given the option to commit/push immediately, and whether you wish to copy database and files from stg.coasdept.howard. Choosing "NO" on any, will skip these steps, and they will subsequently need to be performed manually. If git automation is not chosen, a new git branch will be created and used locally: "new_howard_multisite_TIMESTAMP".

- Be sure that HAL is up to date.
- Be sure that all desired local folders, and drush aliases are set up in hal_config.txt.
- Be sure that you are on master branch, and it is up to date.
- Be sure you have the database machine name you added in acquia.
- You will need to keep a loose eye on the terminal to put in passwords/etc occasionally.
- `$ sh ~/Sites/_hal/drupal/acquia/create_new_multisite.sh`

#### Update all Howard packagist repos, on all Howard D8 sites, commit, and push to acquia

You will also be given the option to commit/push immediately. If git automation is not chosen, a new git branch will be created and used locally: "howard_package_updates_TIMESTAMP".

- Be sure that HAL is up to date.
- Be sure that all desired local folders are set up in hal_config.txt.
- Be sure that you are on master branch, and it is up to date.
- You will need to keep a loose eye on the terminal to put in passwords/etc occasionally.
- `$ sh ~/Sites/_hal/drupal/acquia/update_howard_packages.sh`

#### Run a full update (core, contrib, and Howard packages) on all Howard D8 sites, commit, and push to acquia

Runs all three composer update operations in sequence per site: Drupal core, all `drupal/*` contrib modules/themes, and all `howard/*` packages. Supports dry-run mode. If git automation is not chosen, a new git branch will be created and used locally: "full_update_TIMESTAMP".

- Be sure that HAL is up to date.
- Be sure that all desired local folders are set up in hal_config.txt.
- Be sure that you are on master branch, and it is up to date.
- You will need to keep a loose eye on the terminal to put in passwords/etc occasionally.
- `$ sh ~/Sites/_hal/drupal/acquia/update_all.sh`

#### Update Drupal core on all Howard D8 sites, commit, and push to acquia

Updates `drupal/core`, `drupal/core-recommended`, `drupal/core-composer-scaffold`, and `drupal/core-project-message` (with all dependencies) across every local Howard D8 application. You will also be given the option to commit/push immediately. If git automation is not chosen, a new git branch will be created and used locally: "drupal_core_update_TIMESTAMP".

- Be sure that HAL is up to date.
- Be sure that all desired local folders are set up in hal_config.txt.
- Be sure that you are on master branch, and it is up to date.
- You will need to keep a loose eye on the terminal to put in passwords/etc occasionally.
- `$ sh ~/Sites/_hal/drupal/acquia/update_drupal_core.sh`

#### Update all Drupal contrib modules and themes on all Howard D8 sites, commit, and push to acquia

Runs `composer update "drupal/*" --with-all-dependencies` across every local Howard D8 application, updating all contrib modules and themes within their existing version constraints. You will also be given the option to commit/push immediately. If git automation is not chosen, a new git branch will be created and used locally: "drupal_contrib_update_TIMESTAMP".

- Be sure that HAL is up to date.
- Be sure that all desired local folders are set up in hal_config.txt.
- Be sure that you are on master branch, and it is up to date.
- You will need to keep a loose eye on the terminal to put in passwords/etc occasionally.
- `$ sh ~/Sites/_hal/drupal/acquia/update_drupal_contrib.sh`

#### Update config item on all sites

- Be sure that HAL is up to date.
- Be sure that all desired local drush aliases are set up in hal_config.txt.
- Paste in Name, Key, and Value as the prompts arise.
- Relies on [drush cset](https://drushcommands.com/drush-8x/config/config-set/), please ensure this is understood before using.
- `$ sh ~/Sites/_hal/drupal/acquia/acquia_config_set.sh`
- See [idfive developer documentation](https://developers.idfive.com/#/back-end/drupal/drupal-config-management?id=one-time-config-overrides-via-drush) for overview of approach, and finding Name, Key, and Values desired.

#### Run drush command on all sites

- Be sure that HAL is up to date.
- Be sure that all desired local drush aliases are set up in hal_config.txt.
- Paste in desired drush command at the prompt.
- Add the desired command only, ie "pm-uninstall page_cache", as things like "drush" and "@sites" are added by the script.
- `$ sh ~/Sites/_hal/drupal/acquia/update_via_drush.sh`

#### Update database on acquia sites

- Use `update_via_drush.sh` with drush command `updb`.
- `$ sh ~/Sites/_hal/drupal/acquia/update_via_drush.sh`

#### Push master branch, create a new tag, and deploy to Acquia Prod

- Be sure that HAL is up to date.
- Be sure `acli` is installed and authenticated (`acli auth:login`).
- Be sure `ACQUIA_ENV_UUID_*_prod` entries are populated in `hal_config.txt`.
- Be sure the target application's master branch is up to date.
- Choose "Single Application" to deploy one app, or "All Applications" to deploy all five.
- The script tags master, pushes master and the tag, then switches the prod environment to the tag via acli.
- `$ sh ~/Sites/_hal/drupal/acquia/acquia_code_deploy.sh`

#### List users, webforms, webform email handlers, news feeds, and magazine feeds across sites.

A single unified script for listing data across all Howard D8 sites. Prompts for the list type at runtime. Relies on the corresponding remote list scripts (`hal_user_list.sh`, `hal_webform_list.sh`, `hal_webform_email_list.sh`, etc.) on the app servers.

- Be sure that HAL is up to date.
- Be sure that all desired local drush aliases are set up in hal_config.txt.
- Be sure all acquia drush aliases are up to date.
- Choose the list type (users, webforms, webform_emails, newsfeeds, or magazinefeeds) when prompted.
- Choose dev, test, or prod; the script runs the selected list across all apps for that environment.
- `$ sh ~/Sites/_hal/drupal/acquia/list.sh`

#### Search for a node or menu link title across all apps

Searches all multisites across all five Howard D8 apps for a node title or menu link title. Useful for tracking down where specific content lives in the ecosystem.

- Be sure that HAL is up to date.
- Be sure all acquia drush aliases are set up in hal_config.txt.
- Enter a partial search term when prompted (case-insensitive).
- Choose dev, test, or prod.
- `$ sh ~/Sites/_hal/drupal/acquia/node_search.sh`

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
