#!/bin/bash
#
# Update database on all Howard D8 installs on acquia.
#
# $ sh ~/Sites/_hal/drupal/acquia/update_db_on_acquia.sh
#
# Notes:
# - See README.md for detailed instructions.
#
# Dependencies:
# - drush
#
# Paramaters:
# - Acquia Environment | corresponds to local drush aliases for acquia environments
#

echo "This script will update all databases on the specified Acque environments, for dev, stg, and prod."

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

for ENV in 'dev' 'test' 'prod'
do
  drush $ACQUIA_ENV.$ENV ssh "drush @sites updb -y && exit"
  echo $ACQUIA_ENV.$ENV "Updates complete.";
done

exit 0
