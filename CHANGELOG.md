# Changelog

All notable changes to the Howard Automation Library (HAL) will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.2.0] - 2026-05-08

### Added

- **NEW SCRIPT**: `list.sh` - Unified listing script replacing four individual list scripts
  - Prompts for list type (users, webforms, newsfeeds, magazinefeeds) in a single interactive menu
  - Delegates to new `partials/run_remote_list.sh` shared partial
- **NEW PARTIAL**: `partials/run_remote_list.sh` - Shared logic for running remote list scripts across all apps/environments

### Removed

- **REMOVED**: `list_users.sh` - Consolidated into `list.sh`
- **REMOVED**: `list_webforms.sh` - Consolidated into `list.sh`
- **REMOVED**: `list_newsfeeds.sh` - Consolidated into `list.sh`
- **REMOVED**: `list_magazinefeeds.sh` - Consolidated into `list.sh`

### Fixed

- **FIXED**: `update_howard_packages.sh` and `create_new_multisite.sh` - `select` menu validation was checking `$` (shell PID, never empty) instead of the selected variable; invalid choices were silently accepted
- **FIXED**: `update_howard_packages.sh` - branches created when skipping auto-push were named `new_howard_multisite_TIMESTAMP`; now correctly named `howard_package_updates_TIMESTAMP`
- **FIXED**: `acquia_code_deploy.sh` - typo "credienatials" corrected to "credentials"

### Removed

- **REMOVED**: `commit_push_branch_dev.sh` - thin git wrapper with a hardcoded commit message; superseded by inline git ops in other scripts
- **REMOVED**: `update_db_on_acquia.sh` - superseded by `update_via_drush.sh` with command `updb`

### Improved

- **IMPROVED**: `acquia_code_deploy.sh` - replaced deprecated `ac-code-path-deploy` (Acquia Cloud API v1, no longer functional) with `acli api:environments:code-switch`; always targets prod; user chooses single app or all five apps; no longer requires Acquia email/key credentials
- **IMPROVED**: `remove_deprecated_modules.sh` - removed hardcoded module list (ckeditor, mysql57, tour, seven, ckeditor_lts); now prompts for any module machine name(s) at runtime (space-separated input), making the script generic and reusable
- **IMPROVED**: `partials/run_remote_list.sh` - replaced inline ENVS array and `select ENV` block with `select_env_only` from `partials/select_app_and_env.sh`; all scripts now consistently use the shared partial for app and environment selection
- **IMPROVED**: `create_new_multisite.sh` - replaced manual 5-branch if/elif folder lookup with `get_local_folder_for_app()` from `partials/select_app_and_env.sh`; script now sources that partial

## [2.1.0] - 2024-10-24

### Added

- **NEW SCRIPT**: `remove_deprecated_modules.sh` - Generic cleanup script for lingering module database references after uninstalling modules
  - Prompts for any module machine name(s) at runtime (space-separated)
  - Includes all four targeting options (single app+env, single app+all envs, all apps+single env, all apps+all envs)
  - Removes entries from `key_value` (system.schema) and `config` tables per module
  - Automatic cache clearing after cleanup operations

### Enhanced

- **IMPROVED**: All scripts now use standardized targeting system with consistent interface
- **IMPROVED**: Enhanced error handling across all automation scripts
- **IMPROVED**: Better progress feedback and user experience during script execution
- **IMPROVED**: Database update scripts now handle Drupal 11 compatibility issues gracefully

### Documentation

- **UPDATED**: Comprehensive README.md with detailed script documentation
- **ADDED**: Usage examples for all major scripts
- **ADDED**: Troubleshooting section for common issues
- **ADDED**: Changelog tracking for future releases
- **IMPROVED**: Installation and configuration instructions

### Technical

- **ENHANCED**: Modular architecture with shared selection component (`partials/select_app_and_env.sh`)
- **ENHANCED**: Consistent validation and confirmation patterns across all scripts
- **ENHANCED**: Improved compatibility with Drupal 11 core changes

### Fixed

- **FIXED**: Issues with mysql57 module references preventing database updates on Drupal 11 sites
- **FIXED**: Bootstrap failures caused by missing deprecated module files
- **FIXED**: Inconsistent error handling when database tables don't exist

## [2.0.0] - Previous Release

### Added

- Core HAL automation framework
- Standardized drush command execution
- Configuration management scripts
- Database update automation
- Code deployment scripts
- User and content listing utilities

---

**Legend:**
- **NEW SCRIPT** - Brand new automation script
- **IMPROVED** - Enhanced existing functionality
- **UPDATED** - Documentation or configuration updates
- **ENHANCED** - Technical improvements to architecture
- **FIXED** - Bug fixes and issue resolutions
