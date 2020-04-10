#!/bin/bash
#
# This script installs a Drupal 8 module to a local code base using composer. Once local installation is
# complete, the code changes are committed to source control.
#
# Notes:
# - Be sure hal_config.txt is set up and working properly.
# - Be sure you are on master branch, and that the env in question has DEV ENV set to MASTER.
# - Be sure you run from ~/Sites/devdesktop/DESIRED_CODEBASE (the same directory as composer.json).
#
# Dependencies:
# - Git: https://git-scm.com/
# - Composer: https://getcomposer.org/
# - Drush: https://www.drush.org/
# - Acquia CLI: https://github.com/typhonius/acquia_cli
#
# Parameters:
# - Drupal 8 Module Name | 'seckit' |
# - Drupal 8 Module Version | '^1.5' |
# - Acquia API Email | 'your.email@howard.edu' | read from hal_config.txt.
# - Acquia API Key | 'xxxxxxxxxxxxxxxxxxxxxxxx' | read from hal_config.txt.
#

echo "This script will install a Drupal 8 module to a local Drupal 8 codebase, then commit and push to the Acquia VCS."
echo "Be sure you are on the correct branch to deploy to the Acquia DEV environment."

# Import Acquia credentials.
source ~/docroot/Sites/_hal/hal_config.txt

# The name of a Drupal 8 module to install.
echo "Enter the name of the Drupal 8 module you would like to install (e.g. seckit):"
read MODULE_NAME

# Validate input parameter.
if [ -z "$MODULE_NAME" ]; then
  echo "A Drupal 8 module name must be provided."
  exit 2
fi

# The version of the Drupal 8 module to install (optional).
echo "Enter the desired version of the Drupal 8 module you would like to install, or press enter to install the latest version:"
read MODULE_VERSION

# Validate input parameter.
if [ -z "$MODULE_VERSION" ]; then
  echo "A Drupal 8 module version was not provided, using the latest version."
fi

# Add the Drupal 8 composer endpoint to composer.json if it is not already listed.
composer config repositories.0 composer https://packages.drupal.org/8

# Set module identifier.
MODULE_ID = "drupal/$MODULE_NAME"
if [ -n "$MODULE_VERSION" ]; then
  MODULE_ID = "$MODULE_ID:$MODULE_VERSION"
fi

# Install the module using composer.
composer require "$MODULE_ID" -v

# Commit module and composer updates to VCS.
echo "Commiting changes to git, and pushing to remote repository."
git add .
git commit -m "Adding Drupal module $MODULE_NAME, via Howard Automation Library"
git push origin master --force
