# Howard Automation Library (HAL)

This repo holds bash scripts and other files to help in the automation of Howard University Drupal projects.

## Instalation

Clone this repo into your ~/Sites folder, as "_hal"

 - `$ cd ~/Sites`
 - `$ git clone https://https://github.com/howard-university-web-services/Howard-Automation-Library.git _hal`

### Add Local Config

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

#### Initial spinup of a multisite site, and clone dev.coasdept

 - This script creates a new multisite install locally, adjusts settings.php and sites.php with needed parameters, create a new multisite DB on acquia, clone the dev.coasdept.howard.edu DB and Files into it. 
 - You will need to keep a loose eye on the terminal to put in passwords/etc occasionally.
 - `$ cd ~/Sites/devdesktop/DESIRED_CODEBASE/docroot`
 - `$ sh ~/Sites/_hal/drupal/acquia/create_new_multisite.sh`
