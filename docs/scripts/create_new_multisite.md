# `create_new_multisite.sh` — New Multisite Scaffolding

**Purpose**: Scaffold a new multisite install locally, configure it on Acquia, and optionally clone an existing site's database and files into it.

**Scope**: Local + Remote — creates local config files, commits to git, and interacts with Acquia.

A video overview is available on [Vimeo](https://vimeo.com/400050607/0f830ca20d).

## Manual Steps (complete before running the script)

1. **Create a database** in the desired Acquia environment (hud8 or academicdepartments) — note the machine name.
2. **Add URLs** for the new site into the dev/stg/live URL fields in the Acquia Cloud UI.

Both steps must be completed before running the script, as it depends on both the URL and the database being configured in Acquia.

## Automated Steps (done by the script)

- Copies the `_starter_` folder to create a new site directory
- Adjusts `settings.php` and `sites.php` with the required parameters
- Adds connection data to the multisite database on Acquia
- Optionally commits to master and pushes to Acquia
- Optionally clones an existing site's database and files into the new site on Acquia stg

## Usage

```bash
$ sh ~/Sites/_hal/drupal/acquia/create_new_multisite.sh
```

You will be prompted at each step whether to proceed with git automation and database/file cloning. Choosing **NO** skips those steps (they must be completed manually). If git automation is declined, a new branch `new_howard_multisite_TIMESTAMP` is created locally.

## Prerequisites

- HAL is up to date
- All local folders and drush aliases are configured in `hal_config.txt`
- You are on the `master` branch and it is up to date
- The database machine name from Acquia is ready
- Monitor the terminal throughout — you may need to enter passwords at various points
