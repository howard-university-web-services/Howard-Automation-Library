# Changelog

All notable changes to the Howard Automation Library (HAL) will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.1.0] - 2024-10-24

### Added

- **NEW SCRIPT**: `remove_deprecated_modules.sh` - Automated cleanup of deprecated module database references for Drupal 11 compatibility
  - Cleans up database references for ckeditor, mysql57, tour, seven, and ckeditor_lts modules
  - Includes all four targeting options (single app+env, single app+all envs, all apps+single env, all apps+all envs)
  - Safe execution with error handling for missing database tables
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
