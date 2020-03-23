#!/bin/bash
#
# Update all Howard packagist repos, on all Howard D8 sites, commit, and push to acquia.
#
# $ sh ~/Sites/_hal/drupal/acquia/update_howard_packages.sh
#
# Notes:
# - See README.md for detailed instructions.
#
# Dependencies:
# - Git
# - Composer
#
# Paramaters:
# - Local Howard D8 Folders | an array of absolute paths to folders on your local machine | read from hal_config.txt
#

echo "This script will update all Howard packagist projects in all local folders specified in hal_config.txt, commit and push to acquia."

source ~/Sites/_hal/hal_config.txt
composer clearcache

for app in ${LOCAL_HOWARD_D8_FOLDERS[@]}; do
  echo "Running update in $app"
  cd $app
  # Check to ensure we are master git branch, and things are up to date.
  sh ~/Sites/_hal/drupal/acquia/partials/check_git_status.sh
  composer update 'howard/*'
  echo "commiting to git, and pushing..."
  git add .
  git commit -m 'Updating all Howard Packagist themes and modules, via Howard Automation Library'
  git push origin master
done

exit 0
