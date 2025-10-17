# Howard Automation Library (HAL)

The Howard Automation Library (HAL) is a comprehensive collection of bash scripts and automation tools designed to streamline the management of Howard University's Drupal applications across multiple Acquia Cloud environments.

## Overview

HAL provides standardized, interactive scripts for managing five Howard University Drupal applications:
- **@hud8** - Main Howard University site
- **@academicdepartments** - Academic department sites  
- **@howardenterprise** - Enterprise sites
- **@centers** - Center and institute sites
- **@uxws** - UX/Web Services sites

All scripts feature a consistent, user-friendly interface with flexible targeting options and built-in safety confirmations.

## Quick Reference

### Most Common Commands

```bash
# Universal drush command runner (cache rebuild, module enable, etc.)
$ sh ~/Sites/_hal/drupal/acquia/update_via_drush.sh

# Update configuration values (site settings, etc.)  
$ sh ~/Sites/_hal/drupal/acquia/update_config.sh

# Run database updates after code deployments
$ sh ~/Sites/_hal/drupal/acquia/update_db_on_acquia.sh

# Deploy code to production environments
$ sh ~/Sites/_hal/drupal/acquia/acquia_code_deploy.sh
```

### Targeting Options (Available in All Scripts)

1. **Single App + Single Env** → Precise targeting (e.g., @hud8 dev only)
2. **Single App + All Envs** → App-wide (e.g., @hud8 across dev/test/prod)  
3. **All Apps + Single Env** → Environment-wide (e.g., all apps on test)
4. **All Apps + All Envs** → System-wide (use with extreme caution)

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
- **Acquia Credentials** - Your Acquia email and private key for deployments

### 3. Configuration Details

#### Setting a local drush

- Navigate to the Drush 9 installed in the hud8 folder as a dependency, and adjust the path to match your local machine in config.
- `LOCAL_DRUSH="/PATH/TO/YOUR/FOLDER/hud8/vendor/bin/drush"`

#### Finding your local Howard D8 folders

- LOCAL_HOWARD_D8_FOLDERS[0] = Your local hud8 root folder.
- LOCAL_HOWARD_D8_FOLDERS[1] = Your local academicdepartments root folder.
- LOCAL_HOWARD_D8_FOLDERS[2] = Your local howardenterprise root folder.
- LOCAL_HOWARD_D8_FOLDERS[3] = Your local centers root folder.
- LOCAL_HOWARD_D8_FOLDERS[4] = Your local uxws root folder.
- Navigate to your DevDesktop sites folder.
- Find the folder you wish to use, ie "hud8"
- `cd hud8`
- `pwd`: The out put of this would go into hal_config.txt as `LOCAL_HOWARD_D8_FOLDERS[0]="/PATH/TO/YOUR/FOLDER/hud8"` (NOTICE THE "0" HERE).
- Subsequent paths, Academic Departments,for additional Howard D8 environments you wish to update would go into hal_config.txt as `LOCAL_HOWARD_D8_FOLDERS[1]="/PATH/TO/YOUR/OTHER/FOLDER/academicdepartments"` (NOTICE THE "1" HERE).

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
- Verify `ACQUIA_EMAIL` and `ACQUIA_PRIVATE_KEY` are set correctly
- Check that you have deployment permissions for the target environment

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

1. **Core Automation Scripts** - Daily operational tasks (update_via_drush.sh, update_config.sh, etc.)
2. **Deployment Scripts** - Code and database deployments (acquia_code_deploy.sh, update_db_on_acquia.sh)
3. **Information Scripts** - Data gathering and reporting (list_users.sh, list_webforms.sh, etc.)
4. **Legacy Scripts** - Drupal 7 maintenance and specialized tasks

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
$ sh ~/Sites/_hal/drupal/acquia/update_via_drush.sh
# Choose targeting scope (1-4)
# Select application(s) and environment(s)
# Enter drush command (e.g., "cr" for cache rebuild)
# Confirm execution
```

**Examples**:
- Cache rebuild on single site: Choose option 1, @hud8, dev, command: `cr`
- Enable module system-wide: Choose option 4, command: `pm:enable page_cache`
- Update database on one app: Choose option 2, @academicdepartments, command: `updb`

#### `update_config.sh` - Precise Configuration Updates

**Purpose**: Update specific configuration values on targeted Howard sites using `drush config:set`.

**Features**:
- All four targeting options available
- Interactive prompts for config name, key, and value
- Confirmation before applying changes
- Supports any valid Drupal configuration

**Usage**:
```bash
$ sh ~/Sites/_hal/drupal/acquia/update_config.sh  
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

#### `update_db_on_acquia.sh` - Database Updates

**Purpose**: Run database updates (`drush updb`) with flexible targeting options.

**Features**:
- All four targeting options available
- Safety confirmation before execution
- Clear progress feedback
- Handles multiple environments efficiently

**Usage**:
```bash
$ sh ~/Sites/_hal/drupal/acquia/update_db_on_acquia.sh
# Choose targeting scope
# Select application(s) and environment(s)  
# Confirm execution
```

**Examples**:
- Update single environment: Choose option 3, select test environment
- Update single app across all environments: Choose option 2, select @hud8
- Emergency system-wide update: Choose option 4 (use with extreme caution)

#### `acquia_code_deploy.sh` - Code Deployment

**Purpose**: Create Git tags and deploy code to specific Acquia environments.

**Features**:
- Standardized app and environment selection
- Automatic tag creation with date versioning
- Git operations (pull, push, tag push)
- Direct deployment to selected environment

**Usage**:
```bash
$ sh ~/Sites/_hal/drupal/acquia/acquia_code_deploy.sh
# Select application (@hud8, @academicdepartments, etc.)
# Select environment (dev, test, prod)
# Script creates tag and deploys automatically
```

**Process**:
1. Navigates to selected application's local folder
2. Creates date-based Git tag (e.g., `2025-10-17` or `2025-10-17.1` if tag exists)
3. Pulls latest master, pushes master and tags
4. Deploys tag to selected Acquia environment

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

#### Update all Howard packagist repos, on all Howard D9 sites, commit, and push to acquia

You will also be given the option to commit/push immediately. If git automation is not chosen, a new git branch will be created and used locally: "new_howard_multisite_TIMESTAMP".

- Be sure that HAL is up to date.
- Be sure that all desired local folders are set up in hal_config.txt.
- Be sure that you are on master branch, and it is up to date.
- You will need to keep a loose eye on the terminal to put in passwords/etc occasionally.
- `$ sh ~/Sites/_hal/drupal/acquia/update_howard_packages.sh`

#### Update the twitter API key on all sites

- Be sure that HAL is up to date.
- Be sure that all desired local drush aliases are set up in hal_config.txt.
- Be sure that you are on master branch, and it is up to date.
- You may set twitter credentials in hal_config.txt and simply hit enter through the prompts, or paste them in as the prompts arise.
- You will need to keep a loose eye on the terminal to put in passwords/etc occasionally.
- `$ sh ~/Sites/_hal/drupal/acquia/update_twitter_api_key.sh`

#### Update config item on all sites

- Be sure that HAL is up to date.
- Be sure that all desired local drush aliases are set up in hal_config.txt.
- Paste in Name, Key, and Value as the prompts arise.
- Relies on [drush cset](https://drushcommands.com/drush-8x/config/config-set/), please ensure this is understood before using.
- `$ sh ~/Sites/_hal/drupal/acquia/update_config.sh`
- See [idfive developer documentation](https://developers.idfive.com/#/back-end/drupal/drupal-config-management?id=one-time-config-overrides-via-drush) for overview of approach, and finding Name, Key, and Values desired.

#### Run drush command on all sites

- Be sure that HAL is up to date.
- Be sure that all desired local drush aliases are set up in hal_config.txt.
- Paste in desired drush command at the prompt.
- Add the desired command only, ie "pm-uninstall page_cache", as things like "drush" and "@sites" are added by the script.
- `$ sh ~/Sites/_hal/drupal/acquia/update_via_drush.sh`

#### Update database on all acquia D9 sites

- Be sure that HAL is up to date.
- Be sure that all desired local drush aliases are set up in hal_config.txt.
- Be sure all acquia drush aliases are up to date.
- You may choose either hud8 or academicdepartments. The script then runs drush updb on all multi-sites on dev, stg, and prod.
- You will need to keep a loose eye on the terminal to put in passwords/etc occasionally.
- `$ sh ~/Sites/_hal/drupal/acquia/update_db_on_acquia.sh`

#### Push master branch, creates new Tag and deploys new Tag to Acquia Prod Environment

- Be sure that HAL is up to date.
- Be sure that all desired local drush aliases are set up in hal_config.txt.
- Be sure all acquia drush aliases are up to date.
- Be sure either the HUD8 or the academicdepartments master branch is up-to-date
- Be sure Acquia Private Key and Acquia E-mail are up to date.
- You may choose either hud8 or academicdepartments Prod Environment.
- This script will push master branch, create new Tag  and deploy code to the selected Prod environment.
- You will need to keep a loose eye on the terminal to put in passwords/etc occasionally.
- `$ sh ~/Sites/_hal/drupal/acquia/acquia_code_deploy.sh`

#### List all non admin users on sites.

This script is set to be able to quickly see what non admin users are on all sites in an application. It may be modified in the future to perform more operations. Currently, it uses a script on the hud8, and academicdepartment servers, `/scripts/hal_user_list`. Any modifications to the functionality desired, will likely need to modify those scripts also.

- Be sure that HAL is up to date.
- Be sure that all desired local drush aliases are set up in hal_config.txt.
- Be sure all acquia drush aliases are up to date.
- You may choose either dev, test, or prod, at which point it will list all users, on all multisites, on both hud8 and academicdepartments, for the chosen environment.
- The script will then list the user id, user name, and email for all non administrator accounts.
- `$ sh ~/Sites/_hal/drupal/acquia/list_users.sh`

#### List all webforms on sites.

This script is set to be able to quickly see what webforms are on all sites in an application. It may be modified in the future to perform more operations. Currently, it uses a script on the hud8, and academicdepartment servers, `/scripts/hal_webform_list`. Any modifications to the functionality desired, will likely need to modify those scripts also.

- Be sure that HAL is up to date.
- Be sure that all desired local drush aliases are set up in hal_config.txt.
- Be sure all acquia drush aliases are up to date.
- You may choose either dev, test, or prod, at which point it will list all webforms, on all multisites, on both hud8 and academicdepartments, for the chosen environment.
- The script will then list the webform id.
- `$ sh ~/Sites/_hal/drupal/acquia/list_webforms.sh`

#### List all News feeds on sites.

This script is set to be able to quickly see what news feed widgets are on all sites in an application. It may be modified in the future to perform more operations. Currently, it uses a script on the hud8, and academicdepartment servers, `/scripts/hal_newsfeed_list`. Any modifications to the functionality desired, will likely need to modify those scripts also.

- Be sure that HAL is up to date.
- Be sure that all desired local drush aliases are set up in hal_config.txt.
- Be sure all acquia drush aliases are up to date.
- You may choose either dev, test, or prod, at which point it will list all webforms, on all multisites, on both hud8 and academicdepartments, for the chosen environment.
- `$ sh ~/Sites/_hal/drupal/acquia/list_newsfeeds.sh`

#### List all Magazine feeds on sites.

This script is set to be able to quickly see what magazine feed widgets are on all sites in an application. It may be modified in the future to perform more operations. Currently, it uses a script on the hud8, and academicdepartment servers, `/scripts/hal_magazinefeed_list`. Any modifications to the functionality desired, will likely need to modify those scripts also.

- Be sure that HAL is up to date.
- Be sure that all desired local drush aliases are set up in hal_config.txt.
- Be sure all acquia drush aliases are up to date.
- You may choose either dev, test, or prod, at which point it will list all webforms, on all multisites, on both hud8 and academicdepartments, for the chosen environment.
- `$ sh ~/Sites/_hal/drupal/acquia/list_magazinefeeds.sh`

## Drupal 7 Legacy

The following scripts exist as a stopgap in order to perform user operations on howard d7 sites.

- Reset password for a user: `sh ~/Sites/_hal/drupal/acquia/d7_reset_password.sh`.
- Cancel user account: `sh ~/Sites/_hal/drupal/acquia/d7_cancel_user.sh`.

## User maintenance

The following is a quick guide to disabling uses across all howard ecosystems, if required.

- For D8 sites, run `sh ~/Sites/_hal/drupal/acquia/update_via_drush.sh`, choose environments, and drush command when prompted: `user:cancel first.last`.
- For D7 sites, run `sh ~/Sites/_hal/drupal/acquia/d7_cancel_user.sh`, and type in username when prompted, ie `first.last`.

This will block the user account an reassign all content to anon user.

## Roadmap

### All Howard D8 acquia codebases

- Run composer add on all local codebases. "add the seckit module on all local D8 codebases" **In Progress**
- Commit and push to DEV for all local codebases
- Deploy to prod for all codebases
- You may choose either hud8 or academicdepartments Prod Environment.
