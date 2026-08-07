# `remove_deprecated_modules.sh` — Module Database Cleanup

**Purpose**: Remove lingering database entries for one or more modules across Howard sites. Useful after uninstalling or removing modules that leave behind `system.schema` or config table entries.

**Scope**: Remote — connects to Acquia environments via drush. No local file changes.

## Usage

```bash
# Interactive mode:
$ sh ~/Sites/_hal/drupal/acquia/remove_deprecated_modules.sh
# 1. Enter module machine name(s), space-separated (e.g., "ckeditor tour seven")
# 2. Choose targeting scope
# 3. Select application(s) and environment(s)
# 4. Confirm execution
```

## What It Does

For each module name provided, removes entries from:
- `key_value` table (system.schema state)
- `config` table (any configuration belonging to the module)

Runs a cache clear after each environment.

## When to Use

- After removing a module from `composer.json` that wasn't cleanly uninstalled via drush first
- When `drush updb` or `drush status` shows errors about missing modules that are no longer in the codebase
- After a failed `pm:uninstall` that left database artifacts behind

## Notes

- Enter module machine names only (e.g., `ckeditor` not `CKEditor`)
- Multiple modules can be entered space-separated in a single run
- Always verify the module is fully removed from the codebase (`composer.json`) before running
