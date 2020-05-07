#!/bin/bash
#
# This script creates a new multisite install locally, adjusts settings.php and sites.php with needed parameters,
# create a new multisite DB on acquia, clone the dev.coasdept.howard.edu DB and Files into it.
#
# $ sh ~/Sites/_hal/drupal/acquia/test.sh
#
# Notes:
# - See README.md for detailed instructions.
#
# Dependencies:
# - Drush: https://www.drush.org/
#
# Paramaters:
# - Acquia Env | The environment to create the site on


echo "Testing..."

source ~/Sites/_hal/hal_config.txt
YES_NO=( "YES" "NO" )

# Acquia ENV to create site on, use as $ACQUIA_ENV
TO_ACQUIA_ENVS=( "@hud8.dev" "@academicdepartments.dev" )
select ACQUIA_ENV in "${TO_ACQUIA_ENVS[@]}"; do
  if [[ -z "$" ]]; then
    printf '"%s" is not a valid choice\n' "$REPLY" >&2
  else
    break
  fi
done

# Move to proper folder
echo "Moving to proper folder..."
if [[ $ACQUIA_ENV = "@hud8.dev" ]]
then
  cd ${LOCAL_HOWARD_D8_FOLDERS[0]}/docroot/sites
elif [[ $ACQUIA_ENV = "@academicdepartments.dev" ]]
then
  cd ${LOCAL_HOWARD_D8_FOLDERS[1]}/docroot/sites
fi

pwd

# Check to ensure we are master git branch, and things are up to date.
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. $DIR/partials/check_git_status.sh

exit 0
