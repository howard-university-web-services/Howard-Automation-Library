# Howard Automation Library (HAL)

This repo holds bash scripts and other files to help in the automation of Howard University Drupal projects.

## Installation

Clone this repo into your ~/Sites folder, as "_hal"

- `$ cd ~/Sites`
- `$ git clone https://https://github.com/howard-university-web-services/Howard-Automation-Library.git _hal`

### Add Local Config

- `$ cd ~/Sites/_hal`
- `$ cp hal_config.default.txt hal_config.txt`
- Edit hal_config.txt to use your acquia credentials.
- Edit hal_config.txt to use the absolute path to any local Howard D8 repos you wish to update/use.

#### Finding your local Howard D8 folders

- Navigate to your DevDesktop sites folder.
- Find the folder you wish to use, ie "hud8-dev"
- `cd hud8-dev`
- `pwd`: The out put of this would go into hal_config.txt as `LOCAL_HOWARD_D8_FOLDERS[0]="/PATH/TO/YOUR/FOLDER/hud8-dev"` (NOTICE THE "0" HERE).
- Subsequent paths, for additional Howard D8 environments you wish to update would go into hal_config.txt as `LOCAL_HOWARD_D8_FOLDERS[1]="/PATH/TO/YOUR/OTHER/FOLDER/academicdepartments-dev"` (NOTICE THE "1" HERE).

### Add and configure acquia CLI

- `git clone https://github.com/typhonius/acquia_cli.git`
- See [documentation](https://github.com/typhonius/acquia_cli) on adding API keys/etc locally.
- Ensure Acquia CLI is installed and running correctly.

### Requirements

Be sure the following are up and running correctly on your local machine:

- [Acquia DevDesktop](https://www.acquia.com/drupal/acquia-dev-desktop)
- [Acquia CLI](https://github.com/typhonius/acquia_cli)
- [Drush](https://docs.drush.org/en/master/install/) -- Already present if using DevDesktop

## Usage

- Ensure you are in the proper folder, especially for partials
- `$ sh your_desired_script.sh`
- Do not use sudo

## Drupal 8

The following scripts are available:

### Acquia

#### Initial spinup of a multi-site site, and clone dev.coasdept

- This script creates a new multisite install locally, adjusts settings.php and sites.php with needed parameters, create a new multisite DB on acquia, clone the dev.coasdept.howard.edu DB and Files into it.
- You will need to keep a loose eye on the terminal to put in passwords/etc occasionally.
- `$ cd ~/Sites/devdesktop/DESIRED_CODEBASE/docroot/sites`
- `$ sh ~/Sites/_hal/drupal/acquia/create_new_multisite.sh`

#### Update all Howard packagist repos, on all Howard D8 sites, commit, and push to acquia

- Be sure that all desired local folders are set up in hal_config.txt
- You will need to keep a loose eye on the terminal to put in passwords/etc occasionally.
- `$ sh ~/Sites/_hal/drupal/acquia/update_howard_packages.sh`
