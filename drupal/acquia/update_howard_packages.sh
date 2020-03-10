#!/bin/bash
#
# Update all Howard packagist repos, on all Howard D8 sites, commit, and push to acquia.
#
# $ sh ~/Sites/_hal/drupal/acquia/update_howard_packages.sh
#
# Notes:
# - Be sure hal_config.txt is set up and working
# - Refresh all drush aliases via dev desktop or similar
# - Be sure you are on master branch, and that the env in question has DEV ENV set to MASTER.
#
# Dependencies:
# - Git
# - Composer
#
# Paramaters:
# - Local Howard D8 Folders | an array of absolute paths to folders on your local machine | read from hal_config.txt
#

echo "This script will update all Howard packagist projects in all local folders specified in hal_config.txt, commit and push to acquia."
echo "Be sure you are on the correct branch to deploy to DEV env in all folders/repos, usually 'master'."
echo "You will be committing and pushing code. Be sure this is really what you want to do."

source ~/Sites/_hal/hal_config.txt
composer clearcache

for app in ${LOCAL_HOWARD_D8_FOLDERS[@]}; do
  echo "Running update in $app"
  cd $app
  composer update 'howard/*'
  echo "commiting to git, and pushing..."
  git add .
  git commit -m 'Updating all Howard Packagist themes and modules, via Howard Automation Library'
  git push origin master
done

exit 0
