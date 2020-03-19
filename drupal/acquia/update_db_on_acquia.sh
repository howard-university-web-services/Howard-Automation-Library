#!/bin/bash
#
# Update database on all Howard D8 installs on acquia.
#
# $ sh ~/Sites/_hal/drupal/acquia/update_db_on_acquia.sh
#
# Notes:
# - Refresh all drush aliases via dev desktop or similar
#
# Dependencies:
# - drush
#
# Paramaters:
# - Acquia Environment | corresponds to local drush aliases for acquia environments
#

echo "This script will update all Howard packagist projects in all local folders specified in hal_config.txt, commit and push to acquia."
echo "Be sure you are on the correct branch to deploy to DEV env in all folders/repos, usually 'master'."
echo "You will be running the database update script on acquia dev/test/prod. Be sure this is really what you want to do."

source ~/Sites/_hal/hal_config.txt

# Acquia ENV to create site on, use as $ACQUIA_ENV
TO_ACQUIA_ENVS=( "@hud8" "@academicdepartments" )
select ACQUIA_ENV in "${TO_ACQUIA_ENVS[@]}"; do
  if [[ -z "$" ]]; then
    printf '"%s" is not a valid choice\n' "$REPLY" >&2
  else
    break
  fi
done

for env in 'dev' 'test' 'prod'
do
  drush $ACQUIA_ENV.$env ssh "drush @sites updb -y && exit"
  echo $ACQUIA_ENV.$env "Updates complete.";
done

exit 0
